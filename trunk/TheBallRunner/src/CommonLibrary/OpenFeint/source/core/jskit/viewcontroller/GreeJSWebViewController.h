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

#import <UIKit/UIKit.h>

@class GreeJSHandler;
@class GreeJSInputViewController;
@class GreeJSExternalWebViewController;
@class GreeJSLoadingIndicatorView;
@class GreeJSWebViewControllerPool;

@interface GreeJSWebViewController : UIViewController
<
  UIWebViewDelegate, UIScrollViewDelegate,
  UIImagePickerControllerDelegate, UINavigationControllerDelegate,
  UIActionSheetDelegate, UIAlertViewDelegate
>
{
@protected
  GreeJSHandler *handler_;
  GreeJSWebViewController *nextWebViewController_;
  UIScrollView *scrollView_;
  BOOL canPullToRefresh_;
  id originalScrollViewDelegate_;
}
@property(readonly) UIWebView *webView;
@property(readonly) GreeJSHandler *handler;
@property(readonly) GreeJSLoadingIndicatorView *loadingIndicatorView;
@property(readonly) NSDictionary *pendingLoadRequest;
@property(nonatomic, assign) GreeJSWebViewController *beforeWebViewController;
@property(nonatomic, retain) GreeJSWebViewController *nextWebViewController;
@property(nonatomic, retain) GreeJSInputViewController *inputViewController;
@property(nonatomic, copy) NSString *modalRightButtonCallback;
@property(nonatomic, retain) NSDictionary *modalRightButtonCallbackInfo;
@property(assign) BOOL isJavascriptBridgeEnabled;
@property(nonatomic, readwrite, retain) NSString *networkErrorMessageFilename;
@property(nonatomic, readonly, assign) BOOL deadlyProtonErrorOccured;
@property(nonatomic, retain) GreeJSWebViewControllerPool *pool;
@property(nonatomic, copy) void (^preloadInitializeBlock)(GreeJSWebViewController *, GreeJSWebViewController *);

#pragma mark - Public Interface
- (void)setBackgroundColor:(UIColor*)color;
- (void)displayLoadingIndicator:(BOOL)display;
- (void)setTitleViewForNavigationItem:(UINavigationItem*)item;
- (void)setBackButtonForNavigationItem:(UINavigationItem*)item;
- (void)scrollToTop;
- (void)enableScrollsToTop;
- (void)disableScrollsToTop;
- (void)resetWebViewContents:(NSURL *)toURL;
- (void)retryToInitializeProton;

#pragma mark - Pending Request Handlers
- (void)setPendingLoadRequest:(NSString *)viewName params:(NSDictionary *)params;
- (void)setPendingLoadRequest:(NSString *)viewName params:(NSDictionary *)params options:(NSDictionary *)options;
- (void)resetPendingLoadRequest;

#pragma mark - Preload Next WebView Handlers.
- (GreeJSWebViewController *)preloadNextWebViewController;

@end
