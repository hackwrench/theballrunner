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


#import "GreeJSPushViewWithUrlCommand.h"
#import "UIImage+GreeAdditions.h"

@implementation GreeJSPushViewWithUrlCommand

+ (NSString *)name
{
  return @"push_view_with_url";
}

- (void)execute:(NSDictionary *)params
{
  GreeJSWebViewController *currentViewController =
    (GreeJSWebViewController*)[self viewControllerWithRequiredBaseClass:[GreeJSWebViewController class]];

  // This command doesn't preload next webview(always create new instance)
  // Because, WebView can't preloading contents by URL based push view.  
  GreeJSWebViewController *nextViewController = [[[GreeJSWebViewController alloc] init] autorelease];
  nextViewController.beforeWebViewController = currentViewController;
  nextViewController.pool = currentViewController.pool;
  nextViewController.preloadInitializeBlock = currentViewController.preloadInitializeBlock;
  
  NSURL *url = [NSURL URLWithString:[params objectForKey:@"url"]];
  [nextViewController.webView loadRequest:[NSURLRequest requestWithURL:url]];

  if ([UINavigationBar respondsToSelector:@selector(appearance)]) {
    nextViewController.navigationItem.leftBarButtonItems = nil;
    nextViewController.navigationItem.rightBarButtonItems = currentViewController.navigationItem.rightBarButtonItems;
  } else {
    nextViewController.navigationItem.leftBarButtonItem = nil;
    nextViewController.navigationItem.rightBarButtonItem = currentViewController.navigationItem.rightBarButtonItem;
  }
  
  [nextViewController enableScrollsToTop];
  
  [currentViewController setTitleViewForNavigationItem:nextViewController.navigationItem];
  [currentViewController setBackButtonForNavigationItem:nextViewController.navigationItem];
  [currentViewController.navigationController pushViewController:nextViewController animated:YES];
}

@end
