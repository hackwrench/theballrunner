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


#import "GreeJSPushViewCommand.h"
#import "GreeJSWebViewControllerPool.h"

@implementation GreeJSPushViewCommand

+ (NSString *)name
{
  return @"push_view";
}

- (void)execute:(NSDictionary *)params
{
  GreeJSWebViewController *currentViewController =
    (GreeJSWebViewController*)[self viewControllerWithRequiredBaseClass:[GreeJSWebViewController class]];

  GreeJSWebViewController *nextViewController = [currentViewController preloadNextWebViewController];
  nextViewController.beforeWebViewController = currentViewController;
  
  if ([UINavigationBar respondsToSelector:@selector(appearance)]) {
    nextViewController.navigationItem.leftBarButtonItems = nil;
    nextViewController.navigationItem.rightBarButtonItems = currentViewController.navigationItem.rightBarButtonItems;
  } else {
    nextViewController.navigationItem.leftBarButtonItem = nil;
    nextViewController.navigationItem.rightBarButtonItem = currentViewController.navigationItem.rightBarButtonItem;
  }

  NSString *viewName = [params valueForKey:@"view"];
  NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"record_analytics"];
  [nextViewController enableScrollsToTop];
  if ([nextViewController.handler isReady])
  {
    [nextViewController.handler forceLoadView:viewName params:params options:options];
  }
  else
  {
    [nextViewController setPendingLoadRequest:viewName params:params options:options];
    if (nextViewController.deadlyProtonErrorOccured) {
      // it can be stuck on network error or something so that never get ready.
      // try reload and wish it works this time.
      [nextViewController retryToInitializeProton];
    }
  }

  [currentViewController setBackButtonForNavigationItem:nextViewController.navigationItem];
  [currentViewController.navigationController pushViewController:nextViewController animated:YES];
}

@end
