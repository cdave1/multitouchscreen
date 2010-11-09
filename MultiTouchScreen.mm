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
		
		memset(touchValues, 0, sizeof(touchValues));
		memset(touchValuesCopy, 0, sizeof(touchValuesCopy));
		
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
	memcpy(touchValuesCopy, touchValues, sizeof(touchInfo_t) * kMultiTouchMaxEntries);
	
	// Any touch up mean that the touch is finished, so reset the touch pointer to NULL.
	for (int i = 0; i < kMultiTouchMaxEntries; ++i)
	{
		for (int j = 0; j < touchValues[i].touchesCount; ++j)
		{
			if (touchValues[i].touchPositions[j].TouchUp)
			{
				touchValues[i].uiTouchPtr = NULL;
			}
		}
		TouchCount += touchValues[i].touchesCount;
		touchValues[i].touchesCount = 0;
		memset(touchValues[i].touchPositions, 0, sizeof(touchPosition_t) * kTouchPositionsBufferSize);
	}
	return touchValuesCopy;
}


- (int) GetTouchCount
{
	return TouchCount;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self LoadTouches:touches];
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self LoadTouches:touches];
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self LoadTouches:touches];
}


- (void)LoadTouches:(NSSet *)touches
{
	if (touchScreenLock)
	{
		@synchronized(touchScreenLock)
		{
			for (UITouch* touch in [touches allObjects])
				[self StoreTouchInfo:touch];
		}
	}
	else 
	{
		for (UITouch* touch in [touches allObjects])
			[self StoreTouchInfo:touch];
	}
}


- (void)StoreTouchInfo:(UITouch *)touch
{
	int     pos = -1;
	void * touchPtr = (void *)touch;
	
	CGPoint location     = [touch locationInView:self];
	CGPoint prevLocation = [touch previousLocationInView:self];
	
	// Find an existing slot for this touch value.
	for (unsigned i = 0; i < kMultiTouchMaxEntries; ++i)
	{
		if (touchValues[i].uiTouchPtr == touchPtr)
		{
			pos = i;
			break;
		}
	}
	
	// No exiting slot found. Find first empty slot.
	if (pos == -1)
	{
		for (unsigned i = 0; i < kMultiTouchMaxEntries; ++i)
		{
			if (touchValues[i].uiTouchPtr == NULL)
			{
				pos = i;
				touchValues[pos].uiTouchPtr = touchPtr;
				break;
			}
		}
	}
	
	// No empty slots found. Means that there are more touches than 
	// kMultiTouchMaxEntries.
	if (pos == -1) return;
	
	touchPosition_t newTouchPosition;
	memset(&newTouchPosition, 0, sizeof(touchPosition_t));
	
	if (touch.phase == UITouchPhaseBegan)
	{
#ifdef MULTI_TOUCH_SCREEN_DEBUG
		NSLog(@"\t[TOUCH - BEGAN] touch with id %p:\n", touchPtr);
#endif
		newTouchPosition.currentPosition.Set(location.x, location.y);
		newTouchPosition.startPosition.Set(location.x, location.y);
		newTouchPosition.previousPosition.Set(location.x, location.y);
		newTouchPosition.TapCount = [touch tapCount];
		newTouchPosition.TimeStamp = [touch timestamp];
		newTouchPosition.TouchDown = true;
		newTouchPosition.TouchMoved = false;
		newTouchPosition.TouchUp = false;
	}
	else if (touch.phase == UITouchPhaseMoved || touch.phase == UITouchPhaseStationary)
	{
#ifdef MULTI_TOUCH_SCREEN_DEBUG
		NSLog(@"\t[TOUCH - MOVED] (%3.3f, %3.3f) touch with id %p:\n", location.x, location.y, touchPtr);
#endif
		newTouchPosition.currentPosition.Set(location.x, location.y);
		newTouchPosition.previousPosition.Set(prevLocation.x, prevLocation.y);
		newTouchPosition.TapCount = [touch tapCount];
		newTouchPosition.TouchDown = false;
		newTouchPosition.TouchMoved = true;
		newTouchPosition.TouchUp = false;
	}
	else if (touch.phase == UITouchPhaseEnded)
	{
#ifdef MULTI_TOUCH_SCREEN_DEBUG
		NSLog(@"\t[TOUCH - ENDED] touch with id %p:\n", touchPtr);
#endif
		newTouchPosition.TapCount = [touch tapCount];
		
		newTouchPosition.previousPosition.Set(prevLocation.x, prevLocation.y);
		newTouchPosition.endPosition.Set(location.x, location.y);
		
		newTouchPosition.TouchDown = false;
		newTouchPosition.TouchMoved = false;
		newTouchPosition.TouchUp = true;
	}
	else if (touch.phase == UITouchPhaseCancelled)
	{
#ifdef MULTI_TOUCH_SCREEN_DEBUG
		NSLog(@"\t[TOUCH - CANCELLED] touch with id %p:\n", touchPtr);
#endif
	}
	
	touchValues[pos].touchPositions[touchValues[pos].touchesCount] = newTouchPosition;
	touchValues[pos].touchesCount++;
}


@end



