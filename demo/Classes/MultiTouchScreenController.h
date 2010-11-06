/*
 
 Copyright (c) 2010 David Petrie david@davidpetrie.com
 
 This software is provided 'as-is', without any express or implied warranty.
 In no event will the authors be held liable for any damages arising from the 
 use of this software. Permission is granted to anyone to use this software for
 any purpose, including commercial applications, and to alter it and 
 redistribute it freely, subject to the following restrictions:
 
 1. The origin of this software must not be misrepresented; you must not claim 
 that you wrote the original software. If you use this software in a product, an 
 acknowledgment in the product documentation would be appreciated but is not 
 required.
 2. Altered source versions must be plainly marked as such, and must not be 
 misrepresented as being the original software.
 3. This notice may not be removed or altered from any source distribution.
 
 */


/**
 * Demo iPhone app showing multi touch screen in action.
 * 
 * Each touch event produces a particle on the screen.  The particles
 * are coloured according to the touch event they correspond to; the first
 * touch will be coloured red, the second orange, and so forth.
 */

#ifndef MULTI_DEMO_CONTROLLER_H
#define MULTI_DEMO_CONTROLLER_H

#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>
#include "glesGlue.h"

#define kTouchPointsCount 2048
#define kTouchPointHalfWidth 10.0f
#define kTouchPointStartingAge 10.0f

typedef struct touchPoint
{
	vec2_t position;
	color4_t color;
	float age;
	bool on;
}
touchPoint_t;


class MultiTouchScreenController
{		
public:
	MultiTouchScreenController(const char* path, float width, float height, float scale);
	
	~MultiTouchScreenController();
	
	void HandleTouchDown(const float x, const float y, const float touchId);
	
	void HandleTouchMoved(const float prevX, const float prevY, const float currX, const float currY, const float touchId);
	
	void HandleTouchUp(const float x, const float y, const float touchId);
	
	void Draw();
	
private:
	void AddTouchPoint(const float x, const float y, const int touchId);
	
	void DrawTouchPoint(const touchPoint_t& touch);
	
	touchPoint_t m_touchPoints[kTouchPointsCount];
	
	uint32_t m_touchPointsCount;
};




#endif