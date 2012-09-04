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

#import "GreeJSWebViewController+SubNavigation.h"
#import "GreeJSHandler.h"
#import "GreeJSSubnavigationView.h"
#import "GreeJSWebViewController+PullToRefresh.h"

@interface GreeJSWebViewController()
@property(nonatomic, readwrite, retain) GreeJSSubnavigationView* subNavigationView;
@end

@implementation GreeJSWebViewController (SubNavigation)

- (BOOL)subnavigationMenuIsDisplayed
{
  return (nil != self.subNavigationView);
}

- (BOOL)configureSubnavigationMenuWithParams:(NSDictionary*)params
{
  return [self.subNavigationView configureSubnavigationMenuWithParams:params];
}

#pragma mark - GreeJSSubnavigationMenuButtonDelegate Methods

- (void)onSubnavigationMenuButtonIconTap:(GreeJSSubnavigationIconView *)button
{
  [self stopLoading];
  [self displayLoadingIndicator:YES];
  [self.handler callback:button.callback params:button.callbackParams];
  [self.subNavigationView setSelectedIconAtIndex:button.tag];
}

@end
