//
// Copyright 2012 GREE, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

@class UIViewController;

@interface GreeDashboardLauncher : NSObject
{
  int _originalStatusBarStyle;
}

@property (nonatomic, retain) UIViewController *currentDashboard;
@property (nonatomic, assign) UIViewController *hostViewController;
@property (nonatomic, copy) void (^completion)(id);

- (id)initWithHostViewController:(UIViewController*)viewController;
- (void)launchDashboardWithBaseURL:(NSURL*)URL completion:(void(^)(id))completion;
- (void)launchDashboardWithPath:(NSString*)path completion:(void(^)(id))completion;
- (void)launchDashboardWithParameters:(NSDictionary*)parameters completion:(void(^)(id))completion;
- (void)dismissDashboard;
- (void)dismissDashboardWithResults:(id)results;
+ (NSURL*)URLFromMenuViewController:(UIViewController*)viewController;
+ (NSString*)viewNameFromURL:(NSURL*)url;

@end
