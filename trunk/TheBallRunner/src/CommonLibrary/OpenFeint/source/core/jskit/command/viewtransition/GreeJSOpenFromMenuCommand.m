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


#import "GreeJSOpenFromMenuCommand.h"
#import "GreeMenuNavController.h"
#import "GreeJSWebViewController+SubNavigation.h"

@implementation GreeJSOpenFromMenuCommand

#pragma mark - GreeJSCommand Overrides

+ (NSString *)name
{
  return @"open_from_menu";
}

- (void)execute:(NSDictionary *)params
{
  NSURL *url = [NSURL URLWithString:[params valueForKey:@"url"]];
  GreeJSWebViewController *currentViewController =
    (GreeJSWebViewController*)[self viewControllerWithRequiredBaseClass:[GreeJSWebViewController class]];
  
  GreeMenuNavController *menuController = (GreeMenuNavController*)currentViewController.navigationController.delegate;
  GreeJSWebViewController *topViewController = (GreeJSWebViewController *)
    [(UINavigationController*)menuController.rootViewController topViewController];
  
  if ([topViewController respondsToSelector:@selector(displayLoadingIndicator:)]) {
    [topViewController displayLoadingIndicator:YES];
  }
  
  [topViewController resetWebViewContents:url];
  [topViewController configureSubnavigationMenuWithParams:nil];

  [topViewController.webView loadRequest:[NSURLRequest requestWithURL:url]];
  [menuController setIsRevealed:NO];
}

@end
