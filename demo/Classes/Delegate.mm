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


#import "Delegate.h"

#include <sys/time.h> 
#include "QuartzCore/QuartzCore.h"
#include "MultiTouchScreenController.h"

static MultiTouchScreenController * multiTouchScreenController = NULL;

static int frames;
static CFTimeInterval CurrentTime;
static CFTimeInterval LastFPSUpdate;

@implementation AppController

- (void) update
{
	if (!multiTouchScreenController) return;
	
	/**
	 * We get the accumulated touch information from the multi touch screen
	 * and pass each individual touchPosition_t instance to the controller.
	 *
	 * The receiver of the touch values does not know that the values were 
	 * retrieved from the touch screen.
	 *
	 * If there was a controller that was built to accept mouse input and you
	 * needed to adapt it to a multitouch environment without changing it, you 
	 * would need to pass the touchInfo_t values through in such a way as 
	 * to mimic mouse behavior.  In this case, one approach is to pass 
	 * through touch values from the first touchInfo_t instance retrieved 
	 * via GetTouchValues().  Another would be to pass through touch values
	 * from the first touchInfo_t instance where "touchesCount" is greater
	 * than zero (and ignore the rest).
	 */
	touchInfo_t *multiTouchValues = GetTouchValues();
	if (multiTouchValues)
	{
		for (int i = 0; i < kMultiTouchMaxEntries; i++)
		{
			for (int j = 0; j < multiTouchValues[i].touchesCount; ++j)
			{
				touchPosition_t touchPosition = multiTouchValues[i].touchPositions[j];
				
				if (touchPosition.TouchDown)
				{
					multiTouchScreenController->HandleTouchDown(touchPosition.startPosition.x,
																touchPosition.startPosition.y,
																i);
				}
				
				if (touchPosition.TouchMoved)
				{
					multiTouchScreenController->HandleTouchMoved(touchPosition.previousPosition.x,
																 touchPosition.previousPosition.y,
																 touchPosition.currentPosition.x,
																 touchPosition.currentPosition.y,
																 i);
				}
				
				if (touchPosition.TouchUp)
				{
					multiTouchScreenController->HandleTouchUp(touchPosition.endPosition.x,
															  touchPosition.endPosition.y,
															  i);
				}
			}
		}
	}
	
	multiTouchScreenController->Draw();
	
	[multiTouchGLView swapBuffers];
	
	++frames;
	CurrentTime = CACurrentMediaTime();
	
	if ((CurrentTime - LastFPSUpdate) > 1.0f)
	{ 
		printf("fps: %d\n", frames);		
		frames = 0;
		LastFPSUpdate = CurrentTime;
	} 
}


- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	CGRect	rect = [[UIScreen mainScreen] bounds];
	window = [[UIWindow alloc] initWithFrame:rect];
	multiTouchGLView = [[MultiTouchScreen alloc] initWithFrame:rect];
	
	[window addSubview:multiTouchGLView];
	[window makeKeyAndVisible];
	
	const char *bundleResourcePath = 
		[[[NSBundle mainBundle] resourcePath] cStringUsingEncoding:NSASCIIStringEncoding];

	float scale = 1.0f;
	
#ifdef __IPHONE_4_0
	if([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) 
	{
		scale = [[UIScreen mainScreen] scale];
	}
#endif
	
	multiTouchScreenController = new MultiTouchScreenController(bundleResourcePath, rect.size.width, rect.size.height, scale);
	
	NSString *reqSysVer = @"3.1";
	NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
	BOOL displayLinkSupported = NO;
	if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
		displayLinkSupported = TRUE;
	
	if (displayLinkSupported)
	{
		id displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(update)];
		[displayLink setFrameInterval:1];
		[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	}
	else
	{
		CurrentTime = CACurrentMediaTime();
		LastFPSUpdate = CurrentTime;
		[NSTimer scheduledTimerWithTimeInterval:(1.0 / 60.0) 
										 target:self 
									   selector:@selector(update) 
									   userInfo:nil 
										repeats:YES];
	}
}


- (void) dealloc
{
	delete multiTouchScreenController;
	[multiTouchGLView release];
	[window release];
	[super dealloc];
}


@end
