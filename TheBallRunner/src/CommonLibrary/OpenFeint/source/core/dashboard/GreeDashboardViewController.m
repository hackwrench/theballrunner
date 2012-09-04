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

#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/CATransaction.h>
#import <QuartzCore/CAMediaTimingFunction.h>

#import "GreeDashboardViewController.h"
#import "GreeJSWebViewController.h"
#import "GreeJSWebViewControllerPool.h"
#import "GreeJSWebViewController+PullToRefresh.h"
#import "GreeJSLoadingIndicatorView.h"
#import "GreeWebAppCache.h"

#import "UIImage+GreeAdditions.h"

#import "GreeNotificationBoardViewController.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"

#import "GreeJSNotificationButton.h"
#import "GreeBadgeValues+Internal.h"
#import "GreeAnalyticsEvent.h"

#import "UIViewController+GreeAdditions.h"
#import "UIViewController+GreeAdditions.h"
#import "NSString+GreeAdditions.h"
#import "GreeNSNotification.h"
#import "GreeDashboardViewControllerLaunchMode.h"
#import "GreeLogger.h"

#import "GreeJSWebViewController.h"
#import "GreeJSExternalWebViewController.h"

#import "NSURL+GreeAdditions.h"

#import "GreeJSHandler.h"

#define kGreeJSWebViewUniversalMenuConnectionFailureFileName @"GreeUniversalMenuConnectionFailure.html"

@interface GreeDashboardViewController ()
@property (nonatomic, retain) UIImageView* iOS4NavBarBackground;
@property UIStatusBarStyle originalStatusBarStyle;

+ (NSURL*)URLFromMenuViewController:(UIViewController*)viewController;
+ (NSString*)viewNameFromURL:(NSURL*)url;
+ (NSString*)dashboardPathString:(NSString*)pathString appId:(NSString*)appId userId:(NSString*)userId;
+ (NSString*)createGameDashboardUrlParams:(NSString*)appId userId:(NSString*)userId;

- (void)insertDashboardButtons:(UINavigationItem*)item;
- (void)createViewControllers;
- (void)createRootViewController;
- (void)createMenuViewController;
- (void)enableScroll:(BOOL)enable subviewsOf:(UIView*)view;
- (void)enableMenuViewController:(BOOL)enable;
- (void)loadBadgeValue;
@end


@implementation GreeDashboardViewController
@synthesize closeButton = _closeButton;
@synthesize notificationButton = _notificationButton;
@synthesize baseURL = _baseURL;
@synthesize iOS4NavBarBackground = _iOS4NavBarBackground;
@synthesize originalStatusBarStyle = _originalStatusBarStyle;
@synthesize results = _results;
@synthesize dashboardDelegate = _dashboardDelegate;

#pragma mark - Object Lifecycle

- (id)initWithPath:(NSString*)path {
  NSString* gameDashboardBaseURLString = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlApps];
  
  NSURL* gameDashboardBaseURL = [NSURL URLWithString:gameDashboardBaseURLString];
  NSURL *URL = nil;
  
  if (path != nil) {
    URL = [NSURL URLWithString:path relativeToURL:gameDashboardBaseURL];
  } else {
    NSString *applicationIdString = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
    NSString *gameDashboardPath = [NSString stringWithFormat:@"gd?app_id=%@", applicationIdString];
    URL = [NSURL URLWithString:gameDashboardPath relativeToURL:gameDashboardBaseURL];
  }
  
  return [self initWithBaseURL:URL];
}

- (id)initWithBaseURL:(NSURL*)baseURL;
{
  if ((self = [super initWithNibName:nil bundle:nil])) {
    _baseURL = [baseURL retain];
    
    GreeAnalyticsEvent *event = [GreeAnalyticsEvent
                               eventWithType:@"pg"
                               name:[[self class] viewNameFromURL:baseURL]
                               from:@"game"
                               parameters:[[baseURL query] greeDictionaryFromQueryString]];
  
    [[GreePlatform sharedInstance] addAnalyticsEvent:event];
  }
  
  return self;
}

- (void)dealloc
{
  [[UIApplication sharedApplication] setStatusBarStyle:self.originalStatusBarStyle animated:YES]; 
  NSURL *fromURL = [[self class] URLFromMenuViewController:self.rootViewController];
  
  GreeAnalyticsEvent *event = [GreeAnalyticsEvent
    eventWithType:@"pg"
    name:@"game"
    from:[[self class] viewNameFromURL:fromURL] parameters:nil];
  [[GreePlatform sharedInstance] addAnalyticsEvent:event];
  
  [[NSNotificationCenter defaultCenter]
    postNotificationName:GreeNSNotificationKeyDidCloseNotification
    object:self
    userInfo:_results];

  [_results release];
  [_closeButton release];
  [_notificationButton release];
  [_baseURL release];
  [_iOS4NavBarBackground release];
  
  [super dealloc];
}

#pragma mark - Public Interface

+ (NSURL*)dashboardURLWithParameters:(NSDictionary *)parameters
{  
  NSString* gameDashboardBaseURLString = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlApps];
  NSString* gameDashboardPath = nil;  
  NSString* gameDashBoadPathAddParamsUrl = nil;
  
  if(parameters!=nil)
  {
    gameDashboardPath = [parameters objectForKey:GreeDashboardMode];
    NSString* gameDashboardAppId = [parameters objectForKey:GreeDashboardAppId];
    NSString* gameDashboardUserId = [parameters objectForKey:GreeDashboardUserId];
    
    if ([gameDashboardPath length]!=0) {
      
      if ([gameDashboardPath isEqualToString:GreeDashboardModeUsersList] ||
          [gameDashboardPath isEqualToString:GreeDashboardModeUsersInvites] ||
          [gameDashboardPath isEqualToString:GreeDashboardModeAppSetting] ) {
        if (gameDashboardUserId!=nil) {
          gameDashboardUserId = nil;
        }
      }
      
      gameDashBoadPathAddParamsUrl = [self dashboardPathString:gameDashboardPath appId:gameDashboardAppId userId:gameDashboardUserId];
      
      if ([gameDashboardPath isEqualToString:GreeDashboardModeTop] ||
          [gameDashboardPath isEqualToString:GreeDashboardModeRankingList] ||
          [gameDashboardPath isEqualToString:GreeDashboardModeUsersList] ||
          [gameDashboardPath isEqualToString:GreeDashboardModeAchievementList] ) {
        
        gameDashBoadPathAddParamsUrl = [self dashboardPathString:gameDashboardPath appId:gameDashboardAppId userId:gameDashboardUserId];
        
      } else if ([gameDashboardPath isEqualToString:GreeDashboardModeRankingDetails]) {
        NSString* strLeaderboarderId = [parameters objectForKey:GreeDashboardLeaderboardId];        
        if ([strLeaderboarderId length]!=0) {
          if ([gameDashBoadPathAddParamsUrl rangeOfString:@"?"].location == NSNotFound) {
            gameDashBoadPathAddParamsUrl = [gameDashBoadPathAddParamsUrl stringByAppendingFormat:@"?%@=%@", GreeDashboardLeaderboardId, strLeaderboarderId];
          } else {
            gameDashBoadPathAddParamsUrl = [gameDashBoadPathAddParamsUrl stringByAppendingFormat:@"&%@=%@", GreeDashboardLeaderboardId, strLeaderboarderId];
          }            
        } else {
          GreeLogWarn(@"Cannot launch the selected dashboard without '%@'", GreeDashboardLeaderboardId);
          gameDashBoadPathAddParamsUrl = [self dashboardPathString:GreeDashboardModeTop appId:gameDashboardAppId userId:gameDashboardUserId];
        }
      } else if ([gameDashboardPath isEqualToString:GreeDashboardModeAppSetting]) {
        NSString* applicationIdString = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
        gameDashBoadPathAddParamsUrl = [NSString stringWithFormat:@"%@%@", GreeDashboardModeAppSetting, applicationIdString];
      } else if ([gameDashboardPath isEqualToString:GreeDashboardModeUsersInvites]) {
        NSString* applicationIdString = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
        gameDashboardBaseURLString = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlPf];
        gameDashBoadPathAddParamsUrl = [NSString stringWithFormat:@"%@%@", GreeDashboardModeUsersInvites, applicationIdString];        
      } else {        
        return [NSURL URLWithString:[NSString stringWithFormat:@"%@", gameDashboardPath]];
      }      
    } else {
      gameDashBoadPathAddParamsUrl = [self dashboardPathString:GreeDashboardModeTop appId:gameDashboardAppId userId:gameDashboardUserId];
    }
  } else {
    gameDashBoadPathAddParamsUrl = [NSString stringWithFormat:@"%@", GreeDashboardModeTop];
  }
  
  return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", gameDashboardBaseURLString, gameDashBoadPathAddParamsUrl]];
}

#pragma mark - UIViewController Overrides

- (void)loadView
{
  [super loadView];
  
  [self createViewControllers];
  self.delegate = self;
  self.originalStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
}

- (void)viewDidAppear:(BOOL)animated
{
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];

  [self loadBadgeValue];
  [self enableMenuViewController:NO];  
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  UINavigationBar *navBar = [(UINavigationController*)self.rootViewController navigationBar];
  UIImage *navBar44 = [UIImage greeImageNamed:@"gree_nav_bar_modal_vertical.png"];
  
  if ([UINavigationBar respondsToSelector:@selector(appearance)]) {
    UIImage *navBar32 = [UIImage greeImageNamed:@"gree_nav_bar_modal_horizontal.png"];

    UIEdgeInsets navBar44Insets = UIEdgeInsetsMake(19, 4, 23, 4);
    [navBar setBackgroundImage:[navBar44 resizableImageWithCapInsets:navBar44Insets] forBarMetrics:UIBarMetricsDefault];
    UIEdgeInsets navBar32Insets = UIEdgeInsetsMake(13, 4, 18, 4);
    [navBar setBackgroundImage:[navBar32 resizableImageWithCapInsets:navBar32Insets] forBarMetrics:UIBarMetricsLandscapePhone];
    navBar.backgroundColor = [UIColor blackColor];
  } else {
    _iOS4NavBarBackground = [[UIImageView alloc] initWithImage:[navBar44 stretchableImageWithLeftCapWidth:4 topCapHeight:0]];
    _iOS4NavBarBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _iOS4NavBarBackground.frame = CGRectMake(0,0,navBar.bounds.size.width,navBar.bounds.size.height);
    _iOS4NavBarBackground.backgroundColor = [UIColor blackColor];
    _iOS4NavBarBackground.layer.zPosition = -1;
    [navBar insertSubview:_iOS4NavBarBackground atIndex:0];
  }

  UIImageView *greeLogo = [[[UIImageView alloc] initWithImage:[UIImage greeImageNamed:@"gree_logo.png"]] autorelease];
  navBar.topItem.titleView = greeLogo;

  // Set notification button
  UIImage *nButtonImage = [UIImage greeImageNamed:@"gree_btn_notifications_default.png"];
  
  GreeJSNotificationButton *nButton = [GreeJSNotificationButton buttonWithType:UIButtonTypeCustom];
  nButton.frame = CGRectMake(0, 0, nButtonImage.size.width, nButtonImage.size.height);
  [nButton addTarget:self 
              action:@selector(showNotificationView:)
    forControlEvents:UIControlEventTouchUpInside];
  
  UIImage *buttonImage = [UIImage greeImageNamed:@"gree_btn_close_default.png"];
  UIImage *buttonImageHighlight = [UIImage greeImageNamed:@"gree_btn_close_highlight.png"];
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.frame = CGRectMake(nButtonImage.size.width + 1, 0, buttonImage.size.width, buttonImage.size.height);
  [button setImage:buttonImage 
          forState:UIControlStateNormal];
  [button setImage:buttonImageHighlight 
          forState:UIControlStateHighlighted];
  [button addTarget:self 
             action:@selector(dismissDashboard:) 
   forControlEvents:UIControlEventTouchUpInside];
  
  if ( [UINavigationBar respondsToSelector:@selector(appearance)] ) {
    _notificationButton = [[UIBarButtonItem alloc] initWithCustomView:nButton];
    _closeButton = [[UIBarButtonItem alloc] initWithCustomView:button];
  } else {
    CGRect containerBounds = CGRectMake(0, 0, buttonImage.size.width * 2, buttonImage.size.height);
    UIView* buttonContainer = [[UIView alloc] initWithFrame:containerBounds];
    [buttonContainer addSubview:nButton];
    [buttonContainer addSubview:button];
    _notificationButton = [[UIBarButtonItem alloc] initWithCustomView:nButton];
    _closeButton = [[UIBarButtonItem alloc] initWithCustomView:[buttonContainer autorelease]];
  }
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  self.iOS4NavBarBackground = nil;
  self.notificationButton = nil;
  self.closeButton = nil;
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([self class]), self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  if ([GreePlatform sharedInstance].manuallyRotate) {
    return [GreePlatform sharedInstance].interfaceOrientation == toInterfaceOrientation;
  }
  
  return YES;
}

- (void)presentGreeDashboardWithBaseURL:(NSURL *)URL delegate:(id<GreeDashboardViewControllerDelegate>)delegate animated:(BOOL)animated completion:(void (^)(void))completion {
  UIViewController *topViewController = self.rootViewController.topViewController;
  if ([topViewController isKindOfClass:[GreeJSExternalWebViewController class]]) {
    [self.rootViewController popViewControllerAnimated:YES];
  }
  GreeJSWebViewController *webViewController = (GreeJSWebViewController*)self.rootViewController.topViewController;
  [webViewController.webView loadRequest:[NSURLRequest requestWithURL:URL]];
  
  if (completion) {
    completion();
  }
}

- (void)presentGreeDashboardWithParameters:(NSDictionary *)parameters animated:(BOOL)animated {
  NSURL *URL = [[self class] dashboardURLWithParameters:parameters];
  [self presentGreeDashboardWithBaseURL:URL delegate:self.dashboardDelegate animated:animated completion:nil];  
}

#pragma mark - Internal Methods

+ (NSString*)dashboardPathString:(NSString*)pathString appId:(NSString*)appId userId:(NSString*)userId
{
  NSString* strPath = [NSString stringWithFormat:@"%@", pathString];
  NSString* strParams = [self createGameDashboardUrlParams:appId userId:userId];
  
  if (strParams!=nil ) {
    if ([strPath rangeOfString:@"?"].location == NSNotFound) {
      strPath = [NSString stringWithFormat:@"%@?%@", strPath, strParams];
    } else {
      strPath = [NSString stringWithFormat:@"%@&%@", strPath, strParams];
    }
  }
  return strPath;
}

+ (NSString*)createGameDashboardUrlParams:(NSString*)appId userId:(NSString*)userId
{
  NSString* strParams = nil;
  
  if (appId!=nil && [appId length]!=0) {
    strParams = [NSString stringWithFormat:@"%@=%@", GreeDashboardAppId, appId];
    if (userId!=nil && [userId length]!=0 ) {
      strParams = [strParams stringByAppendingFormat:@"&%@=%@", GreeDashboardUserId, userId];
    }
  } else {
    if (userId!=nil && [userId length]!=0) {
      strParams = [NSString stringWithFormat:@"%@=%@", GreeDashboardUserId, userId];
    }
  }
  return strParams;
}

+ (NSURL*)URLFromMenuViewController:(UIViewController*)viewController {
  UINavigationController *navController = (UINavigationController*)viewController;
  NSAssert([navController isKindOfClass:[UINavigationController class]], @"Expecting an instance of UINavigationController");
  GreeJSWebViewController *menu = (GreeJSWebViewController*)navController.visibleViewController;
  NSAssert([menu isKindOfClass:[GreeJSWebViewController class]] || [menu isKindOfClass:[GreeJSExternalWebViewController class]],
           @"Expecting an instance of GreeJSWebViewController or GreeJSExternalWebViewController");
  return [NSURL URLWithString:[menu.webView stringByEvaluatingJavaScriptFromString:@"location.href"]];
}

+ (NSString*)viewNameFromURL:(NSURL*)url {
  NSURL *snsURL = [NSURL URLWithString:[[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingServerUrlSns]];
  if ([[url host] isEqualToString:[snsURL host]]) {
    return [[[url fragment] greeDictionaryFromQueryString] objectForKey:@"view"];
  } else {
    return [[url URLByDeletingQuery] absoluteString];
  }
}

- (void)createViewControllers
{
  [self createRootViewController];
  [self createMenuViewController];
}

- (void)createRootViewController
{
  if (self.rootViewController) {
    return;
  }
  GreeJSWebViewController *webViewController = [[[GreeJSWebViewController alloc] init] autorelease];
  webViewController.pool = [[[GreeJSWebViewControllerPool alloc] init] autorelease];
  webViewController.pool.preloadURL =
    [NSURL URLWithString:[[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlSns]];

  __block void (^initializer)(GreeJSWebViewController*) = ^(GreeJSWebViewController* webViewController) {
    [webViewController setTitleViewForNavigationItem:webViewController.navigationItem];
    webViewController.view.backgroundColor = [UIColor colorWithRed:(0xE7/255.0f)
                                                             green:(0xE8/255.0f)
                                                              blue:(0xE9/255.0f)
                                                             alpha:1.0f];
    webViewController.webView.opaque = NO;
    webViewController.webView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
  };

  webViewController.preloadInitializeBlock = ^(GreeJSWebViewController *current, GreeJSWebViewController *preload) {
    initializer(preload);
  };
  initializer(webViewController);

  [webViewController.webView loadRequest:[NSURLRequest requestWithURL:_baseURL]];
  
  UINavigationController *rootNavigationController =
    [[[UINavigationController alloc] initWithRootViewController:webViewController] autorelease];
  rootNavigationController.delegate = self;
  
  self.rootViewController = rootNavigationController;
}

- (void)createMenuViewController
{
  if (self.menuViewController) {
    return;
  }

  GreeJSWebViewController *universalMenuViewController = [[[GreeJSWebViewController alloc] init] autorelease];
  // Universal Menu does not create instance pool for reduce memory usage.
  // Because it is not used frequently.

  __block void (^initializer)(GreeJSWebViewController*) = ^(GreeJSWebViewController* webViewController) {
    webViewController.view.backgroundColor = [UIColor colorWithRed:(0x3C/255.0f)
                                                             green:(0x46/255.0f)
                                                              blue:(0x50/255.0f)
                                                             alpha:1.0f];
    webViewController.webView.opaque = NO;
    webViewController.webView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
    webViewController.networkErrorMessageFilename = kGreeJSWebViewUniversalMenuConnectionFailureFileName;
    [webViewController setCanPullToRefresh:NO];

    GreeSettings *settings = [GreePlatform sharedInstance].settings;
    NSString *universalMenuBaseUrlString = [settings stringValueForSetting:GreeSettingUniversalMenuUrl];
    NSString *universalMenuPath = [settings stringValueForSetting:GreeSettingUniversalMenuPath];
    NSURL *universalMenuURL =
      [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", universalMenuBaseUrlString, universalMenuPath]];
    [webViewController.webView loadRequest:[NSURLRequest requestWithURL:universalMenuURL]];
  };

  universalMenuViewController.preloadInitializeBlock = ^(GreeJSWebViewController *current, GreeJSWebViewController *preload) {
    initializer(preload);
  };
  initializer(universalMenuViewController);

  UINavigationController *universalMenuNavigationController =
    [[[UINavigationController alloc] initWithRootViewController:universalMenuViewController] autorelease];
  universalMenuNavigationController.navigationBarHidden = YES;
  universalMenuNavigationController.delegate = self;
  universalMenuNavigationController.navigationBar.barStyle = UIBarStyleBlack;
  universalMenuNavigationController.navigationBar.tintColor = [UIColor colorWithRed:(0x1e/255.0f)
                                                                              green:(0x28/255.0f)
                                                                               blue:(0x32/255.0f)
                                                                              alpha:1.0];

  self.menuViewController = universalMenuNavigationController;  
}

- (void)insertDashboardButtons:(UINavigationItem*)item;
{
  if ([UINavigationBar respondsToSelector:@selector(appearance)]) {
    NSArray *items = item.rightBarButtonItems;
    if (![items containsObject:_closeButton] || ![items containsObject:_notificationButton]) {
      NSMutableArray *rightBarButtonItems = [NSMutableArray arrayWithArray:items];
      if (![rightBarButtonItems count] > 0) {
        [rightBarButtonItems addObject:self.closeButton];
        [rightBarButtonItems addObject:self.notificationButton];
      }
      [item setRightBarButtonItems:rightBarButtonItems];
    }
  } else {
    UIBarButtonItem *barItem = item.rightBarButtonItem;
    if (barItem == nil || barItem != _closeButton) [item setRightBarButtonItem:_closeButton];
    [_closeButton.customView layoutSubviews];
  }
}

- (void)showNotificationView:(id)sender
{
  [self 
    presentGreeNotificationBoardWithType:GreeNotificationBoardLaunchAutoSelect
    parameters:nil 
    delegate:self 
    animated:YES 
    completion:nil];
}

- (void)dismissDashboard:(id)sender
{  
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
  if ([self.dashboardDelegate respondsToSelector:@selector(dashboardCloseButtonPressed:)]) {
    [self.dashboardDelegate dashboardCloseButtonPressed:self];
  }
}

- (void)loadBadgeValue
{
  BOOL forAllApplications = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"jp.gree.greeapp"] ? YES : NO;
  if (forAllApplications) {
    [GreeBadgeValues loadBadgeValuesForAllApplicationsWithBlock:^(GreeBadgeValues* badgeValues, NSError *error) {}];
  } else {
    [GreeBadgeValues loadBadgeValuesForCurrentApplicationWithBlock:^(GreeBadgeValues* badgeValues, NSError *error) {}];
  }
}

#pragma mark - Nav Bar Delegate Methods

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPushItem:(UINavigationItem *)item
{
  if ([super navigationBar:navigationBar shouldPushItem:item]) {
    if (self.rootViewController.navigationBar == navigationBar) {
      [self insertDashboardButtons:item];
      if (_iOS4NavBarBackground) [navigationBar sendSubviewToBack:_iOS4NavBarBackground];
      return YES;
    }
  }
  return NO;
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
  [super navigationController:navigationController willShowViewController:viewController animated:animated];
  if (self.rootViewController == navigationController) {
    [self insertDashboardButtons:viewController.navigationItem];
    if (_iOS4NavBarBackground) [navigationController.navigationBar sendSubviewToBack:_iOS4NavBarBackground];
  }
  if (self.menuViewController == navigationController) {
    if (navigationController.viewControllers.count > 1)
      [navigationController setNavigationBarHidden:NO animated:YES];
    else
      [navigationController setNavigationBarHidden:YES animated:YES];
  }
  
  // Force to call the viewWillAppear methoad of push viewController, because iOS4 is not call viewwillAppear methoad on GreeMenuNavController.
  if ([[[UIDevice currentDevice] systemVersion] floatValue] < 5.0f) {
    [viewController viewWillAppear:animated];
  }  
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
  if (self.rootViewController == navigationController && _iOS4NavBarBackground) {
    [navigationController.navigationBar sendSubviewToBack:_iOS4NavBarBackground];
  }
  // Force to call the viewDidAppear methoad of push viewController, because iOS4 is not call viewDidAppear methoad on GreeMenuNavController.
  if ([[[UIDevice currentDevice] systemVersion] floatValue] < 5.0f) {
    [viewController viewDidAppear:animated];
  }  
}

#pragma mark - GreeMenuNavControllerDelegate Methods
-(void)enableScroll:(BOOL)enable subviewsOf:(UIView*)view
{
  if ([view respondsToSelector:@selector(setScrollsToTop:)]) {
    view.userInteractionEnabled = enable;
  }
  for (UIView* subview in view.subviews) {
    [self enableScroll:enable subviewsOf:subview];
  }
}

- (void)enableMenuViewController:(BOOL)enable
{
  [self enableScroll:enable    subviewsOf:((UINavigationController*)self.menuViewController).topViewController.view];
  [self enableScroll:(!enable) subviewsOf:self.rootViewController.topViewController.view];
}

- (void)menuController:(GreeMenuNavController*)controller didShowViewController:(UIViewController*)leftViewController
{
  NSURL *fromURL = [[self class] URLFromMenuViewController:leftViewController];
  
  GreeAnalyticsEvent *event = [GreeAnalyticsEvent
    eventWithType:@"pg" name:@"universalmenu_top"
    from:[[self class] viewNameFromURL:fromURL]
    parameters:nil];
  [[GreePlatform sharedInstance] addAnalyticsEvent:event];

  [self enableMenuViewController:YES];

  NSDictionary *callbackParameters = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"result"];
  UINavigationController *menuViewController = (UINavigationController *)self.menuViewController;
  GreeJSWebViewController *universalMenuViewController = (GreeJSWebViewController *)menuViewController.topViewController;
  [[universalMenuViewController handler] callback:@"universalmenu_did_show" params:callbackParameters];
}
- (void)menuController:(GreeMenuNavController*)controller didHideViewController:(UIViewController*)leftViewController
{
  [self enableMenuViewController:NO];
  
  NSDictionary *callbackParameters = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"result"];
  UINavigationController *menuViewController = (UINavigationController *)self.menuViewController;
  GreeJSWebViewController *universalMenuViewController = (GreeJSWebViewController *)menuViewController.topViewController;
  [[universalMenuViewController handler] callback:@"universalmenu_did_hide" params:callbackParameters];
}

- (void)menuController:(GreeMenuNavController*)controller willShowViewController:(UIViewController*)leftViewController
{
  NSDictionary *callbackParameters = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"result"];
  UINavigationController *menuViewController = (UINavigationController *)self.menuViewController;
  GreeJSWebViewController *universalMenuViewController = (GreeJSWebViewController *)menuViewController.topViewController;
  [[universalMenuViewController handler] callback:@"universalmenu_will_show" params:callbackParameters];
}

- (void)menuController:(GreeMenuNavController*)controller willHideViewController:(UIViewController*)leftViewController
{
  NSDictionary *callbackParameters = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"result"];
  UINavigationController *menuViewController = (UINavigationController *)self.menuViewController;
  GreeJSWebViewController *universalMenuViewController = (GreeJSWebViewController *)menuViewController.topViewController;
  [[universalMenuViewController handler] callback:@"universalmenu_will_hide" params:callbackParameters];
}

@end
