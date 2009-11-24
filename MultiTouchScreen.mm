/*
Oolong Engine for the iPhone / iPod touch
Copyright (c) 2007-2008 Wolfgang Engel  http://code.google.com/p/oolongengine/

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising from the use of this software.
Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it freely,
subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.
*/

/*
 Multi Touch Screen changes
 By David Petrie 2009 (david@davidpetrie.com)
*/


#import "MultiTouchScreen.h"
#include "Mathematics.h"
#include "UI.h"


id idFrame;

extern CDisplayText * AppDisplayText;

// C wrapper
TouchScreenValues* GetValuesMultiTouchScreen()
{
        return [idFrame GetValuesMultiTouchScreen];
}

int GetCountTouchesBegan()
{
        return [idFrame GetCountTouchesBegan];
}

int GetCountTouchesMoved()
{
        return [idFrame GetCountTouchesMoved];
}

int GetTouchCount()
{
        return [idFrame GetTouchCount];
}



@interface EAGLCameraView (Private)

- (void)LoadTouches:(NSSet *)touches;
- (void)StoreTouchInfo:(UITouch *)touch;



UIEvent* lastTouchBeganEvent;
UIEvent* lastTouchMovedEvent;
UIEvent* lastTouchEndedEvent;

TouchScreenValues       MultiTouchScreen[kMultiTouchScreenValues];

@end


@implementation EAGLCameraView

@synthesize     renderLock;

- (id) initWithFrame:(CGRect)frame pixelFormat:(GLuint)format
         depthFormat:(GLuint)depth preserveBackbuffer:(BOOL)retained
{
  if((self = [super initWithFrame:(CGRect)frame pixelFormat:(GLuint)format
                    depthFormat:(GLuint)depth preserveBackbuffer:(BOOL)retained]))
        {
                [self setMultipleTouchEnabled:YES];

                memset(MultiTouchScreen, 0, sizeof(MultiTouchScreen));
                memset(MultiTouchScreenCopy, 0, sizeof(MultiTouchScreenCopy));

                CountTouchesBegan = 0;
                CountTouchesMoved = 0;
                TouchCount        = 0;

                renderLock      = nil;
                touchScreenLock = [[NSObject alloc] init];
        }

        idFrame = self;
        return idFrame;
}


- (void)dealloc
{
        [touchScreenLock release];
        [super dealloc];
}


-(TouchScreenValues*)GetValuesMultiTouchScreen
{
        TouchCount = 0;

        // Atomic copy
        memcpy(MultiTouchScreenCopy,
               MultiTouchScreen,
               sizeof(TouchScreenValues) * kMultiTouchScreenValues);

        for (int i = 0; i < kMultiTouchScreenValues; ++i)
        {
                if (MultiTouchScreenCopy[i].TouchID != 0)
                {
                        ++TouchCount;
                }
        }

        // Reset finished touches - they will go out to the
        // caller as Up on this call, but will be invisible
        // on the following one.
        for (int i = 0; i < kMultiTouchScreenValues; ++i)
        {
                if (MultiTouchScreen[i].TouchID != 0)
                {
                        if (MultiTouchScreen[i].TouchUp)
                        {
                                MultiTouchScreen[i].LocationXTouchBegan = 0.0;
                                MultiTouchScreen[i].LocationYTouchBegan = 0.0;

                                MultiTouchScreen[i].LocationXTouchMovedPrevious = 0.0;
                                MultiTouchScreen[i].LocationYTouchMovedPrevious = 0.0;
                                MultiTouchScreen[i].LocationXTouchMoved         = 0.0;
                                MultiTouchScreen[i].LocationYTouchMoved         = 0.0;

                                MultiTouchScreen[i].TimeStamp = 0.0;

                                MultiTouchScreen[i].TouchDown  = false;
                                MultiTouchScreen[i].TouchUp    = false;
                                MultiTouchScreen[i].TouchMoved = false;

                                MultiTouchScreen[i].TapCount = 0;
                                MultiTouchScreen[i].TouchID  = 0;
                        }

                        MultiTouchScreen[i].LocationXTouchMovedPrevious = MultiTouchScreen[i].LocationXTouchMoved;
                        MultiTouchScreen[i].LocationYTouchMovedPrevious = MultiTouchScreen[i].LocationYTouchMoved;
                }
        }
        return MultiTouchScreenCopy;
}


- (int) GetCountTouchesBegan
{
        return CountTouchesBegan;
}


- (int) GetCountTouchesMoved
{
        return CountTouchesMoved;
}


- (int) GetTouchCount
{
        return TouchCount;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
        if (touchScreenLock == nil)
        {
                [self LoadTouches:touches];
        }
        else
        {
                @synchronized(touchScreenLock)
                {
                        [self LoadTouches:touches];
                }
        }
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
        if (touchScreenLock == nil)
        {
                [self LoadTouches:touches];
        }
        else
        {
                @synchronized(touchScreenLock)
                {
                        [self LoadTouches:touches];
                }
        }
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
        if (touchScreenLock == nil)
        {
                [self LoadTouches:touches];
        }
        else
        {
                @synchronized(touchScreenLock)
                {
                        [self LoadTouches:touches];
                }
        }
}


- (void)LoadTouches:(NSSet *)touches
{
        for (UITouch* touch in [touches allObjects])
                [self StoreTouchInfo:touch];
}


- (void)StoreTouchInfo:(UITouch *)touch
{
        int     pos      = -1;
        int     newPos   = -1;
        int     touchPtr = (int)touch;

        CGPoint location     = [touch locationInView:self];
        CGPoint prevLocation = [touch previousLocationInView:self];

        // Find a spot to store the info using the touch ID.
        for (int i = 0; i < kMultiTouchScreenValues; ++i)
        {
                if (MultiTouchScreen[i].TouchID == touchPtr)
                {
                        pos = i;
                }
                else if (MultiTouchScreen[i].TouchID == 0)      // first empty spot
                {
                        if (newPos == -1) newPos = i;
                }
        }

        // If our assumptions are correct, we should always find a spot for the touch.
        //assert(!(newPos == -1 && pos == -1));
        if (newPos == -1) newPos = 0;

        // Use the first empty spot if the touch is not in the list.
        if (pos == -1) pos = newPos;

        MultiTouchScreen[pos].TouchID = touchPtr;

        if (touch.phase == UITouchPhaseCancelled)
        {
#ifdef DEBUG
                printf("\t[TOUCH - CANCELLED] touch with id %d:\n", touchPtr);
#endif
                MultiTouchScreen[pos].LocationXTouchBegan = 0.0;
                MultiTouchScreen[pos].LocationYTouchBegan = 0.0;

                MultiTouchScreen[pos].LocationXTouchMovedPrevious = 0.0;
                MultiTouchScreen[pos].LocationYTouchMovedPrevious = 0.0;
                MultiTouchScreen[pos].LocationXTouchMoved         = 0.0;
                MultiTouchScreen[pos].LocationYTouchMoved         = 0.0;

                MultiTouchScreen[pos].TimeStamp = 0.0;

                MultiTouchScreen[pos].TouchDown  = false;
                MultiTouchScreen[pos].TouchUp    = false;
                MultiTouchScreen[pos].TouchMoved = false;

                MultiTouchScreen[pos].TapCount = 0;
                MultiTouchScreen[pos].TouchID  = 0;
        }
        else if (touch.phase == UITouchPhaseEnded)
        {
#ifdef DEBUG
                printf("\t[TOUCH - ENDED] touch with id %d:\n", touchPtr);
#endif
                MultiTouchScreen[pos].TapCount = [touch tapCount];
                if ([touch timestamp] - MultiTouchScreen[pos].TimeStamp < 0.045)
                {
                        MultiTouchScreen[pos].TouchDown = true;
                }
                else
                {
                        MultiTouchScreen[pos].TouchDown = false;
                }

                MultiTouchScreen[pos].TouchUp    = true;
                MultiTouchScreen[pos].TouchMoved = false;
        }
        else if (touch.phase == UITouchPhaseBegan)
        {
#ifdef DEBUG
                printf("\t[TOUCH - BEGAN] touch with id %d:\n", touchPtr);
#endif
                MultiTouchScreen[pos].LocationXTouchMovedPrevious = location.x;
                MultiTouchScreen[pos].LocationYTouchMovedPrevious = location.y;

                MultiTouchScreen[pos].LocationXTouchBegan = location.x;
                MultiTouchScreen[pos].LocationYTouchBegan = location.y;
                MultiTouchScreen[pos].LocationXTouchMoved = location.x;
                MultiTouchScreen[pos].LocationYTouchMoved = location.y;

                MultiTouchScreen[pos].TapCount  = [touch tapCount];
                MultiTouchScreen[pos].TimeStamp = [touch timestamp];

                MultiTouchScreen[pos].TouchDown  = true;
                MultiTouchScreen[pos].TouchMoved = false;
                MultiTouchScreen[pos].TouchUp    = false;
        }
        else if (touch.phase == UITouchPhaseMoved || touch.phase == UITouchPhaseStationary)
        {
#ifdef DEBUG
                printf("\t[TOUCH - MOVED] (%3.3f, %3.3f) touch with id %d:\n", location.x, location.y, touchPtr);
#endif
                MultiTouchScreen[pos].LocationXTouchMoved = location.x;
                MultiTouchScreen[pos].LocationYTouchMoved = location.y;
                MultiTouchScreen[pos].TapCount            = [touch tapCount];
                MultiTouchScreen[pos].TouchDown           = false;
                MultiTouchScreen[pos].TouchMoved          = true;
                MultiTouchScreen[pos].TouchUp             = false;
        }
}


@end



