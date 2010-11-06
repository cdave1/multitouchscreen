/*
 *  glesGlue.h
 *  MultiTouchScreenDemo
 *
 *  Created by David Petrie on 6/11/10.
 *  Copyright 2010 n/a. All rights reserved.
 *
 */

#ifndef GLES_GLUE_H
#define GLES_GLUE_H

#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>

#define kVertexCount 512

#ifndef uint32_t
typedef unsigned int uint32_t;
#endif

typedef float vec_t;
typedef vec_t vec2_t[2];
typedef vec_t vec3_t[3];
typedef vec_t vec4_t[4];
typedef vec4_t color4_t;

#define vec2Set(__v, __x, __y) { __v[0] = __x; __v[1] = __y; }
#define vec3Set(__v, __x, __y, __z) { __v[0] = __x; __v[1] = __y; __v[2] = __z; }
#define vec4Set(__v, __x, __y, __z, __u) { __v[0] = __x; __v[1] = __y; __v[2] = __z; __v[3] = __u; }
#define color4Set(__c, __r, __g, __b, __a) { vec4Set(__c, __r, __g, __b, __a) }
#define color4SetC(__cDst, __cSrc) { color4Set(__cDst, __cSrc[0], __cSrc[1], __cSrc[2], __cSrc[3]); }

typedef struct gVertex 
{
	vec3_t xyz;
	vec2_t st;
	color4_t rgba;
} gVertex_t;

static gVertex_t vertices[kVertexCount];
static gVertex_t vertex;
static GLenum currentPrimitive = GL_TRIANGLES;
static uint32_t vertexCount = 0;

#ifdef __cplusplus
extern "C" {
#endif
	
void gGlBegin(GLenum prim);

void gGlVertex3f(float x, float y, float z);

void gGlColor4f(float r, float g, float b, float a);

void gGlTexCoord2f(float s, float t);

void gGlEnd();

void gGlError(const char *source);

#ifdef __cplusplus
}
#endif

#endif