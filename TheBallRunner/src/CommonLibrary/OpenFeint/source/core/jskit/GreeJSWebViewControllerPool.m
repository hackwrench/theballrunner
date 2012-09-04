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

#import "GreeJSWebViewControllerPool.h"

@interface GreeJSWebViewControllerPool()
@property(nonatomic, retain) GreeJSWebViewController *currentWebViewController;
@end

@implementation GreeJSWebViewControllerPool
@synthesize preloadURL = preloadURL_;
@synthesize currentWebViewController = currentWebViewController_;

- (void)dealloc
{
  self.preloadURL = nil;
  self.currentWebViewController = nil;
  [super dealloc];
}

- (GreeJSWebViewController *)take
{
  if (!self.currentWebViewController) {
    [self prepareNextWebViewController];
  }

  GreeJSWebViewController *webViewController = [[self.currentWebViewController retain] autorelease];
  self.currentWebViewController = nil;
  return webViewController;
}

- (GreeJSWebViewController *)prepareNextWebViewController
{
  self.currentWebViewController = [[[GreeJSWebViewController alloc] init] autorelease];
  if (self.preloadURL) {
    [self.currentWebViewController.webView loadRequest:[NSURLRequest requestWithURL:self.preloadURL]];
  }
  return self.currentWebViewController;
}

- (GreeJSWebViewController *)currentWebViewController
{
  if (!currentWebViewController_) {
    [self prepareNextWebViewController];
  }
  return currentWebViewController_;
}

@end
