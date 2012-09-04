//
// Copyright 2011 GREE, Inc.
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


#import "GreeJSCommand.h"
#import "GreeJSCommandEnvironment.h"
#import "GreeJSLaunchServiceCommand.h"
#import "GreeLogger.h"
#import "GreePlatform+Internal.h"
#import "GreePopup.h"
#import "GreePopup+Internal.h"
#import "GreePopupURLHandler.h"
#import "GreePopupView.h"
#import "GreeSettings.h"
#import "NSDictionary+GreeAdditions.h"
#import "NSString+GreeAdditions.h"
#import "UIImage+GreeAdditions.h"
#import "UIViewController+GreeAdditions.h"
#import "NSBundle+GreeAdditions.h"
#import "GreePlatformSettings.h"
#import "GreeNSNotification.h"
#import "GreeNSNotification+Internal.h"
#import "UIView+GreeAdditions.h"
#import "UIWebView+GreeAdditions.h"
#import "GreeGlobalization.h"
#import "UIViewController+GreeAdditions.h"
#import "UIViewController+GreePlatform.h"

#pragma mark - GreePopup notification constants

NSString* const GreePopupWillLaunchNotification = @"GreePopupWillLaunchNotification";
NSString* const GreePopupDidLaunchNotification = @"GreePopupDidLaunchNotification";
NSString* const GreePopupWillDismissNotification = @"GreePopupWillDismissNotification";
NSString* const GreePopupDidDismissNotification = @"GreePopupDidDismissNotification";

NSString* const GreePopupInviteAction = @"service_invite";
NSString* const GreePopupShareAction = @"service_share";
NSString* const GreePopupRequestServiceAction = @"service_request";

NSString* const GreeRequestServicePopupTitle = @"title";
NSString* const GreeRequestServicePopupBody = @"body";
NSString* const GreeRequestServicePopupMobileImage = @"mobile_image";
NSString* const GreeRequestServicePopupImageURL = @"image_url";
NSString* const GreeRequestServicePopupMobileURL = @"mobile_url";
NSString* const GreeRequestServicePopupRedirectURL = @"redirect_url";
NSString* const GreeRequestServicePopupAttributes = @"attrs";
NSString* const GreeRequestServicePopupCallbackURL = @"callbackurl";
NSString* const GreeRequestServicePopupListType = @"list_type";
NSString* const GreeRequestServicePopupToUserId = @"to_user_id";
NSString* const GreeRequestServicePopupExpireTime = @"expire_time";

NSString* const GreeRequestServicePopupListTypeAll = @"all";
NSString* const GreeRequestServicePopupListTypeJoined = @"joined";
NSString* const GreeRequestServicePopupListTypeNotJoined = @"not_joined";
NSString* const GreeRequestServicePopupListTypeSpecified = @"specified";

# pragma mark - GreePopup private interface

@interface GreePopup () <GreePopupViewDelegate, GreeJSCommandEnvironment>
@property (nonatomic, retain) id keyboardShowObserver;
@property (nonatomic, retain) id keyboardHideObserver;
@property (nonatomic, assign, setter = setCanDisplayBackButton:) BOOL canDisplayBackButton;
-(NSString *)endPointString;
@end


# pragma mark - GreePopup implementation
@implementation GreePopup
@synthesize action;
@synthesize parameters = _parameters;
@synthesize results;
@synthesize cancelBlock;
@synthesize completeBlock;
@synthesize willLaunchBlock;
@synthesize didLaunchBlock;
@synthesize willDismissBlock;
@synthesize didDismissBlock;

@synthesize popupView;
@synthesize keyboardShowObserver = _keyboardShowObserver;
@synthesize keyboardHideObserver = _keyboardHideObserver;
@synthesize canDisplayBackButton = _canDisplayBackButton;
 
@synthesize hostViewController = _hostViewController;

#pragma mark - Object Lifecycle

-(void)setup
{
  // the template method for subclasses 
}

-(void)dealloc
{
  self.action = nil;
  self.parameters = nil;
  self.results = nil;
  self.cancelBlock = nil;
  self.completeBlock = nil;
  self.willLaunchBlock = nil;
  self.didLaunchBlock = nil;
  self.willDismissBlock = nil;
  self.didDismissBlock = nil;
  
  [[NSNotificationCenter defaultCenter] removeObserver:_keyboardShowObserver];
  [[NSNotificationCenter defaultCenter] removeObserver:_keyboardHideObserver];
  [_keyboardShowObserver release];
  [_keyboardHideObserver release];
  
  GreePopupView *viewAsGreeView = (GreePopupView*)self.view;
  viewAsGreeView.delegate = nil;  //avoids a crash if the view is currently being held in a block, such as animation
  
  [popupView release];
  [super dealloc];
}

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
  return [super initWithNibName:@"GreePopup" bundle:[NSBundle greePlatformCoreBundle]];
}


#pragma mark - Public Interface

-(id)initWithParameters:(NSDictionary *)someParameters
{
  self = [self initWithNibName:nil bundle:nil];
  if (self) {
    _parameters = [someParameters retain];
    _canDisplayBackButton = NO;
    [self setup];
  }
  return self;
}

+(id)popup
{
  return [self popupWithParameters:nil];
}

+(id)popupWithParameters:(NSDictionary *)parameters
{
  GreePopup *popup = [[[self alloc] initWithParameters:parameters] autorelease];
  return popup;
}

-(void)show
{
  __block GreePopup* myself = self;

  _keyboardShowObserver = [[NSNotificationCenter defaultCenter]
      addObserverForName:UIKeyboardDidShowNotification
      object:nil
      queue:[NSOperationQueue mainQueue]
      usingBlock:^(NSNotification* notification) {
        CGRect keyboardEndFrame = [myself.view
          convertRect:[[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue]
          fromView:myself.view.window];
  
        CGFloat animationDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, animationDuration * 0.5 * NSEC_PER_SEC);
  
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            CGRect firstResponderFrame = [myself.view greeFirstResponderFrame];

            if (CGRectIntersectsRect(firstResponderFrame, keyboardEndFrame)) {
              CGFloat finalYPosition = (keyboardEndFrame.origin.y / 2.0f) - (firstResponderFrame.size.height / 2.0f);
              CGFloat distanceToTravel = MAX(finalYPosition - firstResponderFrame.origin.y, -keyboardEndFrame.size.height);
              [UIView
                animateWithDuration:animationDuration
                animations:^{
                  myself.view.transform = CGAffineTransformTranslate(myself.view.transform, 0.0f, distanceToTravel);
              }];
            }
          });
        }];
       
  [_keyboardShowObserver retain];
        
  _keyboardHideObserver = [[NSNotificationCenter defaultCenter]
    addObserverForName:UIKeyboardWillHideNotification
    object:nil
    queue:[NSOperationQueue mainQueue]
    usingBlock:^(NSNotification* notification) {        
      CGFloat animationDuration = [[[notification userInfo]
        objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
                
      [UIView animateWithDuration:animationDuration
        animations:^{
          myself.view.transform = CGAffineTransformIdentity;
      }];
    }];
      
  [_keyboardHideObserver retain];

  if ([GreePlatform sharedInstance].manuallyRotate) {
    [[UIApplication sharedApplication] setStatusBarOrientation:[GreePlatform sharedInstance].interfaceOrientation];
    [GreePlatform endGeneratingRotation];
  }
  
  self.popupView.delegate = self;
  [self.popupView show];
}

-(void)dismiss
{
  if ([GreePlatform sharedInstance].manuallyRotate) {
    [[UIApplication sharedApplication] setStatusBarOrientation:[GreePlatform sharedInstance].interfaceOrientation];
    [GreePlatform beginGeneratingRotation];
  }
  
  [self.popupView dismiss];
}

-(void)loadRequest:(NSURLRequest *)aRequest
{
  [self.popupView.webView loadRequest:aRequest];
}

-(void)loadData:(NSData *)aData MIMEType:(NSString *)aMIMEType textEncodingName:(NSString *)anEncodingName baseURL:(NSURL *)aBaseURL
{
  [self.popupView.webView loadData:aData MIMEType:aMIMEType textEncodingName:anEncodingName baseURL:aBaseURL];
}

-(void)loadHTMLString:(NSString *)aString baseURL:(NSURL *)aBaseURL
{
  [self.popupView.webView loadHTMLString:aString baseURL:aBaseURL];
}

-(NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)aScript
{
  return [self.popupView.webView stringByEvaluatingJavaScriptFromString:aScript];
}


#pragma mark - UIViewController Overrides
- (void)viewDidLoad {
  self.popupView.containerView.backgroundColor = [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.7f];
  self.popupView.commandEnvironment = self;
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([self class]), self];
}

- (void)presentGreeDashboardWithBaseURL:(NSURL *)URL delegate:(id<GreeDashboardViewControllerDelegate>)delegate animated:(BOOL)animated completion:(void (^)(void))completion {
  [self.hostViewController
    presentGreeDashboardWithBaseURL:URL
    delegate:self.hostViewController
    animated:animated
    completion:completion];
}

- (void)presentGreeNotificationBoardWithType:(GreeNotificationBoardLaunchType)type parameters:(NSDictionary *)parameters delegate:(id<GreeNotificationBoardViewControllerDelegate>)delegate animated:(BOOL)animated completion:(void (^)(void))completion {
  [self.hostViewController
    presentGreeNotificationBoardWithType:type
    parameters:parameters
    delegate:self.hostViewController
    animated:YES
    completion:completion];
}

- (void)greePresentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion {
  [self.hostViewController greePresentViewController:viewController animated:animated completion:completion];
}

- (void)greeDismissViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion {
  [self.hostViewController greeDismissViewControllerAnimated:animated completion:completion];
}

#pragma mark - GreePopupViewDelegate Methods

-(BOOL)popupViewShouldAcceptEmptyBody
{
  return YES;
}

-(void)popupViewDidCancel
{
  // Subclass overrides this method if necessary.
  self.results = nil;

  [[NSNotificationCenter defaultCenter]
   postNotificationName:GreeNSNotificationKeyDidCloseNotification
   object:self];

  if (self.cancelBlock)
    self.cancelBlock(self);
  
  [self dismissGreePopup];
}

-(void)popupViewDidComplete:(NSDictionary*)someResults
{
  // Subclass overrides this method if necessary.
  self.results = someResults;

  [[NSNotificationCenter defaultCenter]
   postNotificationName:GreeNSNotificationKeyDidCloseNotification
   object:self
   userInfo:someResults];

  if (self.completeBlock)
    self.completeBlock(self);
  
  [self dismissGreePopup];
}

-(void)popupViewWillLaunch
{
  NSDictionary* userInfo = [NSDictionary dictionaryWithObject:self forKey:@"sender"];
  [[NSNotificationCenter defaultCenter] postNotificationName:GreePopupWillLaunchNotification object:nil userInfo:userInfo];
  if (self.willLaunchBlock)
    self.willLaunchBlock(self);
}

-(void)popupViewDidLaunch
{	
  NSDictionary* userInfo = [NSDictionary dictionaryWithObject:self forKey:@"sender"];
  [[NSNotificationCenter defaultCenter] postNotificationName:GreePopupDidLaunchNotification object:nil userInfo:userInfo];
  if (self.didLaunchBlock)
    self.didLaunchBlock(self);
}

-(void)popupViewWillDismiss
{
  NSDictionary* userInfo = [NSDictionary dictionaryWithObject:self forKey:@"sender"];
  [[NSNotificationCenter defaultCenter] postNotificationName:GreePopupWillDismissNotification object:nil userInfo:userInfo];
  if (self.willDismissBlock)
    self.willDismissBlock(self);
}

-(void)popupViewDidDismiss
{
  NSDictionary* userInfo = [NSDictionary dictionaryWithObject:self forKey:@"sender"];
  [[NSNotificationCenter defaultCenter] postNotificationName:GreePopupDidDismissNotification object:nil userInfo:userInfo];
  if (self.didDismissBlock)
    self.didDismissBlock(self);
}


#pragma mark - Internal Methods
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  if ([GreePlatform sharedInstance].manuallyRotate) {
    return [GreePlatform sharedInstance].interfaceOrientation == interfaceOrientation;
  }

  return YES;
}

-(NSString *)endPointString
{
  NSString* endPoint = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlPf];
  return endPoint;
}

- (GreePopupView*)popupView
{
  return (GreePopupView*)self.view;
}


#pragma mark - GreeJSCommandEnvironment

- (UIViewController*)viewControllerForCommand:(GreeJSCommand*)command {
  return self;
}

- (UIWebView*)webviewForCommand:(GreeJSCommand*)command {
  return self.popupView.webView;
}

- (GreeJSHandler*)handler {
  return self.popupView.handler;
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

- (BOOL)isJavascriptBridgeEnabled {
  return YES;
}


#pragma mark - GreePopup+Internal Methods

- (void)reloadWithParameters:(NSDictionary*)parameters
{
  
}

- (void)setCanDisplayBackButton:(BOOL)canDisplayBackButton
{
  _canDisplayBackButton = canDisplayBackButton;
  
  if (!_canDisplayBackButton) {
    self.popupView.backButton.hidden = YES;
  }
}

- (void)updateBackButtonStateWithWebView:(UIWebView*)aWebView
{
  if (_canDisplayBackButton && [aWebView canGoBack]) {
    self.popupView.backButton.hidden = NO;
  } else {
    self.popupView.backButton.hidden = YES;
  }
}

- (void)popupViewWebViewReload:(UIWebView *)aWebView
{
  NSString* currentUrl = [aWebView stringByEvaluatingJavaScriptFromString:@"document.URL"];
  NSString* backToUrlString = [currentUrl stringByReplacingOccurrencesOfString:@"about://error/" withString:@""];
  NSString* reloadUrlString = [backToUrlString greeURLDecodedString];
  NSURL* url = [NSURL URLWithString:reloadUrlString];
  if ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"]) {
    if (url) {
      [aWebView loadRequest:[NSURLRequest requestWithURL:url]];
    }
  }
}

@end


#pragma mark - GreeInvitePopup Implementation


@implementation GreeInvitePopup
@synthesize message;
@synthesize callbackURL;
@synthesize toUserIds;


#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.message = nil;
  self.callbackURL = nil;
  self.toUserIds = nil;
  [super dealloc];
}


#pragma mark - GreePopup Overrides

-(void)setup
{
  self.action = GreePopupInviteAction;
}

-(void)popupViewWillLaunch
{
  [super popupViewWillLaunch];
  [self load];
}

-(void)show
{
  [super show];
}

- (GreePopupViewTitleSettingMethod)popupViewHowDoesSetTitle
{
  return GreePopupViewTitleSettingMethodNothing;
}

- (void)popupViewWebViewDidStartLoad:(UIWebView *)aWebView
{
  NSString* aTitleString = GreePlatformString(@"core.popup.invite.title", @"Send Invites");
  [self.popupView setTitleWithString:aTitleString];
}


#pragma mark - NSObject Overrides

- (NSString*)description
{
  return [NSString stringWithFormat:
          @"<%@:%p message:%@ callbackURL:%@ toUserIds:%@>", 
          NSStringFromClass([self class]), self,
          self.message, self.callbackURL, self.toUserIds];
}

-(void)load
{
  NSString *anUrlString = [NSString stringWithFormat:@"%@/?mode=ggp&act=%@", [self endPointString], self.action];  
  NSURL *anURL = [NSURL URLWithString:anUrlString];
  NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:anURL];
  NSString *anApplicationIdString = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
  NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
  if (anApplicationIdString) [parameters setObject:anApplicationIdString forKey:@"app_id"];
  if (self.message) [parameters setObject:self.message forKey:@"body"];
  if (self.callbackURL.absoluteString) [parameters setObject:self.callbackURL.absoluteString forKey:@"callbackurl"];
  if (self.toUserIds) [parameters setObject:self.toUserIds forKey:@"to_user_id"];
  NSString *aMethod = @"POST";
	[aRequest setHTTPMethod:aMethod];
  NSString *aPostBodyString = [parameters greeBuildQueryString];
	[aRequest setHTTPBody:[aPostBodyString dataUsingEncoding:NSUTF8StringEncoding]];
  [self loadRequest:aRequest];
}

-(void)popupViewWebViewReload:(UIWebView*)aWebView
{  
  [self load];
}

@end


#pragma mark - GreeSharePopup Interface


@interface GreeSharePopup ()
@property (retain) NSDictionary* launchServiceParameters;
- (NSString*)appDisplayNameString;
- (void)setupDefaultTextProperty;
- (NSDictionary*)makeParametersWithAdditionalParameters:(NSDictionary*)additionalParameters;
- (void)loadWithParameters:(NSDictionary*)parameters;
@end


#pragma mark - GreeSharePopup Implementation


@implementation GreeSharePopup
@synthesize text;
@synthesize attachingImage;
@synthesize imageUrls;
@synthesize launchServiceParameters;


#pragma mark - Object Lifecycle

-(void)dealloc
{
  self.text = nil;
  self.attachingImage = nil;
  self.imageUrls = nil;
  self.launchServiceParameters = nil;
  [super dealloc];
}


#pragma mark - GreePopup Overrides

-(void)setup
{
  self.action = GreePopupShareAction;
  
  UIImage *anIconImage = [UIImage greeIconImageFromBundle];
  self.attachingImage = [UIImage greeResizeImage:anIconImage maxPixel:57];

  [self setupDefaultTextProperty];
}

-(void)popupViewWillLaunch
{
  [super popupViewWillLaunch];
  
  if (!self.text || [self.text length] == 0) {
    [self setupDefaultTextProperty];
  }

  [self load];
}

-(void)load
{
  NSDictionary* parameters = [self makeParametersWithAdditionalParameters:nil];
  [self loadWithParameters:parameters];
}

-(void)show
{
  [super show];
}

- (void)popupViewWebViewReload:(UIWebView*)aWebView
{  
  [self load];
}

- (GreePopupViewTitleSettingMethod)popupViewHowDoesSetTitle
{
  return GreePopupViewTitleSettingMethodNothing;
}

- (void)popupViewWebViewDidStartLoad:(UIWebView *)aWebView
{
  NSString* aTitleString = GreePlatformString(@"core.popup.share.title", @"Share");
  [self.popupView setTitleWithString:aTitleString];
}


#pragma mark - GreeJSCommandEnvironment

- (BOOL)shouldExecuteCommand:(GreeJSCommand*)command withParameters:(NSDictionary*)parameters {
  if ([command isKindOfClass:[GreeJSLaunchServiceCommand class]]) {
    self.launchServiceParameters = parameters;
  }
  return YES;
}

#pragma mark - Internal Methods

- (NSString*)appDisplayNameString
{
  NSString *thisAppDisplayName;
  thisAppDisplayName = [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"];
  if (!thisAppDisplayName) {
    thisAppDisplayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
  }
  return thisAppDisplayName;
}

- (void)setupDefaultTextProperty
{
  NSString *thisAppDisplayName = [self appDisplayNameString];
  self.text = thisAppDisplayName;
}

- (NSDictionary*)makeParametersWithAdditionalParameters:(NSDictionary*)additionalParameters
{
  NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

  if (self.text) {
    [parameters setValue:self.text forKey:@"message"];
  }

  NSString *anImageString = [self.attachingImage greeBase64EncodedString];
  if (anImageString) {
    [parameters setValue:anImageString forKey:@"image"];
  }
  
  if (self.imageUrls) {
    [parameters setValue:self.imageUrls forKey:@"image_urls"];
  }
  
  if (self.launchServiceParameters) {
    NSString* aUserInputKey = @"user_input";
    NSString* userInputString = [[self.launchServiceParameters objectForKey:@"params"] objectForKey:aUserInputKey];
    [parameters setValue:userInputString forKey:aUserInputKey];
  }

  if (additionalParameters) {
    NSDictionary* queryParameters = [[additionalParameters objectForKey:@"params"] objectForKey:@"query_params"];
    if (queryParameters) {
      [parameters addEntriesFromDictionary:queryParameters];
    }
  }
  
  return parameters;
}

- (void)loadWithParameters:(NSDictionary*)parameters
{
  NSString *anUrlString = [NSString stringWithFormat:@"%@/?mode=ggp&act=%@", [self endPointString], self.action];
  NSURL *anURL = [NSURL URLWithString:anUrlString];
  NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:anURL];
  NSString *aMethod = @"POST";
  NSString *aPostBodyString = [parameters greeBuildQueryString];
  [aRequest setHTTPMethod:aMethod];
  [aRequest setHTTPBody:[aPostBodyString dataUsingEncoding:NSUTF8StringEncoding]];
  [self loadRequest:aRequest];
}


#pragma mark - GreePopup+Internal Methods

- (void)reloadWithParameters:(NSDictionary*)_parameters
{
  NSDictionary* parameters = [self makeParametersWithAdditionalParameters:_parameters];
  [self loadWithParameters:parameters];
}

@end






#pragma mark - GreeRequestServicePopup implementation


@implementation GreeRequestServicePopup

-(void)setup
{
  self.action = GreePopupRequestServiceAction;
}

-(void)popupViewWillLaunch
{
  [super popupViewWillLaunch];
  [self load];
}

-(void)load
{
  NSString *anUrlString = [NSString stringWithFormat:@"%@/?mode=ggp&act=%@", [self endPointString], self.action];
  NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionaryWithDictionary:self.parameters];
  NSString *anApplicationIdString = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
  [mutableParameters setObject:anApplicationIdString forKey:@"app_id"];
  
  NSURL *anURL = [NSURL URLWithString:anUrlString];
  NSMutableURLRequest *aRequest = [NSMutableURLRequest requestWithURL:anURL];
  NSString *aMethod = @"POST";
	NSString *aPostBodyString = [mutableParameters greeBuildQueryString];
	[aRequest setHTTPMethod:aMethod];
	[aRequest setHTTPBody:[aPostBodyString dataUsingEncoding:NSUTF8StringEncoding]];
  [self loadRequest:aRequest];
}

-(void)show
{
  [super show];
}

- (void)popupViewWebViewReload:(UIWebView*)aWebView
{
  [self load];
}

- (GreePopupViewTitleSettingMethod)popupViewHowDoesSetTitle
{
  return GreePopupViewTitleSettingMethodNothing;
}

- (void)popupViewWebViewDidStartLoad:(UIWebView *)aWebView
{
  NSString* aTitleString = GreePlatformString(@"core.popup.request.title", @"Send Requests");
  [self.popupView setTitleWithString:aTitleString];
}


@end
