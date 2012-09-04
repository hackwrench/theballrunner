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

#import <QuartzCore/QuartzCore.h>
#import "JSONKit.h"

#import "GreeJSWebViewController.h"
#import "GreeJSWebViewControllerPool.h"
#import "GreeJSHandler.h"
#import "GreeJSCommandEnvironment.h"
#import "GreeJSWebViewMessageEvent.h"
#import "GreeJSSubnavigationView.h"
#import "GreeJSSubnavigationMenuView.h"
#import "GreeJSPullToRefreshHeaderView.h"
#import "GreeJSLoadingIndicatorView.h"
#import "GreeJSWebViewController+PullToRefresh.h"
#import "GreeJSWebViewController+StateCommand.h"
#import "GreeJSWebViewController+Photo.h"
#import "GreeJSWebViewController+ModalView.h"
#import "GreeJSWebViewController+SubNavigation.h"

#import "GreeSettings.h"
#import "GreePlatform+Internal.h"
#import "GreeHTTPClient.h"
#import "GreeWebSessionRegenerator.h"
#import "NSString+GreeAdditions.h"
#import "UIWebView+GreeAdditions.h"
#import "NSBundle+GreeAdditions.h"
#import "UIImage+GreeAdditions.h"
#import "GreeLogger.h"
#import "NSURL+GreeAdditions.h"

#import "GreeNotificationBoardViewController.h"

#define kGreeJSWebViewConnectionFailureFileName @"GreePopupConnectionFailure.html"

@interface GreeJSWebViewController() <GreeJSCommandEnvironment>
@property(assign) BOOL isProton;
@property(assign) BOOL isDragging;
@property(assign) BOOL isPullLoading;
@property(nonatomic, retain) NSTimer *pullToRefreshTimeoutTimer;
@property(readonly) UIView *pullToRefreshBackground;
@property(readonly) GreeJSPullToRefreshHeaderView *pullToRefreshHeader;
@property(nonatomic, retain) GreeJSTakePhotoActionSheet *photoTypeSelector;
@property(nonatomic, retain) GreeJSTakePhotoPickerController *photoPickerController;
@property(nonatomic, retain) id popoverPhotoPicker;
@property(nonatomic, readwrite, retain) GreeJSSubnavigationView* subNavigationView;
@property(nonatomic, assign) BOOL connectionFailureContentsLoading;
@property(nonatomic, readwrite, assign) BOOL deadlyProtonErrorOccured;
@property(nonatomic, retain) NSSet *previousOrientations;

- (void)adjustWebViewContentInset;
- (void)onBackButtonPressed;
- (void)messageEventNotification:(NSNotification*)notification;
- (void)showHTTPErrorMessage:(NSError*)anError;
- (BOOL)shouldHandleRequest:(NSURLRequest*)request;
- (BOOL)handleSchemeItmsApps:(NSURLRequest*)request;
@end

@implementation GreeJSWebViewController
@synthesize webView = webView_;
@synthesize handler = handler_;
@synthesize beforeWebViewController = beforeWebViewController_;
@synthesize nextWebViewController = nextWebViewController_;
@synthesize inputViewController = inputViewController_;
@synthesize pendingLoadRequest = pendingLoadRequest_;
@synthesize loadingIndicatorView = loadingIndicatorView_;
@synthesize pullToRefreshHeader = pullToRefreshHeader_;
@synthesize pullToRefreshBackground = pullToRefreshBackground_;
@synthesize pullToRefreshTimeoutTimer = pullToRefreshTimeoutTimer_;
@synthesize modalRightButtonCallback = modalRightButtonCallback_;
@synthesize modalRightButtonCallbackInfo = modalRightButtonCallbackInfo_;
@synthesize subNavigationView = subNavigationView_;
@synthesize isProton = isProton_;
@synthesize isPullLoading = isPullLoading_;
@synthesize isDragging = isDragging_;
@synthesize isJavascriptBridgeEnabled = isJavascriptBridgeEnabled_;
@synthesize photoTypeSelector = photoTypeSelector_;
@synthesize photoPickerController = photoPickerController_;
@synthesize popoverPhotoPicker = popoverPhotoPicker_;
@synthesize connectionFailureContentsLoading = connectionFailureContentsLoading_;
@synthesize networkErrorMessageFilename = networkErrorMessageFilename_;
@synthesize deadlyProtonErrorOccured = deadlyProtonErrorOccured_;
@synthesize pool = pool_;
@synthesize preloadInitializeBlock = preloadInitializeBlock_;
@synthesize previousOrientations = previousOrientations_;



#pragma mark - Object Lifecycle

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  self.webView.delegate = nil;
  [webView_ release];
  webView_ = nil;

  handler_.currentCommand.environment = nil;
  [handler_ release];
  handler_ = nil;
  
  [nextWebViewController_ release];
  nextWebViewController_ = nil;

  [inputViewController_ release];
  inputViewController_ = nil;

  [pendingLoadRequest_ release];
  pendingLoadRequest_ = nil;

  [loadingIndicatorView_ release];
  loadingIndicatorView_ = nil;

  [subNavigationView_ release];
  subNavigationView_ = nil;

  [pullToRefreshHeader_ release];
  pullToRefreshHeader_ = nil;
  [pullToRefreshBackground_ release];
  pullToRefreshBackground_ = nil;

  self.modalRightButtonCallback = nil;
  self.modalRightButtonCallbackInfo = nil;
  self.beforeWebViewController = nil;
  self.pullToRefreshTimeoutTimer = nil;
  self.photoTypeSelector.delegate = nil;
  self.photoTypeSelector = nil;
  self.photoPickerController = nil;
  self.popoverPhotoPicker = nil;
  self.preloadInitializeBlock = nil;
  self.pool = nil;

  [super dealloc];
}

- (id)init
{
  self = [super init];
  if (self)
  {
    CGRect screen = [[UIScreen mainScreen] bounds];
    webView_ = [[UIWebView alloc] initWithFrame:screen];
    self.webView.scalesPageToFit = YES;
    self.webView.dataDetectorTypes = UIDataDetectorTypeNone;
    self.webView.delegate = self;
    
    handler_ = [[GreeJSHandler alloc] init];
    self.handler.webView = self.webView;
    self.isJavascriptBridgeEnabled = YES;
    self.subNavigationView = [[[GreeJSSubnavigationView alloc] initWithDelegate:self] autorelease];
    self.subNavigationView.frame = screen;
    
    scrollView_ = [webView_ valueForKey:@"_scrollView"];
    originalScrollViewDelegate_ = [[self.webView valueForKey:@"_scrollView"] delegate];
    [scrollView_ setDecelerationRate:UIScrollViewDecelerationRateNormal];
    scrollView_.delegate = self;

    loadingIndicatorView_ = [[GreeJSLoadingIndicatorView alloc] initWithLoadingIndicatorType:GreeJSLoadingIndicatorTypeDefault];
    pullToRefreshHeader_ = [[GreeJSPullToRefreshHeaderView alloc] init];
    pullToRefreshBackground_ =
      [[UIView alloc] initWithFrame:CGRectMake(0, 
                                               -screen.size.height - kGreeJSRefreshHeaderHeight, 
                                               screen.size.width, 
                                               screen.size.height)];
    self.pullToRefreshBackground.backgroundColor = self.pullToRefreshHeader.backgroundColor;
    self.pullToRefreshBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageEventNotification:)
                                                 name:kGreeJSWebViewMessageEventNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didFailWithErrorNotification:)
                                                 name:kGreeJSDidFailWithError object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notificationBoardDidLaunchNotification:)
                                                 name:GreeNotificationBoardDidLaunchNotification object:nil];
    [self setCanPullToRefresh:YES];

    self.modalRightButtonCallback = nil;
    self.modalRightButtonCallbackInfo = nil;
    self.networkErrorMessageFilename = kGreeJSWebViewConnectionFailureFileName;

    [self displayLoadingIndicator:YES];
  }
  return self;
}

#pragma mark - UIViewController Overrides
- (void)loadView
{
  self.view = self.subNavigationView;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self.subNavigationView setContentView:self.webView];
  [self setCanPullToRefresh:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  // Release next webview controller.
  // Next webview controller create at push/modal view. however, it is not released pop/dismiss view.
  // We should release it when displayed before view controller.
  if (self.nextWebViewController) {
    self.nextWebViewController = nil;
  }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self adjustWebViewContentInset];
}

#pragma mark - Message Event forwarder

- (void)messageEventNotification:(NSNotification*)notification
{
  GreeJSWebViewMessageEvent *event = [notification.userInfo objectForKey:kGreeJSWebViewMessageEventObjectKey];
  [event fireMessageEventInWebView:self.webView];
}

#pragma mark - UIWebViewDelegate methods

- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
  if([[GreePlatform sharedInstance].settings boolValueForSetting:GreeSettingShowConnectionServer]){
    if (!([[request.URL path] isEqualToString:@"/"] && ![request.URL query] && ![request.URL fragment])) {
      [self.webView attachLabelWithURL:request.URL position:GreeWebViewUrlLabelPositionBottom];
    }
  }
  id regenerator =
  [GreeWebSessionRegenerator generatorIfNeededWithRequest:request webView:webView delegate:nil
                                     showHttpErrorBlock:^(NSError* error) {
                                       [self showHTTPErrorMessage:error];
                                     }];
  if (regenerator) {
    return NO;
  }
  
  if ([GreeJSHandler executeCommandFromRequest:request handler:self.handler environment:self])
  {
    return NO;
  }
  
  if (connectionFailureContentsLoading_) {
    deadlyProtonErrorOccured_ = YES;
    connectionFailureContentsLoading_ = NO;
    return YES;
  }

  if ([self shouldHandleRequest:request] == NO) {
    return NO;
  }

  BOOL clearCurrentContent = YES;
  if ([request.URL isGreeDomain] == NO) {
    if (navigationType == UIWebViewNavigationTypeOther) {
      NSString* referer = [request.allHTTPHeaderFields objectForKey:@"Referer"];
      NSString* currentLocation = [webView.request.mainDocumentURL absoluteString];
      // request is for iframe or something.
      if (referer != nil && currentLocation != nil) {
        BOOL isSubsequentPageRequest = [referer isEqualToString:currentLocation];
        if (isSubsequentPageRequest) {
          clearCurrentContent = NO;
        }
      }
    }
  }

  if (clearCurrentContent) {
    // To avoid lag move next Page.
    [self resetWebViewContents:[[webView request] URL]];
  }
  return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
  self.isProton = NO;

  // Set a flag in window.name to distinguish proton clients from mobile safari.
  [self.webView stringByEvaluatingJavaScriptFromString:@"window.name='protonApp'"];
  if (!self.isPullLoading) {
    [self displayLoadingIndicator:YES];
  }
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
  self.isProton = [[self handler] isProtonPage];
  if (!self.isProton) {
    [self displayLoadingIndicator:NO];
    [self stopLoading];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
  [self stopLoading];

  //MARK:Loading indicator will be removed after completion showHTTPErrorMessage.
  //[self displayLoadingIndicator:NO];
  [self showHTTPErrorMessage:error];
}

#pragma mark - GreeJSCommandEnvironment

- (UIViewController*)viewControllerForCommand:(GreeJSCommand*)command {
  return self;
}

- (UIWebView*)webviewForCommand:(GreeJSCommand*)command {
  return self.webView;
}

- (id)instanceOfProtocol:(Protocol*)protocol {
  if ([self conformsToProtocol:protocol]) {
    return self;
  }
  
  return nil;
}

- (BOOL)shouldExecuteCommand:(GreeJSCommand*)command withParameters:(NSDictionary*)parameters {
  return YES;
}

#pragma mark - Public Interface

- (void)setBackgroundColor:(UIColor*)color
{
  self.subNavigationView.backgroundColor = color;
}

- (void)setTitleViewForNavigationItem:(UINavigationItem*)item
{
  UIImageView *greeLogo = [[[UIImageView alloc] initWithImage:[UIImage greeImageNamed:@"gree_logo.png"]] autorelease];
  item.titleView = greeLogo;
}

- (void)setBackButtonForNavigationItem:(UINavigationItem*)item
{
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.autoresizingMask = UIViewAutoresizingNone;
  
  NSString *defaultBackButton;
  NSString *highlightedBackButton;
  if (self.navigationController.navigationBar.barStyle == UIBarStyleBlack) {
    defaultBackButton = @"gree_um_btn_back_default.png";
    highlightedBackButton = @"gree_um_btn_back_highlight.png";
  }
  else {
    defaultBackButton = @"gree_btn_back_default.png";
    highlightedBackButton = @"gree_btn_back_highlight.png";
  }

	UIImage *bg_image = [UIImage greeImageNamed:defaultBackButton];
	UIImage *bg_image_highlighted = [UIImage greeImageNamed:highlightedBackButton];
  
	button.frame = CGRectMake(0, 0, bg_image.size.width, bg_image.size.height);
  [button setBackgroundImage:bg_image forState:UIControlStateNormal];
  [button setBackgroundImage:bg_image_highlighted forState:UIControlStateHighlighted];
	
  [button addTarget:self action:@selector(onBackButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	item.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:button] autorelease];
}

- (void)scrollToTop
{
  [self.webView stringByEvaluatingJavaScriptFromString:@"window.scrollTo(0, 0)"];
}

- (void)enableScrollsToTop
{
  NSArray *subviews = [self.webView subviews];
  for (UIView *view in subviews) {
    if ([view respondsToSelector:@selector(setScrollsToTop:)]) {
      [(UIScrollView *)view setScrollsToTop:YES];
    }
  }
}

- (void)disableScrollsToTop
{
  NSArray *subviews = [self.webView subviews];
  for (UIView *view in subviews) {
    if ([view respondsToSelector:@selector(setScrollsToTop:)]) {
      [(UIScrollView *)view setScrollsToTop:NO];
    }
  }
}

- (void)displayLoadingIndicator:(BOOL)display
{
  if (display) {
    if (self.loadingIndicatorView.superview) {
      return;
    }
    self.loadingIndicatorView.center = self.view.center;
    [self.view addSubview:self.loadingIndicatorView];
  } else {
    [self.loadingIndicatorView removeFromSuperview];
  }
}

- (void)resetWebViewContents:(NSURL *)toURL
{
  if (self.isProton) {
    NSDictionary *params = [[toURL query] greeDictionaryFromQueryString];
    [[self handler] resetToView:[params objectForKey:@"view"] toParams:params];
  } else {
    [self.webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML = ''"];
  }
}

#pragma mark - Pending Request Handlers

- (void)setPendingLoadRequest:(NSString *)viewName params:(NSDictionary *)params
{
  [self setPendingLoadRequest:viewName params:params options:nil];
}

- (void)setPendingLoadRequest:(NSString *)viewName params:(NSDictionary *)params options:(NSDictionary *)options
{
  [self resetPendingLoadRequest];
  pendingLoadRequest_ = [[NSDictionary dictionaryWithObjectsAndKeys:
                          viewName, @"view",
                          params, @"params",
                          options, @"options",
                          nil] retain];
}

- (void)resetPendingLoadRequest
{
  [pendingLoadRequest_ release];
  pendingLoadRequest_ = nil;
}

- (void)retryToInitializeProton
{
  [webView_ reload];
  deadlyProtonErrorOccured_ = NO;
}

#pragma mark - Preload Instance Initialize Handlers

- (GreeJSWebViewController *)preloadNextWebViewController
{
  GreeJSWebViewController *webViewController = nil;
  if (self.pool) {
    webViewController = [self.pool take];
    webViewController.pool = self.pool;
  } else {
    webViewController = [[[GreeJSWebViewController alloc] init] autorelease];
  }

  if (self.preloadInitializeBlock) {
    self.preloadInitializeBlock(self, webViewController);
    webViewController.preloadInitializeBlock = self.preloadInitializeBlock;
  }

  self.nextWebViewController = webViewController;
  return webViewController;
}

#pragma mark - Internal Methods

- (void)adjustWebViewContentInset
{
  // interfaceOrientation of rootController of Universal menu controller is not updated after rotation
  // so that use the orientation set by willRotateToInterfaceOrientation instead.
  [subNavigationView_ setNeedsLayout];
  [pullToRefreshHeader_ setNeedsLayout];
}

- (void)onBackButtonPressed
{
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)showHTTPErrorMessage:(NSError*)anError
{
  if (anError.code != kCFURLErrorCancelled) {
    [self setCanPullToRefresh:NO];
    [self configureSubnavigationMenuWithParams:nil];
  }
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  [self.webView showHTTPErrorMessage:anError loadingFlag:&connectionFailureContentsLoading_
    bodyStreamExhaustedErrorFilePath:[[NSBundle greePlatformCoreBundle] pathForResource:self.networkErrorMessageFilename ofType:nil]];
}

- (void)didFailWithErrorNotification:(NSNotification*)notification
{
  NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary:notification.userInfo];
  NSString* urlString = [info objectForKey:@"url"];
  NSURL* url = [NSURL URLWithString:urlString];
  if (url) {
    [info setObject:url forKey:@"NSErrorFailingURLKey"];
    [info setObject:urlString forKey:NSURLErrorFailingURLStringErrorKey];
  }
  NSError* error = [NSError errorWithDomain:@"" code:kCFURLErrorUnknown userInfo:info];
  [self showHTTPErrorMessage:error];
}
- (void)notificationBoardDidLaunchNotification:(NSNotification*)notification
{
  if (self.navigationController.topViewController == self) {
    [self.webView endEditing:YES];
  }
}

- (BOOL)shouldHandleRequest:(NSURLRequest*)request
{
  NSString* scheme = request.URL.scheme;
  if (
      [scheme isEqualToString:@"http"] ||
      [scheme isEqualToString:@"https"]
      ) {
    return YES;
  } else if (
             [scheme isEqualToString:@"itms-apps"] ||
             [scheme isEqualToString:@"itms"]
             ) {
    return [self handleSchemeItmsApps:request];
  }
  return NO;
}

- (BOOL)handleSchemeItmsApps:(NSURLRequest*)request
{
  [[UIApplication sharedApplication] openURL:request.URL];
  return NO;
}

@end
