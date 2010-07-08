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
 * Demo iPhone app showing ftgles in action.
 */

#include "MultiTouchScreenController.h"
#include "TextureLoader.h"

static GLuint aTexture;

#define MAX_VERTEX_COUNT 16

typedef struct DemoVertex 
{
	float xyz[3];
	float st[2];
	float rgba[4];
} DemoVertex;

static DemoVertex vertices[MAX_VERTEX_COUNT];
static DemoVertex vertex;
static GLenum currentPrimitive = GL_TRIANGLES;
static int vertexCount = 0;
static float screenWidth, screenHeight, contentScaleFactor;


void demoGlBegin(GLenum prim)
{
	currentPrimitive = prim;
	vertexCount = 0;
	glVertexPointer(3, GL_FLOAT, sizeof(DemoVertex), vertices[0].xyz);
	glTexCoordPointer(2, GL_FLOAT, sizeof(DemoVertex), vertices[0].st);
	glColorPointer(4, GL_FLOAT, sizeof(DemoVertex), vertices[0].rgba);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
}


void demoGlVertex3f(float x, float y, float z)
{
	if (vertexCount > MAX_VERTEX_COUNT) return;
	vertex.xyz[0] = x;
	vertex.xyz[1] = y;
	vertex.xyz[2] = z;
	vertices[vertexCount] = vertex;
	vertexCount++;
}


void demoGlColor4f(float r, float g, float b, float a)
{
	vertex.rgba[0] = r;
	vertex.rgba[1] = g;
	vertex.rgba[2] = b;
	vertex.rgba[3] = a;
}


void demoGlTexCoord2f(float s, float t)
{
	vertex.st[0] = s;
	vertex.st[1] = t;
}


void demoGlEnd()
{
	if (vertexCount == 0) 
	{
		currentPrimitive = 0;
		return;
	}
	glDrawArrays(currentPrimitive, 0, vertexCount);
	vertexCount = 0;
	currentPrimitive = 0;
}


void demoGlError(const char *source)
{
}


MultiTouchScreenController::MultiTouchScreenController(const char* path, float width, float height, float scale)
{
	contentScaleFactor = scale;
	screenWidth = contentScaleFactor * width;
	screenHeight = contentScaleFactor * height;
	
	glDepthFunc(GL_LEQUAL);
	glClearDepthf(1.0);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	LoadTexture("mousePoint.png", &aTexture);
}


MultiTouchScreenController::~MultiTouchScreenController() 
{
	// TODO: unload texture.
}


void MultiTouchScreenController::DrawTexturedQuad()
{
	demoGlBegin(GL_TRIANGLE_STRIP);
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, aTexture);
	
	demoGlVertex3f(-40.0f, -40.0f, 0.0f);
	demoGlColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	demoGlTexCoord2f(0, 1);
	
	demoGlVertex3f(-40.0f, 40.0f, 0.0f);
	demoGlColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	demoGlTexCoord2f(1, 0);
	
	demoGlVertex3f(40.0f, -40.0f, 0.0f);
	demoGlColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	demoGlTexCoord2f(0, 0);
	
	demoGlVertex3f(40.0f, 40.0f, 0.0f);
	demoGlColor4f(1.0f, 1.0f, 1.0f, 1.0f);
	demoGlTexCoord2f(1, 1);
	
	demoGlEnd();
}


static float angle = 0.0f;
void MultiTouchScreenController::Draw()
{
	float halfScreenWidth = screenWidth * 0.5f;
	float halfScreenHeight = screenHeight * 0.5f;
	
	glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	glPushMatrix();
	glOrthof(0.0f, screenWidth, 
			 0.0f, screenHeight, 
			 1000.0f, -1000.0f);
	
	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glTranslatef(halfScreenWidth, halfScreenHeight, 0.0f);
	
	glDisable(GL_DEPTH_TEST);
	glEnable(GL_BLEND);

	DrawTexturedQuad();
	
	glPopMatrix();
	
	glDisable(GL_BLEND);
	glEnable(GL_DEPTH_TEST);
	
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
	
	angle += 0.1f;
	if (angle >= 360.0f) angle = 0.0f;
	
	//fonts[1]->FaceSize(faceSize);
	//faceSize -= 1.0f;
	//if (faceSize < 10) faceSize = 120;
}

