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

#include "MultiTouchScreenController.h"
#include "TextureLoader.h"
#import <string.h>

static GLuint mouseTexture;
static GLuint pathTexture;

static float screenWidth, screenHeight, contentScaleFactor;


MultiTouchScreenController::MultiTouchScreenController(const char* path, float width, float height, float scale)
{
	contentScaleFactor = scale;
	screenWidth = contentScaleFactor * width;
	screenHeight = contentScaleFactor * height;
	
	m_touchPointsCount = 0;
	memset(m_touchPoints, 0, sizeof(m_touchPoints));
	
	glDepthFunc(GL_LEQUAL);
	glClearDepthf(1.0);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	LoadTexture("point_glow.png", &pathTexture);
}


MultiTouchScreenController::~MultiTouchScreenController() 
{
	// TODO: unload texture.
}


void MultiTouchScreenController::HandleTouchDown(const float x, const float y, const float touchId)
{
	AddTouchPoint(x, y, touchId);
}


void MultiTouchScreenController::HandleTouchMoved(const float prevX, const float prevY, 
												  const float currX, const float currY, const float touchId)
{
	AddTouchPoint(currX, currY, touchId);
}


void MultiTouchScreenController::HandleTouchUp(const float x, const float y, const float touchId)
{
	AddTouchPoint(x, y, touchId);
}


void MultiTouchScreenController::AddTouchPoint(const float x, const float y, const int touchId)
{
	// HACK -- hard coded colours depending on the touch id.
	color4_t color;
	switch (touchId) 
	{
		case 0:
			color4Set(color, 1.0f, 0.0f, 0.0f, 1.0f); // r
			break;
		case 1:
			color4Set(color, 1.0f, 0.5f, 0.0f, 1.0f); // o
			break;
		case 2:
			color4Set(color, 1.0f, 1.0f, 0.0f, 1.0f); // y
			break;
		case 3:
			color4Set(color, 0.0f, 1.0f, 0.0f, 1.0f); // g
			break;
		case 4:
			color4Set(color, 0.5f, 0.5f, 1.0f, 1.0f); // b
			break;
		case 5:
			color4Set(color, 0.66f, 0.0f, 1.0f, 1.0f); // i
			break;
		case 6:
			color4Set(color, 1.0f, 0.5f, 1.0f, 1.0f); // v
			break;
		case 7:
			color4Set(color, 0.0f, 0.0f, 0.0f, 1.0f); // black
			break;
		case 8:
			color4Set(color, 0.33f, 0.33f, 0.33f, 1.0f); // 33% grey
			break;
		case 9:
			color4Set(color, 0.66f, 0.66f, 0.66f, 1.0f); // 66% grey
			break;
		default:
			color4Set(color, 0.0f, 0.0f, 0.0f, 0.0f);
			break;
	}
	
	vec2Set(m_touchPoints[m_touchPointsCount].position, x, y);
	color4SetC(m_touchPoints[m_touchPointsCount].color, color);
	
	m_touchPoints[m_touchPointsCount].on = true;
	m_touchPoints[m_touchPointsCount].age = kTouchPointStartingAge;
	
	m_touchPointsCount = (m_touchPointsCount + 1) % kTouchPointsCount;
}


void MultiTouchScreenController::Draw()
{
	float halfScreenWidth = screenWidth * 0.5f;
	float halfScreenHeight = screenHeight * 0.5f;
	
	glClearColor(0.0f, 0.0f, 0.1f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	glPushMatrix();
	glRotatef(180.0f, 1.0f, 0.0f, 0.0f);
	glOrthof(0.0f, screenWidth, 
			 0.0f, screenHeight,
			 -1000.0f, 1000.0f);
	
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	
	glDisable(GL_DEPTH_TEST);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE);
	
	
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, pathTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	for (int i = 0; i < kTouchPointsCount; ++i)
	{
		if (m_touchPoints[i].on)
		{
			DrawTouchPoint(m_touchPoints[i]);
			m_touchPoints[i].age -= 0.02f;
			m_touchPoints[i].color[3] = m_touchPoints[i].age / kTouchPointStartingAge;
		}
		
		if (m_touchPoints[i].age <= 0.0f)
		{
			m_touchPoints[i].on = false;
			m_touchPoints[i].age = 0.0f;
		}
	}
	

	glDisable(GL_BLEND);
	glEnable(GL_DEPTH_TEST);

	glMatrixMode(GL_MODELVIEW);
	glPopMatrix();
	
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
}


void MultiTouchScreenController::DrawTouchPoint(const touchPoint_t& touch)
{
	gGlBegin(GL_TRIANGLE_STRIP);
	gGlVertex3f(touch.position[0] - kTouchPointHalfWidth, touch.position[1] - kTouchPointHalfWidth, 0.0f);
	gGlColor4f(touch.color[0], touch.color[1], touch.color[2], touch.color[3]);
	gGlTexCoord2f(0, 1);
	
	gGlVertex3f(touch.position[0] - kTouchPointHalfWidth, touch.position[1] + kTouchPointHalfWidth, 0.0f);
	gGlColor4f(touch.color[0], touch.color[1], touch.color[2], touch.color[3]);
	gGlTexCoord2f(1, 0);
	
	gGlVertex3f(touch.position[0] + kTouchPointHalfWidth, touch.position[1] - kTouchPointHalfWidth, 0.0f);
	gGlColor4f(touch.color[0], touch.color[1], touch.color[2], touch.color[3]);
	gGlTexCoord2f(0, 0);
	
	gGlVertex3f(touch.position[0] + kTouchPointHalfWidth, touch.position[1] + kTouchPointHalfWidth, 0.0f);
	gGlColor4f(touch.color[0], touch.color[1], touch.color[2], touch.color[3]);
	gGlTexCoord2f(1, 1);
	gGlEnd();
	
}
