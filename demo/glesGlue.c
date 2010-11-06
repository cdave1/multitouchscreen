/*
 *  glesGlue.c
 *  MultiTouchScreenDemo
 *
 *  Created by David Petrie on 6/11/10.
 *  Copyright 2010 n/a. All rights reserved.
 *
 */

#include "glesGlue.h"

void gGlBegin(GLenum prim)
{
	currentPrimitive = prim;
	vertexCount = 0;
	glVertexPointer(3, GL_FLOAT, sizeof(gVertex_t), vertices[0].xyz);
	glTexCoordPointer(2, GL_FLOAT, sizeof(gVertex_t), vertices[0].st);
	glColorPointer(4, GL_FLOAT, sizeof(gVertex_t), vertices[0].rgba);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
}


void gGlVertex3f(float x, float y, float z)
{
	if (vertexCount > kVertexCount) return;
	vec3Set(vertex.xyz, x, y, z);
	vertices[vertexCount] = vertex;
	vertexCount++;
}


void gGlColor4f(float r, float g, float b, float a)
{
	color4Set(vertex.rgba, r, g, b, a);
}


void gGlTexCoord2f(float s, float t)
{
	vec2Set(vertex.st, s, t);
}


void gGlEnd()
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


void gGlError(const char *source) {}
