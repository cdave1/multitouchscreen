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

#import "EAGLView.h"

@class MultiTouchScreen;

const int kMultiTouchScreenValues = 10;

typedef struct touchInfo
{
	float LocationXTouchBegan;    // x and y coordinates where the touch began
	float LocationYTouchBegan;
	
	float LocationXTouchMovedPrevious;
	float LocationYTouchMovedPrevious;
	
	float LocationXTouchMoved;      // x and y coordinates where the touch moved
	float LocationYTouchMoved;
	
	NSTimeInterval TimeStamp;
	
	void * uiTouchPtr;
	int TapCount;
	
	bool TouchDown;
	bool TouchUp;
	bool TouchMoved;
} touchInfo_t;


@interface MultiTouchScreen : EAGLView
{
@private
	int CountTouchesBegan;
	int CountTouchesMoved;
	int TouchCount;
	NSObject * renderLock;
	NSObject * touchScreenLock;
	
	UIEvent * lastTouchBeganEvent;
	UIEvent * lastTouchMovedEvent;
	UIEvent * lastTouchEndedEvent;
	
	touchInfo_t touchInfoValuesCopy[kMultiTouchScreenValues];
	touchInfo_t touchInfoValues[kMultiTouchScreenValues];
}

@property (readwrite, assign) NSObject *renderLock;

- (touchInfo_t *)GetTouchValues;
- (int) GetCountTouchesBegan;
- (int) GetCountTouchesMoved;
- (int) GetTouchCount;

@end


// C wrapper
touchInfo_t * GetTouchValues();

int GetCountTouchesBegan();

int GetCountTouchesMoved();

int GetTouchCount();
