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

#import "GreeJSBroadcastCommand.h"
#import "GreeJSWebViewController.h"
#import "GreeDashboardViewController.h"

@implementation GreeJSBroadcastCommand;


#pragma mark - GreeJSCommand Overrides

+ (NSString *)name
{
  return @"broadcast";
}

- (void)broadcast:(NSDictionary*)params toAllAscendingViewControllers:(GreeJSWebViewController*)controller
{
  while (controller) {
    [GreeJSWebViewMessageEvent fireMessageEventName:@"ProtonBroadcast" userInfo:params inWebView:controller.webView];
    controller = controller.beforeWebViewController;
  }
}

- (void)execute:(NSDictionary *)params
{
  GreeJSWebViewController* controller = (GreeJSWebViewController*)[self viewControllerWithRequiredBaseClass:[GreeJSWebViewController class]];
  GreeJSWebViewController* topController = controller;
  id navigationControllerDelegate = controller.navigationController.delegate;
  if (navigationControllerDelegate == nil) {
    // Modal view does not have navigationController.
    topController = controller.beforeWebViewController;
    navigationControllerDelegate = topController.navigationController.delegate;
  }
  
  if (![navigationControllerDelegate isKindOfClass:[GreeDashboardViewController class]]) {
    NSLog(@"unexpected delegate %@", navigationControllerDelegate);
    return;
  }
  GreeDashboardViewController* dashboardViewController = (GreeDashboardViewController*)navigationControllerDelegate;
  [self broadcast:params toAllAscendingViewControllers:controller];

  UINavigationController* menuNavigationController = nil;
  if (![dashboardViewController.menuViewController isKindOfClass:[UINavigationController class]]) {
    NSLog(@"menuViewController is not UINavigationController.");
    return;
  }
  menuNavigationController = (UINavigationController*)dashboardViewController.menuViewController;
  
  if (topController == dashboardViewController.rootViewController.topViewController) {
    [self broadcast:params toAllAscendingViewControllers:(GreeJSWebViewController*)menuNavigationController.topViewController];
  } else if (topController == menuNavigationController.topViewController) {
    [self broadcast:params toAllAscendingViewControllers:(GreeJSWebViewController*)dashboardViewController.rootViewController.topViewController];
  } else {
    // cant happpen
  }
}
@end
