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

#ifndef MULTI_TOUCH_SCREEN_H
#define MULTI_TOUCH_SCREEN_H

#import "EAGLView.h"

// Uncomment this line to enable debug logging messages.
//#define MULTI_TOUCH_SCREEN_DEBUG


@class MultiTouchScreen;

const int kMultiTouchMaxEntries = 10;
const int kTouchPositionsBufferSize = 8;

typedef struct touchCoordinate
{
	void Set(float _x, float _y) { x = _x; y = _y; }
	
	float x;
	float y;
	
} touchCoordinate_t;


typedef struct touchPosition
{
	touchCoordinate_t startPosition;
	touchCoordinate_t previousPosition;
	touchCoordinate_t currentPosition;
	touchCoordinate_t endPosition;
	
	NSTimeInterval TimeStamp;
	
	int TapCount;
	
	bool TouchDown;
	bool TouchUp;
	bool TouchMoved;
} touchPosition_t;


typedef struct touchSlot
{
	touchPosition_t touchPositions[kTouchPositionsBufferSize];
	unsigned int touchesCount;
	void * uiTouchPtr;
} touchInfo_t;


@interface MultiTouchScreen : EAGLView
{
@private
	int TouchCount;
	NSObject * renderLock;
	NSObject * touchScreenLock;
	
	UIEvent * lastTouchBeganEvent;
	UIEvent * lastTouchMovedEvent;
	UIEvent * lastTouchEndedEvent;
	
	touchInfo_t touchValuesCopy[kMultiTouchMaxEntries];
	touchInfo_t touchValues[kMultiTouchMaxEntries];
}

@property (readwrite, assign) NSObject *renderLock;

- (touchInfo_t *)GetTouchValues;
- (int) GetTouchCount;

@end


// C wrapper
touchInfo_t * GetTouchValues();

int GetTouchCount();


#endif MULTI_TOUCH_SCREEN_H