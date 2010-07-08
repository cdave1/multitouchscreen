/*
 Multi Touch GLView
 By David Petrie 2010 (david@davidpetrie.com)

 Adapted from the TouchScreen class in the oolong engine.
*/

/*
 Oolong Engine for the iPhone / iPod touch
 Copyright (c) 2007-2008 Wolfgang Engel  http://code.google.com/p/oolongengine/
 
 This software is provided 'as-is', without any express or implied warranty.
 In no event will the authors be held liable for any damages arising from the use of this software.
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it freely,
 subject to the following restrictions:
 
 1. The origin of this software must not be misrepresented; you must not claim that you wrote the 
	original software. If you use this software in a product, an acknowledgment in the product documentation 
	would be appreciated but is not required.
 2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
 3. This notice may not be removed or altered from any source distribution.
 */

#import "MultiTouchScreen.h"

id idFrame;

// C wrapper
touchInfo_t * GetTouchValues()
{
	return [idFrame GetTouchValues];
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



@interface MultiTouchScreen (Private)

- (void)LoadTouches:(NSSet *)touches;
- (void)StoreTouchInfo:(UITouch *)touch;

@end


@implementation MultiTouchScreen

@synthesize renderLock;

- (id) initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:(CGRect)frame]))
	{
		[self setMultipleTouchEnabled:YES];
		
		memset(touchInfoValues, 0, sizeof(touchInfoValues));
		memset(touchInfoValuesCopy, 0, sizeof(touchInfoValuesCopy));
		
		CountTouchesBegan = 0;
		CountTouchesMoved = 0;
		TouchCount = 0;
		
		renderLock = nil;
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


- (touchInfo_t *)GetTouchValues
{
	TouchCount = 0;
	
	// Atomic copy
	memcpy(touchInfoValuesCopy,
		   touchInfoValues,
		   sizeof(touchInfo_t) * kMultiTouchScreenValues);
	
	for (int i = 0; i < kMultiTouchScreenValues; ++i)
	{
		if (touchInfoValuesCopy[i].uiTouchPtr != NULL)
		{
			++TouchCount;
		}
	}
	
	// Reset finished touches - they will go out to the
	// caller as Up on this call, but will be invisible
	// on the following one.
	for (int i = 0; i < kMultiTouchScreenValues; ++i)
	{
		if (touchInfoValues[i].uiTouchPtr != NULL)
		{
			if (touchInfoValues[i].TouchUp)
			{
				touchInfoValues[i].LocationXTouchBegan = 0.0;
				touchInfoValues[i].LocationYTouchBegan = 0.0;
				
				touchInfoValues[i].LocationXTouchMovedPrevious = 0.0;
				touchInfoValues[i].LocationYTouchMovedPrevious = 0.0;
				touchInfoValues[i].LocationXTouchMoved         = 0.0;
				touchInfoValues[i].LocationYTouchMoved         = 0.0;
				
				touchInfoValues[i].TimeStamp = 0.0;
				
				touchInfoValues[i].TouchDown  = false;
				touchInfoValues[i].TouchUp    = false;
				touchInfoValues[i].TouchMoved = false;
				
				touchInfoValues[i].TapCount = 0;
				touchInfoValues[i].uiTouchPtr  = NULL;
			}
			
			touchInfoValues[i].LocationXTouchMovedPrevious = touchInfoValues[i].LocationXTouchMoved;
			touchInfoValues[i].LocationYTouchMovedPrevious = touchInfoValues[i].LocationYTouchMoved;
		}
	}
	return touchInfoValuesCopy;
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
	void * touchPtr = (void *)touch;
	
	CGPoint location     = [touch locationInView:self];
	CGPoint prevLocation = [touch previousLocationInView:self];
	
	// Find a spot to store the info using the touch ID.
	for (int i = 0; i < kMultiTouchScreenValues; ++i)
	{
		if (touchInfoValues[i].uiTouchPtr == touchPtr)
		{
			pos = i;
		}
		else if (touchInfoValues[i].uiTouchPtr == 0)      // first empty spot
		{
			if (newPos == -1) newPos = i;
		}
	}
	
	if (newPos == -1) newPos = 0;
	
	// Use the first empty spot if the touch is not in the list.
	if (pos == -1) pos = newPos;
	
	touchInfoValues[pos].uiTouchPtr = touchPtr;
	
	if (touch.phase == UITouchPhaseCancelled)
	{
#ifdef MULTI_TOUCH_SCREEN_DEBUG
		NSLog(@"\t[TOUCH - CANCELLED] touch with id %d:\n", touchPtr);
#endif
		touchInfoValues[pos].LocationXTouchBegan = 0.0;
		touchInfoValues[pos].LocationYTouchBegan = 0.0;
		
		touchInfoValues[pos].LocationXTouchMovedPrevious = 0.0;
		touchInfoValues[pos].LocationYTouchMovedPrevious = 0.0;
		touchInfoValues[pos].LocationXTouchMoved = 0.0;
		touchInfoValues[pos].LocationYTouchMoved = 0.0;
		
		touchInfoValues[pos].TimeStamp = 0.0;
		
		touchInfoValues[pos].TouchDown  = false;
		touchInfoValues[pos].TouchUp    = false;
		touchInfoValues[pos].TouchMoved = false;
		
		touchInfoValues[pos].TapCount = 0;
		touchInfoValues[pos].uiTouchPtr  = NULL;
	}
	else if (touch.phase == UITouchPhaseEnded)
	{
#ifdef MULTI_TOUCH_SCREEN_DEBUG
		NSLog(@"\t[TOUCH - ENDED] touch with id %d:\n", touchPtr);
#endif
		touchInfoValues[pos].TapCount = [touch tapCount];
		if ([touch timestamp] - touchInfoValues[pos].TimeStamp < 0.045)
		{
			touchInfoValues[pos].TouchDown = true;
		}
		else
		{
			touchInfoValues[pos].TouchDown = false;
		}
		
		touchInfoValues[pos].TouchUp    = true;
		touchInfoValues[pos].TouchMoved = false;
	}
	else if (touch.phase == UITouchPhaseBegan)
	{
#ifdef MULTI_TOUCH_SCREEN_DEBUG
		NSLog(@"\t[TOUCH - BEGAN] touch with id %d:\n", touchPtr);
#endif
		touchInfoValues[pos].LocationXTouchMovedPrevious = location.x;
		touchInfoValues[pos].LocationYTouchMovedPrevious = location.y;
		
		touchInfoValues[pos].LocationXTouchBegan = location.x;
		touchInfoValues[pos].LocationYTouchBegan = location.y;
		touchInfoValues[pos].LocationXTouchMoved = location.x;
		touchInfoValues[pos].LocationYTouchMoved = location.y;
		
		touchInfoValues[pos].TapCount  = [touch tapCount];
		touchInfoValues[pos].TimeStamp = [touch timestamp];
		
		touchInfoValues[pos].TouchDown  = true;
		touchInfoValues[pos].TouchMoved = false;
		touchInfoValues[pos].TouchUp    = false;
	}
	else if (touch.phase == UITouchPhaseMoved || touch.phase == UITouchPhaseStationary)
	{
#ifdef MULTI_TOUCH_SCREEN_DEBUG
		NSLog(@"\t[TOUCH - MOVED] (%3.3f, %3.3f) touch with id %d:\n", location.x, location.y, touchPtr);
#endif
		touchInfoValues[pos].LocationXTouchMoved = location.x;
		touchInfoValues[pos].LocationYTouchMoved = location.y;
		touchInfoValues[pos].TapCount            = [touch tapCount];
		touchInfoValues[pos].TouchDown           = false;
		touchInfoValues[pos].TouchMoved          = true;
		touchInfoValues[pos].TouchUp             = false;
	}
}


@end



