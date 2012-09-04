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
#import "GreeError+Internal.h"
#import "GreeGlobalization.h"
#import "GreeLogger.h"
#import "GreeNotification+Internal.h"
#import "GreeNotificationBoardViewController.h"
#import "GreePlatform+Internal.h"
#import "GreeWebSession.h"
#import "GreeWebSessionRegenerator.h"
#import "NSString+GreeAdditions.h"
#import "NSURL+GreeAdditions.h"
#import "UIImage+GreeAdditions.h"
#import "UIWebView+GreeAdditions.h"
#import "UIViewController+GreeAdditions.h"
#import "UIViewController+GreePlatform.h"
#import "GreeNSNotification.h"
#import "GreeSettings.h"
#import "GreeJSHandler.h"
#import "GreeJSCommandEnvironment.h"

#define kGreeNotificationBoardConnectionFailureFileName @"GreePopupConnectionFailure.html"

static const CGFloat navigationBarHeightPortrait = 44.0f;
static const CGFloat navigationBarHeightLandscape = 32.0f;

NSString* const GreeNotificationBoardDidLaunchNotification = @"GreeNotificationBoardDidLaunchNotification";
NSString* const GreeNotificationBoardDidDismissNotification = @"GreeNotificationBoardDidDismissNotification";

@interface GreeNotificationBoardViewController () <GreeJSCommandEnvironment>
@property (nonatomic, retain) GreeJSHandler *handler;
@property BOOL popItemLock;
@property BOOL loadingPreviousPage;
@property (nonatomic, retain) NSURLRequest* currentRequest;
@property NSUInteger webSessionRegeneratingCount;
@property BOOL connectionFailureContentsLoading;
@property UIStatusBarStyle originalStatusBarStyle;

- (void)dismiss;
- (void)pushNextItem:(BOOL)showBackButton;
- (void)showHTTPErrorMessage:(NSError*)anError;
- (CGRect)navigationBarFrameForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (CGRect)webViewFrame;
- (BOOL)shouldDisplayBackButtonForURL:(NSURL*)anURL;
- (void)hideBackButton;
- (void)updateBackButtonAppearanceForWebView:(UIWebView*)aWebView;
@end


@implementation GreeNotificationBoardViewController
@synthesize webView = _webView;
@synthesize navigationBar = _navigationBar;
@synthesize URL = _URL;
@synthesize handler = _handler;
@synthesize popItemLock = _popItemLock;
@synthesize loadingPreviousPage = _loadingPreviousPage;
@synthesize currentRequest = _currentRequest;
@synthesize delegate = _delegate;
@synthesize webSessionRegeneratingCount = _webSessionRegeneratingCount;
@synthesize connectionFailureContentsLoading = _connectionFailureContentsLoading;
@synthesize originalStatusBarStyle = _originalStatusBarStyle;

@synthesize results;

#pragma mark - Object Lifecycle

- (id)initWithType:(GreeNotificationBoardLaunchType)type parameters:(NSDictionary*)parameters {
  NSURL *URL = [[self class] URLForLaunchType:type withParameters:parameters];
  return [self initWithURL:URL];
}

- (id)initWithURL:(NSURL*)URL
{
  if ((self = [super initWithNibName:nil bundle:nil])) {
    _URL = [URL retain];
    _loadingPreviousPage = YES;
    _popItemLock = NO;
    _connectionFailureContentsLoading = NO;
    _handler = [[GreeJSHandler alloc] init];
    _currentRequest = nil;
  }
  
  return self;
}

- (void)dealloc
{
  [[UIApplication sharedApplication] setStatusBarStyle:self.originalStatusBarStyle animated:YES];

  [[NSNotificationCenter defaultCenter]
    postNotificationName:GreeNotificationBoardDidDismissNotification
    object:nil
    userInfo:results];
  
  [[NSNotificationCenter defaultCenter]
    postNotificationName:GreeNSNotificationKeyDidCloseNotification
    object:self
    userInfo:results];
        
  [[GreePlatform sharedInstance] updateBadgeValuesWithBlock:nil];

  [_handler release];
  [_URL release];
  [_webView release];
  [_navigationBar release];
  _delegate = nil;
  [_currentRequest release];
  [super dealloc];
}


#pragma mark - Public Interface
+ (NSURL*)URLForLaunchType:(GreeNotificationBoardLaunchType)aType withParameters:(NSDictionary*)parameters
{
  NSURL* URL = nil;
  GreeSettings* settings = [GreePlatform sharedInstance].settings;
  
  switch (aType){
    case GreeNotificationBoardLaunchWithSns:
      URL = [NSURL URLWithString:
             [NSString stringWithFormat:@"%@%@",
              [settings stringValueForSetting:GreeSettingServerUrlNotice],
              @"/sns"]];
      break;
      
    case GreeNotificationBoardLaunchWithPlatform:
      URL = [NSURL URLWithString:
             [NSString stringWithFormat:@"%@%@",
              [settings stringValueForSetting:GreeSettingServerUrlNotice],
              @"/game"]];
      break;
      
    case GreeNotificationBoardLaunchWithExternalUrl:
      URL = [NSURL URLWithString:
             [NSString stringWithFormat:@"%@",
              [parameters objectForKey:@"url"]]];
      break;
      
    case GreeNotificationBoardLaunchWithInternalAction:
      URL = [NSURL URLWithString:
             [NSString stringWithFormat:@"%@%@",
              [settings stringValueForSetting:GreeSettingServerUrlNotice],
              [parameters objectForKey:@"action"]]];
      break;
      
    case GreeNotificationBoardLaunchWithMessageDetail:
      URL = [NSURL URLWithString:
             [NSString stringWithFormat:@"%@%@",
              [settings stringValueForSetting:GreeSettingServerUrlGamesMessageDetail],
              [parameters objectForKey:@"info-key"]]]; 
      break;
      
    case GreeNotificationBoardLaunchWithRequestDetail:
      URL = [NSURL URLWithString:
             [NSString stringWithFormat:@"%@%@",
              [settings stringValueForSetting:GreeSettingServerUrlGamesRequestDetail],
              [parameters objectForKey:@"info-key"]]];
      break;
      
    default:
      URL = [NSURL URLWithString:
              [NSString stringWithFormat:@"%@%@",
                [settings stringValueForSetting:GreeSettingServerUrlNotice],
                @"/"]];
      break;
  }

  return URL;
}

- (void)backButtonPressed:(id)sender
{
  [self.navigationBar popNavigationItemAnimated:NO];
}

- (void)doneButtonPressed:(id)sender
{
  [self dismiss];
}

- (void)dismiss
{
  if ([self.delegate respondsToSelector:@selector(notificationBoardCloseButtonPressed:)]) {
    [self.delegate notificationBoardCloseButtonPressed:self];
  }
}


#pragma mark - UIViewController Overrides

- (void)loadView
{
  UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
  view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  view.opaque = YES;
  
  self.view = view;
  [view release];
  
  _navigationBar = [[UINavigationBar alloc] initWithFrame:
    [self navigationBarFrameForInterfaceOrientation:self.interfaceOrientation]];
  _navigationBar.autoresizesSubviews = YES;

  _navigationBar.delegate = self;
  
  UIImage *navBar44 = [UIImage greeImageNamed:@"gree_nav_bar_modal_vertical.png"];
  
  if ([_navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
    UIImage *navBar32 = [UIImage greeImageNamed:@"gree_nav_bar_modal_horizontal.png"];

    UIEdgeInsets navBar44Insets = UIEdgeInsetsMake(19, 4, 23, 4);
    [_navigationBar setBackgroundImage:[navBar44 resizableImageWithCapInsets:navBar44Insets] forBarMetrics:UIBarMetricsDefault];
    UIEdgeInsets navBar32Insets = UIEdgeInsetsMake(13, 4, 18, 4);
    [_navigationBar setBackgroundImage:[navBar32 resizableImageWithCapInsets:navBar32Insets] forBarMetrics:UIBarMetricsLandscapePhone];
    _navigationBar.backgroundColor = [UIColor blackColor];
  } else {
    UIImageView *iOS4NavBarBackground = [[UIImageView alloc] initWithImage:[navBar44 stretchableImageWithLeftCapWidth:4 topCapHeight:0]];
    iOS4NavBarBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    iOS4NavBarBackground.frame = CGRectMake(0,0,_navigationBar.bounds.size.width,_navigationBar.bounds.size.height);
    iOS4NavBarBackground.backgroundColor = [UIColor blackColor];
    [_navigationBar insertSubview:iOS4NavBarBackground atIndex:0];
    [iOS4NavBarBackground release];
  }

  [view addSubview:_navigationBar];
  
  _webView = [[UIWebView alloc] initWithFrame:[self webViewFrame]];
  _webView.delegate = self;
  _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  [view addSubview:_webView];
  _handler.webView = _webView;
  
  self.originalStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
  [self pushNextItem:NO];
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  NSURLRequest *urlRequest = [NSURLRequest requestWithURL:self.URL];
  [self.webView loadRequest:urlRequest];
}

- (void)viewDidAppear:(BOOL)animated {
  [[NSNotificationCenter defaultCenter] postNotificationName:GreeNotificationBoardDidLaunchNotification object:nil];

  self.navigationBar.frame = [self navigationBarFrameForInterfaceOrientation:self.interfaceOrientation];
  self.webView.frame = [self webViewFrame];
  
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
}

- (void)viewDidUnload
{
  self.webView = nil;
  self.navigationBar = nil;
  
  [super viewDidUnload];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  self.navigationBar.frame = [self navigationBarFrameForInterfaceOrientation:toInterfaceOrientation];
  self.webView.frame = [self webViewFrame];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  if ([GreePlatform sharedInstance].manuallyRotate) {
    return [GreePlatform sharedInstance].interfaceOrientation == toInterfaceOrientation;
  }
  
  return YES;
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([self class]), self];
}

- (void)presentGreeDashboardWithBaseURL:(NSURL *)URL delegate:(id<GreeDashboardViewControllerDelegate>)delegate animated:(BOOL)animated completion:(void (^)(void))completion {
  UIViewController *presentingViewController = [self greePresentingViewController];
  
  [presentingViewController dismissGreeNotificationBoardAnimated:animated completion:^(id results){
    [presentingViewController presentGreeDashboardWithBaseURL:URL delegate:delegate animated:animated completion:completion];
  }];
}

- (void)presentGreeDashboardWithParameters:(NSDictionary *)parameters animated:(BOOL)animated {
  UIViewController *presentingViewController = [self greePresentingViewController];
  
  [presentingViewController dismissGreeNotificationBoardAnimated:animated completion:^(id results){
    [presentingViewController presentGreeDashboardWithParameters:parameters animated:animated];
  }];  
}


#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)_webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
  NSURL *aURL = request.URL;
  GreeLog(@"URL:%@", aURL);

  if([[GreePlatform sharedInstance].settings boolValueForSetting:GreeSettingShowConnectionServer]){
    [self.webView attachLabelWithURL:request.URL position:GreeWebViewUrlLabelPositionTop];
  }

  if (_connectionFailureContentsLoading) {
    _connectionFailureContentsLoading = NO;
    return YES;
  }

  // First, we should handle the <a href="#" ...> request.
  if ([[request.URL absoluteString] hasSuffix:@"#"]) {
    return YES;
  }

  if ([[aURL scheme] isEqualToString:@"http"] || [[aURL scheme] isEqualToString:@"https"]) {
    if (!_currentRequest) {
      _currentRequest = [request retain];
      [self.webView performSelector:@selector(showActivityIndicator) withObject:nil afterDelay:0.f];
      [self.webView performSelector:@selector(loadRequest:) withObject:_currentRequest afterDelay:0.2f];
      return NO;
    } else {
      [_currentRequest release], _currentRequest = nil;
    }
  }

  // handle web session regenerating if necessary
  id regenerator =
  [GreeWebSessionRegenerator generatorIfNeededWithRequest:request webView:self.webView delegate:nil
    showHttpErrorBlock:^(NSError* error) {
      [self showHTTPErrorMessage:error];
    }
  ];
  if (regenerator) {
    return NO;
  }

  if ([GreeJSHandler executeCommandFromRequest:request handler:self.handler environment:self]) {
    return NO;
  }
  
  return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
  [self updateBackButtonAppearanceForWebView:webView];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)anError
{
  GreeLog(@"URL:%@ error:%@", webView.request.URL, anError);

  [self updateBackButtonAppearanceForWebView:webView];
  
  if (([anError.domain isEqualToString:@"WebKitErrorDomain"] && [anError code] == 102) ||
      [anError code] == kCFURLErrorCancelled) {
    // Ignore it.
    return;
  }
  [self showHTTPErrorMessage:anError];
}


#pragma mark - UINavigationBarDelegate

- (void)navigationBar:(UINavigationBar *)aNavigationBar didPopItem:(UINavigationItem *)item
{
  if (!_popItemLock) {
    [self.webView goBack];
    self.loadingPreviousPage = YES;
  }
}


#pragma mark - GreeJSCommandEnvironment

- (UIViewController*)viewControllerForCommand:(GreeJSCommand*)command
{
  return self;
}

- (UIWebView*)webviewForCommand:(GreeJSCommand*)command
{
  return self.webView;
}

- (id)instanceOfProtocol:(Protocol*)protocol 
{
  if ([self conformsToProtocol:protocol]) {
    return self;
  }
  
  return nil;
}

- (BOOL)isJavascriptBridgeEnabled
{
  return YES;
}

- (BOOL)shouldExecuteCommand:(GreeJSCommand*)command withParameters:(NSDictionary*)parameters
{
  return YES;
}


#pragma mark - Private methods

-(void)pushNextItem:(BOOL)showBackButton
{  
  UINavigationItem *item = [[UINavigationItem alloc] init];
  UILabel *titleView = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  titleView.textColor = [UIColor whiteColor];
  titleView.backgroundColor = [UIColor clearColor];
  titleView.font = [UIFont boldSystemFontOfSize:20.0f];
  titleView.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
  titleView.text = GreePlatformString(@"notificationboadrd.navigationbar.title", @"Notifications");
  [titleView sizeToFit];
  item.titleView = titleView;
  
  if (showBackButton) {
    UIImage *backButtonImage = [UIImage greeImageNamed:@"gree_btn_back_default.png"];
    UIImage *backButtonImageHighlight = [UIImage greeImageNamed:@"gree_btn_back_highlight.png"];
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0, 0, backButtonImage.size.width, backButtonImage.size.height);
    [backButton setImage:backButtonImage forState:UIControlStateNormal];
    [backButton setImage:backButtonImageHighlight forState:UIControlStateHighlighted];
    [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    item.leftBarButtonItem = leftBarButtonItem;
    [leftBarButtonItem release];
  }
  
  UIImage *closeButtonImage = [UIImage greeImageNamed:@"gree_btn_close_default.png"];
  UIImage *closeButtonImageHighlight = [UIImage greeImageNamed:@"gree_btn_close_highlight.png"];
  UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  closeButton.frame = CGRectMake(0, 0, closeButtonImage.size.width, closeButtonImage.size.height);
  [closeButton setImage:closeButtonImage forState:UIControlStateNormal];
  [closeButton setImage:closeButtonImageHighlight forState:UIControlStateHighlighted];
  [closeButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
  
  UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:closeButton];
  item.rightBarButtonItem = rightBarButtonItem;
  [rightBarButtonItem release];
      
  [self.navigationBar pushNavigationItem:item animated:NO];
  [item release];
}

- (void)showHTTPErrorMessage:(NSError*)anError
{
  [self.webView showHTTPErrorMessage:anError loadingFlag:&_connectionFailureContentsLoading
    bodyStreamExhaustedErrorFilePath:[[NSBundle greePlatformCoreBundle] pathForResource:kGreeNotificationBoardConnectionFailureFileName ofType:nil]];
}

- (CGRect)navigationBarFrameForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  CGFloat navigationBarHeight = UIInterfaceOrientationIsPortrait(interfaceOrientation) ? 
      navigationBarHeightPortrait : navigationBarHeightLandscape;
      
  return CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, navigationBarHeight);
}

- (CGRect)webViewFrame
{
  CGFloat navBarHeight = self.navigationBar.bounds.size.height;
  return CGRectMake(
    0.0f,
    navBarHeight,
    self.view.bounds.size.width,
    self.view.bounds.size.height - navBarHeight
  );
}

- (BOOL)shouldDisplayBackButtonForURL:(NSURL*)anURL
{
  NSURL* snsURL = [[self class] URLForLaunchType:GreeNotificationBoardLaunchWithSns withParameters:nil];
  NSURL* gameURL = [[self class] URLForLaunchType:GreeNotificationBoardLaunchWithPlatform withParameters:nil];
  NSString* noticeURLString = [NSString stringWithFormat:@"%@/", [[[GreePlatform sharedInstance] settings] stringValueForSetting:GreeSettingServerUrlNotice]];
  NSString* absoluteURLString = [anURL absoluteString];
  
  if ([anURL isFileURL] ||
      [[snsURL absoluteString] isEqualToString:absoluteURLString] ||
      [[gameURL absoluteString] isEqualToString:absoluteURLString] ||
      [noticeURLString isEqualToString:absoluteURLString] ||
      [[anURL absoluteString] hasPrefix:@"about://error"]) {
    return NO;
  } else {
    return YES;
  }
}

- (void)hideBackButton
{
  _popItemLock = YES;
  while (self.navigationBar.backItem) {
    [self.navigationBar popNavigationItemAnimated:NO];
  }
  _popItemLock = NO;
}

- (void)updateBackButtonAppearanceForWebView:(UIWebView*)aWebView
{
  if (self.loadingPreviousPage) {
    self.loadingPreviousPage = NO;
    if (![self shouldDisplayBackButtonForURL:aWebView.request.URL]) {
      [self hideBackButton];
    }
  } else {
    if ([self shouldDisplayBackButtonForURL:aWebView.request.URL]) {
      [self pushNextItem:YES];
    } else {
      if (![aWebView.request.URL isFileURL]) {
        [self hideBackButton];
      }
    }
  }
}


@end
