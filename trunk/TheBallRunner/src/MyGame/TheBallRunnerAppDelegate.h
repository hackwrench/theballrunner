//
//  TheBallRunnerAppDelegate.h
//  TheBallRunner
//
//  Created by Thi Huynh on 7/19/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

@class Isgl3dViewController;

@interface TheBallRunnerAppDelegate : NSObject <UIApplicationDelegate> {

@private
	Isgl3dViewController * _viewController;
	UIWindow * _window;
}

@property (nonatomic, retain) UIWindow * window;

@end
