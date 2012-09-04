//
// Copyright 2010-2011 GREE, inc.
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

#import "GreeDashboardViewControllerDelegate.h"
#import "GreeAuthorization.h"
#import "GreeHTTPClient.h"
#import "GreeKeyChain.h"
#import "NSString+GreeAdditions.h"
#import "GreePlatform.h"
#import "NSHTTPCookieStorage+GreeAdditions.h"
#import "NSData+GreeAdditions.h"
#import "GreePopup.h"
#import "GreePopupView.h"
#import "NSDictionary+GreeAdditions.h"
#import "NSURL+GreeAdditions.h"
#import <UIKit/UIKit.h>
#import "GreeSettings.h"
#import "GreePlatform+Internal.h"
#import "GreeDeviceIdentifier.h"
#import "GreeAuthorizationPopup.h"
#import "GreeSSO.h"
#import "GreeDeviceIdentifier.h"
#import "GreePlatform+Internal.h"
#import "GreeWebSession.h"
#import "GreeNetworkReachability.h"
#import "GreeUser+Internal.h"
#import "GreeLogger.h"
#import "AFNetworking.h"
#import "JSONKit.h"
#import "UIViewController+GreeAdditions.h"
#import "UIViewController+GreePlatform.h"

static NSString *const kCommandStartAuthorization = @"start-authorization";
static NSString *const kCommandGetAcccesstoken = @"get-accesstoken";
static NSString *const kCommandSSORequire = @"sso-require";
static NSString *const kCommandEnter = @"enter";
static NSString *const kCommandLogout = @"logout";
static NSString *const kCommandUpgrade = @"upgrade";
static NSString *const kCommandReAuthorize = @"reauthorize";
static NSString *const kCommandReOpen = @"reopen";
static NSString *const kParamKeyTargetGrade = @"target_grade";
static NSString *const kParamAuthorizationTarget = @"target"; //self/browser/appId
static NSString *const kManageDirectoryName = @"gree.authorization";
static NSString *const kFlagFileName = @"did_install";
static double const kPopupLaunchDelayTime = 0.4;
static double const kSSOServerDismissDelayTime = 1.0;
static double const kAppearCloseButtonDelayTime = 1.0;

#pragma mark - definition 
typedef enum {
	AuthorizationStatusInit,
	AuthorizationStatusEnter,
	AuthorizationStatusRequestTokenBeforeGot,
	AuthorizationStatusRequestTokenGot,
	AuthorizationStatusAuthorizationSuccess,
	AuthorizationStatusAccessTokenGot,
} AuthorizationStatus;

typedef enum {
	AuthorizationTypeDefault,
	AuthorizationTypeUpgrade,
	AuthorizationTypeSSOServer,
	AuthorizationTypeSSOServerWithLogin,
	AuthorizationTypeSSOLegacyServer,  
	AuthorizationTypeSSOLegacyServerWithLogin,  
	AuthorizationTypeLogout,
} AuthorizationType;

typedef void (^GreeAuthorizationUpgradeBlock)(void);
typedef void (^GreeAuthorizationReAuthorizeBlock)(void);

#pragma mark - Category
@interface GreeAuthorization() 
+ (GreeAuthorization*)sharedInstance;
- (BOOL)isSavedAccessToken;
- (void)authorizeAction:(NSMutableDictionary*)params;
- (void)openURLAction:(NSURL*)url;

- (void)loadTopPage:(NSMutableDictionary*)params;
- (void)loadEnterPage:(NSMutableDictionary*)params;
- (void)loadAuthorizePage:(NSMutableDictionary*)params;
- (void)loadConfirmUpgradePage:(NSDictionary*)params;
- (void)loadUpgradePage:(NSMutableDictionary*)params;
- (void)loadConfirmReAuthorizePage;
- (void)loadSSOAcceptPage;
- (void)loadLogoutPage;

- (void)popupLaunch;
- (void)popupDismiss;
- (void)getGreeUUIDWithParams:(NSMutableDictionary*)params;
- (void)getTokenWithParams:(NSMutableDictionary*)params key:(NSString*)key secret:(NSString*)secret;
- (void)handleOAuthErrorWithResponse:(id)response;
- (BOOL)handleReOpenWithCommand:(NSString*)command params:(NSMutableDictionary*)params; 
- (void)getGssidWithCompletionBlock:(void(^)(void))completion;
- (void)getGssidWithCompletionBlock:(void(^)(void))completion forceUpdate:(BOOL)forceUpdate;
- (void)resetStatus;
- (void)resetAccessToken;
- (void)resetCookies;
- (void)addAuthVerifierToHttpClient:(NSMutableDictionary*)params;
- (void)updateAuthorizationStatus:(AuthorizationStatus)status;
- (void)setupAuthorizationType:(AuthorizationType)type;
- (void)removeOfAuthorizationData;

@property (nonatomic, assign) id<GreeAuthorizationDelegate> delegate;
@property (nonatomic, assign) AuthorizationStatus authorizationStatus;
@property (nonatomic, assign) AuthorizationType authorizationType;
@property (nonatomic, retain) GreeHTTPClient* httpClient;
@property (nonatomic, retain) GreeHTTPClient* httpConsumerClient;
@property (nonatomic, retain) NSString* userOAuthKey;
@property (nonatomic, retain) NSString* userOAuthSecret;
@property (nonatomic, retain) GreeAuthorizationPopup* popup;
@property (nonatomic, retain) GreeSSO* greeSSOLegacy;
@property (nonatomic, copy) GreeAuthorizationUpgradeBlock upgradeSuccessBlock;
@property (nonatomic, copy) GreeAuthorizationUpgradeBlock upgradeFailureBlock;
@property (nonatomic, assign) BOOL upgradeComplete;
@property (nonatomic, assign) NSString* configServerUrlOpen;
@property (nonatomic, assign) NSString* configServerUrlOs;
@property (nonatomic, assign) NSString* configServerUrlId;
@property (nonatomic, assign) NSString* configGreeDomain;
@property (nonatomic, assign) NSString* configAppUrlScheme;
@property (nonatomic, assign) NSString* configSelfApplicationId;
@property (nonatomic, assign) NSString* configConsumerSecret;
@property (nonatomic, retain) NSString* deviceJasonWebToken;
@property (nonatomic, retain) NSString* SSOClientApplicationId;
@property (nonatomic, retain) NSString* SSOClientRequestToken;
@property (nonatomic, retain) NSString* SSOClientContext;
@property (nonatomic, retain) NSString* userId;
@property (nonatomic, retain) NSString* greeUUID;
@property (nonatomic, retain) NSString* serviceCode;
@property (nonatomic, retain) GreeNetworkReachability* reachability;
@property (nonatomic) BOOL reachabilityIsSet;
@property (nonatomic) BOOL reachabilityIsWork;
@property (nonatomic) BOOL enableGrade0;
@end

#pragma mark - GreeAuthorization
@implementation GreeAuthorization
@synthesize delegate = _delegate;
@synthesize authorizationStatus = _authorizationStatus;
@synthesize authorizationType = _authorizationType;
@synthesize httpClient = _httpClient;
@synthesize httpConsumerClient = _httpConsumerClient;
@synthesize userOAuthKey = _userOAuthKey;
@synthesize userOAuthSecret = _userOAuthSecret;
@synthesize popup = _popup;
@synthesize greeSSOLegacy = _greeSSOLegacy;
@synthesize upgradeSuccessBlock = _upgradeSuccessBlock;
@synthesize upgradeFailureBlock = _upgradeFailureBlock;
@synthesize upgradeComplete = _upgradeComplete;
@synthesize configServerUrlOpen = _configServerUrlOpen;
@synthesize configServerUrlOs = _configServerUrlOs;
@synthesize configServerUrlId = _configServerUrlId;
@synthesize configGreeDomain = _configGreeDomain;
@synthesize configAppUrlScheme = _configAppUrlScheme;
@synthesize configSelfApplicationId = _configSelfApplicationId;
@synthesize configConsumerSecret = _configConsumerSecret;
@synthesize deviceJasonWebToken = _deviceJasonWebToken;
@synthesize SSOClientApplicationId = _SSOClientApplicationId;
@synthesize SSOClientRequestToken = _SSOClientRequestToken;
@synthesize SSOClientContext = _SSOClientContext;
@synthesize userId = _userId;
@synthesize greeUUID = _greeUUID;
@synthesize serviceCode = _serviceCode;
@synthesize reachability = _reachability;
@synthesize reachabilityIsSet = _reachabilityIsSet;
@synthesize reachabilityIsWork = _reachabilityIsWork;
@synthesize enableGrade0 = _enableGrade0;
@dynamic accessToken;
@dynamic accessTokenSecret;

#pragma mark - Object Lifecycle
- (void)dealloc 
{
  [_userOAuthKey release];
  [_userOAuthSecret release];
  [_httpClient release];
  [_httpConsumerClient release];
  [_popup release];
  [_greeSSOLegacy release];
  [_upgradeSuccessBlock release];
  [_upgradeFailureBlock release];
  [_deviceJasonWebToken release];
  [_SSOClientApplicationId release];
  [_SSOClientRequestToken release];
  [_SSOClientContext release];
  [_userId release];
  [_greeUUID release];
  [_reachability release];
  [_serviceCode release];
  [super dealloc];
}

#pragma mark - Public Interface
- (id)initWithConsumerKey:(NSString*)consumerKey 
    consumerSecret:(NSString*)consumerSecret 
    settings:(GreeSettings*)settings
    delegate:(id<GreeAuthorizationDelegate>)delegate;
{
  self = [super init];
  if(self) {    
    [self resetStatus];
    _delegate = delegate;
    self.configConsumerSecret = consumerSecret;
    self.configServerUrlOpen = [settings stringValueForSetting:GreeSettingServerUrlOpen];
    self.configServerUrlOs = [settings stringValueForSetting:GreeSettingServerUrlOsWithSSL];
    self.configServerUrlId = [settings stringValueForSetting:GreeSettingServerUrlId];
    self.configGreeDomain = [settings stringValueForSetting:GreeSettingServerUrlDomain];
    self.configAppUrlScheme = [settings stringValueForSetting:GreeSettingApplicationUrlScheme];
    self.configSelfApplicationId = [settings stringValueForSetting:GreeSettingApplicationId];
    self.enableGrade0 = [settings boolValueForSetting:GreeSettingEnableGrade0];
    self.greeUUID = [GreeKeyChain readWithKey:GreeKeyChainUUIDIdentifier];
    if (self.greeUUID) {
      self.deviceJasonWebToken = [GreeDeviceIdentifier deviceContextIdWithSecret:consumerSecret greeUUID:self.greeUUID];
    }
    
    NSURL* baseURLOpen = [NSURL URLWithString:[NSString stringWithFormat:@"%@", _configServerUrlOpen]];
    _httpClient = [[GreeHTTPClient alloc] initWithBaseURL:baseURLOpen key:consumerKey secret:consumerSecret];
    
    NSURL* baseURLOs = [NSURL URLWithString:[NSString stringWithFormat:@"%@", _configServerUrlOs]];
    _httpConsumerClient = [[GreeHTTPClient alloc] initWithBaseURL:baseURLOs key:consumerKey secret:consumerSecret];
    
    NSString *OAuthCallbackUrl = [NSString stringWithFormat:@"%@%@://%@", 
      _configAppUrlScheme, 
      _configSelfApplicationId,
      kCommandGetAcccesstoken];
    [self.httpClient setOAuthCallback:OAuthCallbackUrl];
    _reachability = [[GreeNetworkReachability alloc] initWithHost:self.configServerUrlOpen];
    
    __block GreeAuthorization* myself = self;
    [self.reachability addObserverBlock:^(GreeNetworkReachabilityStatus previous, GreeNetworkReachabilityStatus current) {
      myself.reachabilityIsSet = GreeNetworkReachabilityStatusIsConnected(current);
      myself.reachabilityIsWork = YES;
    }];
    BOOL removeTokenWithReInstall = [settings boolValueForSetting:GreeSettingRemoveTokenWithReInstall];
    if (removeTokenWithReInstall) {
      NSString* aFlagFilePath = [NSString stringWithFormat:@"%@/%@", kManageDirectoryName, kFlagFileName];
      NSString* aFileSystemPath = [NSString greeDocumentsPathForRelativePath:aFlagFilePath];
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      NSString *hasToken = [defaults objectForKey:@"hasToken"];
      BOOL sdkv2TokenAvailable = hasToken && ![hasToken isEqualToString:@"0"];
      if (![[NSFileManager defaultManager] fileExistsAtPath:aFileSystemPath] && !sdkv2TokenAvailable) {
        NSString* aDirectoryPath = [aFileSystemPath stringByDeletingLastPathComponent];
        [[NSFileManager defaultManager] createDirectoryAtPath:aDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        [[NSFileManager defaultManager] createFileAtPath:aFileSystemPath contents:nil attributes:nil];
        [self resetAccessToken];
      }    
    }
  }
  return self;
}

+ (GreeAuthorization*)sharedInstance 
{
  return [GreePlatform sharedInstance].authorization;
}

- (void)authorize
{
  self.serviceCode = nil;
  if (![self isSavedAccessToken]) {
    double delayTime = (_reachabilityIsWork)?0:kPopupLaunchDelayTime;    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayTime * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      if (_enableGrade0 && !_reachabilityIsSet) {
        //offline game start
      } else {
        [self authorizeAction:nil];
      }
    });
  }
  else{    
    [self updateAuthorizationStatus:AuthorizationStatusAccessTokenGot];
    if ([_delegate respondsToSelector:@selector(authorizeDidUpdateUserId:withToken:withSecret:)]) {
      [_delegate authorizeDidUpdateUserId:self.userId withToken:self.accessToken withSecret:self.accessTokenSecret];
    }
    [self getGssidWithCompletionBlock:^{
      if ([_delegate respondsToSelector:@selector(authorizeDidFinishWithLogin:)]) {
        [_delegate authorizeDidFinishWithLogin:YES];
      }
    }];
  }
}

- (void)revoke
{  
  if([self isSavedAccessToken]) {
    [self resetStatus];
    [self updateAuthorizationStatus:AuthorizationStatusAccessTokenGot];
    [self setupAuthorizationType:AuthorizationTypeLogout];
    dispatch_async(dispatch_get_main_queue(), ^{
      [self loadLogoutPage];
    });
  }    
}

- (void)reAuthorize
{
  if (_popup) { return;}
  
  [self resetStatus];
  [self resetAccessToken];
  if ([_delegate respondsToSelector:@selector(revokeDidFinish)]) {
    [_delegate revokeDidFinish];
  }
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, kPopupLaunchDelayTime * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    [self loadConfirmReAuthorizePage];
  });
}

- (void)upgradeWithParams:(NSDictionary*)params
    successBlock:(GreeAuthorizationUpgradeBlock)successBlock 
    failureBlock:(GreeAuthorizationUpgradeBlock)failureBlock
{
  if (_popup) { return;}
  
  if (!successBlock || !failureBlock) {
    return;
  }
  
  if (![self isAuthorized] || !self.userId) {
    failureBlock();
    return;
  }

  NSInteger targetGrade = [[params objectForKey:@"target_grade"] intValue];
  if (targetGrade <= 0) {
    failureBlock();
    return;
  }
  
  //wrap the success block so that it actually updates the local user
  GreeAuthorizationUpgradeBlock wrapSuccess = ^{
    [GreeUser upgradeLocalUser:targetGrade];
    successBlock();
  };
    
  [self resetStatus];
  [self updateAuthorizationStatus:AuthorizationStatusAccessTokenGot];
  [self setupAuthorizationType:AuthorizationTypeUpgrade];
  self.upgradeSuccessBlock = wrapSuccess;
  self.upgradeFailureBlock = failureBlock;  
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, kPopupLaunchDelayTime * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    // The following code avoids a problem which displays login view when app has the old session
    [GreeWebSession regenerateWebSessionWithBlock:^(NSError* error) {
      if (error) {
        failureBlock();
      } else {
        [self loadConfirmUpgradePage:params];
      }
    }];
  });
}

- (BOOL)handleOpenURL:(NSURL*)url 
{ 
  [self openURLAction:url];  
  return YES;
}

- (BOOL)handleBeforeAuthorize:(NSString*)serviceString
{
  if (![self isAuthorized]) {
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    [params setObject:serviceString forKey:@"service_code"];
    [self authorizeAction:params];
    self.serviceCode = serviceString;
    return YES;
  }
  return NO;
}

- (BOOL)isAuthorized
{
  return (self.accessToken && self.accessTokenSecret) ? YES : NO;
}

- (NSString*)accessTokenData
{
  if (_authorizationStatus == AuthorizationStatusAccessTokenGot){
    return _userOAuthKey;
  }
  return nil;
}

- (NSString*)accessTokenSecretData
{
  if (_authorizationStatus == AuthorizationStatusAccessTokenGot){
    return _userOAuthSecret;
  }
  return nil;
}

#pragma mark - Internal Method
- (BOOL)isSavedAccessToken;
{
  self.userId = [GreeKeyChain readWithKey:GreeKeyChainUserIdIdentifier];
  self.userOAuthKey = [GreeKeyChain readWithKey:GreeKeyChainAccessTokenIdentifier];
  self.userOAuthSecret = [GreeKeyChain readWithKey:GreeKeyChainAccessTokenSecretIdentifier];
  if (self.userId && self.userOAuthKey && self.userOAuthSecret) {
    return YES;
  }
  return NO;
}

- (void)authorizeAction:(NSMutableDictionary*)params
{
  [self popupLaunch];
  
  if (!self.greeUUID) {
    [self getGreeUUIDWithParams:params];
    return;
  }

  if (_authorizationStatus == AuthorizationStatusInit) {
    [self.popup closeButtonHidden:!_enableGrade0];
    [self resetAccessToken];
    [self loadTopPage:params];
    return;
  }

  if (_authorizationStatus == AuthorizationStatusEnter) {
    [self loadEnterPage:params];
    return;
  }
  
  if (_authorizationStatus == AuthorizationStatusRequestTokenBeforeGot) {
    [self getTokenWithParams:params key:nil secret:nil];
    return;
  }    
  
  if (_authorizationStatus == AuthorizationStatusRequestTokenGot) {
    [self loadAuthorizePage:params];
    return;
  }
  
  if (_authorizationStatus == AuthorizationStatusAuthorizationSuccess) {    
    [self getTokenWithParams:params key:_userOAuthKey secret:_userOAuthSecret];
    return;
  }
  
  if (_authorizationStatus == AuthorizationStatusAccessTokenGot){
    //got accesstoken because being invoked as SSO server but not logged in. 
    if (_authorizationType == AuthorizationTypeSSOLegacyServerWithLogin) {
      [self loadSSOAcceptPage];
      return;
    }
    else if (_authorizationType == AuthorizationTypeSSOServerWithLogin) {
      [self loadAuthorizePage:params];
      return;
    }
    
    //success original , upgrade 
    if (_authorizationType == AuthorizationTypeUpgrade) {
      _upgradeComplete = YES;
    }
    
    [self popupDismiss];
    return;
  }  
}

- (void)popupLaunch
{  
  if (_popup) { return;}
  
  self.popup = [GreeAuthorizationPopup popup];
  [_popup closeButtonHidden:YES];
  [_popup showActivityIndicator];
  
  _popup.didDismissBlock  = ^(GreePopup* aSender) {
    
    if(_authorizationType == AuthorizationTypeUpgrade) {
      if(_upgradeComplete) {
        if ([_delegate respondsToSelector:@selector(authorizeDidFinishWithLogin:)]) {
          [_delegate authorizeDidFinishWithLogin:NO];
        }
        if(_upgradeSuccessBlock){
          _upgradeSuccessBlock();
        }
      }else{
        if(_upgradeFailureBlock){
          _upgradeFailureBlock(); 
        }
      }
      [self resetStatus];
      [self updateAuthorizationStatus:AuthorizationStatusAccessTokenGot];
    }
    else if (_authorizationType == AuthorizationTypeSSOLegacyServer
             || _authorizationType == AuthorizationTypeSSOServer
             || _authorizationType == AuthorizationTypeLogout) {
      if (_authorizationType == AuthorizationTypeSSOLegacyServer
          || _authorizationType == AuthorizationTypeSSOServer) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"GreeAuthorizationDidCloseSSOPopup" object:self];
      }
      [self resetStatus];
      [self updateAuthorizationStatus:AuthorizationStatusAccessTokenGot];
    }
    else if (_authorizationType == AuthorizationTypeDefault 
             || _authorizationType == AuthorizationTypeSSOServerWithLogin
             || _authorizationType == AuthorizationTypeSSOLegacyServerWithLogin) {
      if ([self isAuthorized]) {
        if (_authorizationType == AuthorizationTypeSSOServerWithLogin
            || _authorizationType == AuthorizationTypeSSOLegacyServerWithLogin) {
          [[NSNotificationCenter defaultCenter] postNotificationName:@"GreeAuthorizationDidCloseSSOPopup" object:self];
        }
        if ([_delegate respondsToSelector:@selector(authorizeDidFinishWithLogin:)]) {
          [_delegate authorizeDidFinishWithLogin:YES];
        }
        [self resetStatus];
        [self updateAuthorizationStatus:AuthorizationStatusAccessTokenGot];
      }
      else {
        [self resetStatus];
        [self resetAccessToken];
      }
    }

    self.popup = nil;
  };
  
  //greeapp{self appid} handling
  _popup.selfURLSchemeHandlingBlock = ^(NSURLRequest* aRequest) {
    NSString* handledCommand = [aRequest.URL host];
    NSMutableDictionary* handledParams = [[aRequest.URL query] greeDictionaryFromQueryString];
    GreeLog(@"greeapp{selfId} handled command:%@ params:%@", handledCommand, handledParams);

    //user tap do SSO @SSO client
    if ([handledCommand isEqualToString:kCommandSSORequire]) {
      self.greeSSOLegacy = [[[GreeSSO alloc] initAsClient] autorelease];
      
      NSDictionary* httpParams = [NSDictionary dictionaryWithObjectsAndKeys:
        @"sso_app_candidate", @"action",
        _configSelfApplicationId, @"app_id",
        _deviceJasonWebToken, @"context",
        nil];
      
      NSMutableArray* applist = [NSMutableArray array];
      
      NSURLRequest* previousRequest = _popup.popupView.webView.request;
      if ([previousRequest.URL.scheme isEqualToString:@"http"] 
          || [previousRequest.URL.scheme isEqualToString:@"https"]) {
        _popup.lastRequest = previousRequest;
      }
      [_popup showActivityIndicator];
      [_popup closeButtonHidden:YES];
      [_httpClient getPath:@"/" parameters:httpParams 
        success:^(GreeAFHTTPRequestOperation *operation, id responseObject) {
          id entry = [responseObject objectForKey:@"entry"];
          if ([entry isKindOfClass:[NSArray class]]) {
            for (NSDictionary* appinfo in entry) {
              [applist addObject:[appinfo objectForKey:@"i"]];
            }
          }
          if (![applist count]) {
            [_popup loadErrorPageOnNotWebAccess];
            [_popup closeButtonHidden:!_enableGrade0];
            return;
          }
          [self updateAuthorizationStatus:AuthorizationStatusRequestTokenBeforeGot];      
          NSMutableDictionary* aParams = [NSMutableDictionary dictionary];
          [aParams setDictionary:handledParams];
          NSString* ssoServerAppId = [_greeSSOLegacy openAvailableApplicationWithApps:(NSArray*)applist];
          if (ssoServerAppId) {
            if ([ssoServerAppId isEqualToString:kSelfId]) {             
              [aParams setObject:kSelfId forKey:kParamAuthorizationTarget];
            } else if ([ssoServerAppId isEqualToString:kBrowserId]){
              [aParams setObject:kBrowserId forKey:kParamAuthorizationTarget];
            } else {
              [aParams setObject:ssoServerAppId forKey:kParamAuthorizationTarget];
            }
          } else {
            [aParams setObject:kBrowserId forKey:kParamAuthorizationTarget];
          }
          [self authorizeAction:aParams];
        } 
        failure:^(GreeAFHTTPRequestOperation *operation, NSError *error) {
          [_popup loadErrorPageOnNotWebAccess];
          [_popup closeButtonHidden:!_enableGrade0];
        }
      ];  
      return;
    }
    
    //"enter" from Top page to login as grade1
    if ([handledCommand isEqualToString:kCommandEnter]) {
      [self resetStatus];
      [self resetAccessToken];
      [self updateAuthorizationStatus:AuthorizationStatusEnter];
      [self authorizeAction:handledParams];
      return;
    }
    
    //"start-authorization" from enter page , stating reauthorize
    if ([handledCommand isEqualToString:kCommandStartAuthorization]) {
      [self updateAuthorizationStatus:AuthorizationStatusRequestTokenBeforeGot];
      [self authorizeAction:handledParams];
      return;
    }
    
    //"get-accesstoken" from grade1 registration, finishing reauthorize
    if ([handledCommand isEqualToString:kCommandGetAcccesstoken]){
      [self addAuthVerifierToHttpClient:handledParams];
      [self updateAuthorizationStatus:AuthorizationStatusAuthorizationSuccess];
      [self authorizeAction:nil];
      return;
    }
    
    //user tap upgrade 
    if ([handledCommand isEqualToString:kCommandUpgrade]) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self loadUpgradePage:handledParams];
      });
      return;
    }
    
    //user tap logout
    if ([handledCommand isEqualToString:kCommandLogout]) {
      [self resetStatus];
      [self resetAccessToken];
      [self resetCookies];
      [self removeOfAuthorizationData];
      if ([_delegate respondsToSelector:@selector(revokeDidFinish)]) {
        [_delegate revokeDidFinish];
      }
      [self authorizeAction:nil];
      return;
    }
    
    //"reopen" for sign up or upgrade
    if ([self handleReOpenWithCommand:handledCommand params:handledParams]) {
      return;
    }
  };
  
  _popup.defaultURLSchemeHandlingBlock = ^(NSURLRequest* aRequest){
    NSString* handledScheme = [aRequest.URL scheme];
    NSString* handledCommand = [aRequest.URL host];
    NSMutableDictionary* handledParams = [[aRequest.URL query] greeDictionaryFromQueryString];
    GreeLog(@"default after filter handled scheme:%@ command:%@ params:%@", handledScheme, handledCommand, handledParams);
    
    //back to SSO client after authorization by sso-oauth request
    if ([handledScheme isEqualToString:[NSString stringWithFormat:@"%@%@", self.configAppUrlScheme, self.SSOClientApplicationId]]) {
      //command is get-accesstoken or reopen
      [[UIApplication sharedApplication] openURL:aRequest.URL];
      [NSThread sleepForTimeInterval:kSSOServerDismissDelayTime];
      [self popupDismiss];
      return NO;
    }
    
    //user tap allow or not @SSO server display
    if ([handledScheme isEqualToString:self.configAppUrlScheme]) {
      if ([handledCommand isEqualToString:@"authorize"]){
        BOOL bAccept = ([[aRequest.URL path] isEqualToString:@"/accepted"])?YES:NO;
        NSURL* ssoAcceptUrl = [_greeSSOLegacy ssoAcceptUrlWithFlag:bAccept];
        [[UIApplication sharedApplication] openURL:ssoAcceptUrl];
        [NSThread sleepForTimeInterval:kSSOServerDismissDelayTime];
        [self popupDismiss];
        return NO;
      }      
    }
    
    return YES;
  };
  
  _popup.didFailLoadHandlingBlock = ^{
    if(_authorizationType != AuthorizationTypeLogout) {
      [self.popup closeButtonHidden:!_enableGrade0];
    }
  };

  _popup.didFinishLoadHandlingBlock = ^(NSURLRequest* aRequest){
    NSString* resultString = [_popup.popupView.webView  stringByEvaluatingJavaScriptFromString:@"shouldPopupCloseButtonHidden()"];
    if ([resultString isEqualToString:@"1"]) {
      [self.popup closeButtonHidden:YES];
    }
    else if (_authorizationType == AuthorizationTypeDefault 
        || _authorizationType == AuthorizationTypeSSOServerWithLogin
        || _authorizationType == AuthorizationTypeSSOLegacyServerWithLogin) {
      [self.popup closeButtonHidden:!_enableGrade0];
    }
  };
  
  [[UIViewController greeLastPresentedViewController] showGreePopup:_popup];
}

- (void)popupDismiss
{
  if (_authorizationType == AuthorizationTypeSSOServer ||
      _authorizationType == AuthorizationTypeSSOLegacyServer) {
    [_popup dismiss];
  } else {
    if ([_delegate respondsToSelector:@selector(authorizeDidUpdateUserId:withToken:withSecret:)]) {
      [_delegate authorizeDidUpdateUserId:self.userId withToken:self.accessToken withSecret:self.accessTokenSecret];
    }
    [self getGssidWithCompletionBlock:^{
      [_popup dismiss];
    } forceUpdate:YES];
  }
}

- (void)loadTopPage:(NSMutableDictionary*)params
{
  NSString* urlString = [NSString stringWithFormat:@"%@/?action=top&context=%@%@", 
    _configServerUrlId,
    _deviceJasonWebToken,
    ([params greeBuildQueryString])?[NSString stringWithFormat:@"&%@",[params greeBuildQueryString]]:@""];
  NSURLRequest* aRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
  [_popup loadRequest:aRequest];
}

- (void)loadEnterPage:(NSMutableDictionary*)params
{  
  NSString* urlString = [NSString stringWithFormat:@"%@/?action=enter&context=%@%@", 
    _configServerUrlId,
    _deviceJasonWebToken,
    ([params greeBuildQueryString])?[NSString stringWithFormat:@"&%@",[params greeBuildQueryString]]:@""];
  NSURLRequest* aRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
  [_popup loadRequest:aRequest];
}

- (void)loadAuthorizePage:(NSMutableDictionary*)params
{
  NSString* requestToken;
  NSString* context;
  BOOL bTargetSelf = NO;
  if (self.accessToken && self.SSOClientRequestToken) {
    bTargetSelf = YES;
    requestToken = self.SSOClientRequestToken;
    context = self.SSOClientContext;
  } else {
    requestToken = _userOAuthKey;
    context = _deviceJasonWebToken;
  }
  
	NSString* urlString = [NSString stringWithFormat:@"%@/oauth/authorize?oauth_token=%@&context=%@%@%@", 
    _configServerUrlOpen,
    requestToken,
    context,
    (_authorizationType == AuthorizationTypeSSOLegacyServerWithLogin 
    || _authorizationType == AuthorizationTypeSSOServerWithLogin)?@"&ssologin=1":@"",
    ([params greeBuildQueryString])?[NSString stringWithFormat:@"&%@",[params greeBuildQueryString]]:@""];
  NSURLRequest* aRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
  
  NSString* target = [params objectForKey:kParamAuthorizationTarget];
  if ([target isEqualToString:kSelfId] || bTargetSelf) {
    //Here should be sso server or grade1. open internal webview. 
    [_popup loadRequest:aRequest];
  }
  else if ([target isEqualToString:kBrowserId]){
    //Here should be sso client. open browser.
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    if (self.serviceCode) {
      [params setObject:self.serviceCode forKey:@"service_code"];
    }
    [self loadTopPage:params]; //back to top because of indicator showing
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, kAppearCloseButtonDelayTime * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      [self.popup closeButtonHidden:!_enableGrade0];
    });
  }
  else {
    //Here should be sso client. open sso server app
    NSURL* ssoRequireUrl = [_greeSSOLegacy
                            ssoRequireUrlWithServerApplicationId:target 
                            requestToken:_userOAuthKey 
                            context:_deviceJasonWebToken
                            parameters:params];
    [[UIApplication sharedApplication] openURL:ssoRequireUrl];
    if (self.serviceCode) {
      [params setObject:self.serviceCode forKey:@"service_code"];
    }
    [self loadTopPage:params]; //back to top because of indicator showing
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, kAppearCloseButtonDelayTime * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      [self.popup closeButtonHidden:!_enableGrade0];
    });
  }  
}

- (void)loadLogoutPage
{  
  [self popupLaunch];
	NSString* urlString = [NSString stringWithFormat:@"%@/?action=logout", _configServerUrlId];	
  NSURLRequest* aRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
  [_popup loadRequest:aRequest];
  [_popup closeButtonHidden:NO];
}

- (void)loadConfirmUpgradePage:(NSDictionary*)params
{
  [self popupLaunch];
	NSString* urlString = [NSString stringWithFormat:@"%@/?action=confirm_upgrade%@", 
    _configServerUrlId,
    ([params greeBuildQueryString])?[NSString stringWithFormat:@"&%@",[params greeBuildQueryString]]:@""];
  NSURLRequest* aRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
  [_popup loadRequest:aRequest];
  [_popup closeButtonHidden:NO];
}

- (void)loadUpgradePage:(NSMutableDictionary*)params
{
	NSString* urlString = [NSString stringWithFormat:@"%@/?action=upgrade&user_id=%@&app_id=%@&context=%@%@", 
    _configServerUrlId,	
    _userId,
    _configSelfApplicationId,
    _deviceJasonWebToken,
    ([params greeBuildQueryString])?[NSString stringWithFormat:@"&%@",[params greeBuildQueryString]]:@""];
  NSURLRequest* aRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
  
  NSString* target = [params objectForKey:kParamAuthorizationTarget];
  if ([target isEqualToString:kSelfId]) {
    [_popup loadRequest:aRequest];
  }
  else if ([target isEqualToString:kBrowserId]){
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
  }
  else {
    //nop for now
  }  
}

- (void)loadConfirmReAuthorizePage
{
  [self popupLaunch];
	NSString* urlString = [NSString stringWithFormat:@"%@/?action=confirm_reauthorize", _configServerUrlId];
  NSURLRequest* aRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
  [_popup loadRequest:aRequest];
  [_popup closeButtonHidden:YES];
}

- (void)loadSSOAcceptPage
{
  [self popupLaunch];
  NSURLRequest* aRequest = [NSURLRequest requestWithURL:[_greeSSOLegacy acceptPageUrl]];
  [_popup loadRequest:aRequest];
}

- (void)getGreeUUIDWithParams:(NSMutableDictionary *)params
{
  _popup.lastRequest = _popup.popupView.webView.request;
  [_popup showActivityIndicator];
  [_popup closeButtonHidden:YES];
  [_httpConsumerClient getPath:@"/api/rest/generateuuid" parameters:nil 
     success:^(GreeAFHTTPRequestOperation *operation, id responseObject) {
       self.greeUUID = (NSString*)[responseObject objectForKey:@"entry"];
       self.deviceJasonWebToken = [GreeDeviceIdentifier deviceContextIdWithSecret:_configConsumerSecret greeUUID:_greeUUID];
       [GreeKeyChain saveWithKey:GreeKeyChainUUIDIdentifier value:_greeUUID];
       [self authorizeAction:params];
     } 
     failure:^(GreeAFHTTPRequestOperation *operation, NSError *error) {
       [_popup loadErrorPageOnNotWebAccess];
       [_popup closeButtonHidden:!_enableGrade0];
     }
   ];  
  return;
}

- (void)getTokenWithParams:(NSMutableDictionary*)params key:(NSString*)key secret:(NSString*)secret
{ 
  NSString* path;
  if (!key) {
    path = @"/oauth/request_token";
    [_httpClient setUserToken:nil secret:nil];
    [_httpClient setOAuthVerifier:nil];
  } else {
    path = @"/oauth/access_token";
    [_httpClient setUserToken:key secret:secret];
  }
  
  NSURLRequest* previousRequest = _popup.popupView.webView.request;
  if ([previousRequest.URL.scheme isEqualToString:@"http"] 
      || [previousRequest.URL.scheme isEqualToString:@"https"]) {
    _popup.lastRequest = previousRequest;
  }
  [_popup showActivityIndicator];
  [_popup closeButtonHidden:YES];
  [_httpClient rawRequestWithMethod:@"GET" path:path parameters:nil 
    success:^(GreeAFHTTPRequestOperation *operation, id responseObject) {
      
      NSString* responseBody = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];    
      NSArray *pairs = [responseBody componentsSeparatedByString:@"&"];  
      
      self.userOAuthKey = nil;
      self.userOAuthSecret = nil;
      for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        if ([[elements objectAtIndex:0] isEqualToString:@"oauth_token"]) {
          self.userOAuthKey = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        } else if ([[elements objectAtIndex:0] isEqualToString:@"oauth_token_secret"]) {
          self.userOAuthSecret = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        } else if ([[elements objectAtIndex:0] isEqualToString:@"user_id"]) {
          self.userId = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
      }    
      [responseBody release];    
      if (_userOAuthKey == nil || _userOAuthSecret == nil) {
        [_popup loadErrorPageOnNotWebAccess];
        [_popup closeButtonHidden:!_enableGrade0];
        return;
      }
      
      if(!key) {
        //success to getting request token
        self.authorizationStatus = AuthorizationStatusRequestTokenGot;
      }
      else{
        //success to getting access token
        self.authorizationStatus = AuthorizationStatusAccessTokenGot;
        [GreeKeyChain saveWithKey:GreeKeyChainUserIdIdentifier value:_userId];
        [GreeKeyChain saveWithKey:GreeKeyChainAccessTokenIdentifier value:_userOAuthKey];
        [GreeKeyChain saveWithKey:GreeKeyChainAccessTokenSecretIdentifier value:_userOAuthSecret];
      }
      [self authorizeAction:params];
    } 
    failure:^(GreeAFHTTPRequestOperation *operation, NSError *error) {
      [self handleOAuthErrorWithResponse:[[operation responseString] greeMutableObjectFromJSONString]];
      [_popup closeButtonHidden:!_enableGrade0];
    }
  ];  
}

- (void)handleOAuthErrorWithResponse:(id)response
{
  NSString* anErrorString = nil;
  if ([response isKindOfClass:[NSDictionary class]]) {
    NSDictionary* dict = (NSDictionary*)response;
    GreeLog(@"error:%@", dict);
    anErrorString = [dict objectForKey:@"message"];
  }
  if (anErrorString) {
    [_popup loadErrorPageOnOAuthError:anErrorString];
  } else {
    [_popup loadErrorPageOnNotWebAccess];
  }
}

- (void)openURLAction:(NSURL*)url
{
  NSString* handledScheme = [url scheme];
  NSString* handledCommand = [url host];
  NSMutableDictionary* handledParams = [[url query] greeDictionaryFromQueryString];
  GreeLog(@"openURLAction handled scheme:%@ command:%@ params:%@", handledScheme, handledCommand, handledParams);
  
  //"reopen" from browser for sign up or upgrade
  if ([self handleReOpenWithCommand:handledCommand params:handledParams]) {
    return;
  }
  
  //"get-accesstoken" From browser or SSO server app
  if ([handledCommand isEqualToString:kCommandGetAcccesstoken]) {
    if ([handledParams objectForKey:@"denied"] || _popup == nil) {
      // not allowed SSO
      [self resetStatus];
      [self authorizeAction:nil];
    } else {
      // allowed SSO
      [self addAuthVerifierToHttpClient:handledParams];
      [self updateAuthorizationStatus:AuthorizationStatusAuthorizationSuccess];
      [self authorizeAction:handledParams];
    }
    return;
  }
  
  //boot as SSOServer
  if ([handledCommand isEqualToString:@"authorize"] && [[url path] isEqualToString:@"/request"]) {
    NSString* requestTokenOfSSOClient = [handledParams objectForKey:@"oauth_token"];
    if (requestTokenOfSSOClient) {
      //SSO by oauth
      NSMutableDictionary* aParams = [NSMutableDictionary dictionaryWithDictionary:handledParams];
      [aParams setObject:kSelfId forKey:kParamAuthorizationTarget];
      if (self.accessToken && self.accessTokenSecret) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self setupAuthorizationType:AuthorizationTypeSSOServer];
          [self updateAuthorizationStatus:AuthorizationStatusAccessTokenGot];
          self.SSOClientApplicationId = [handledParams objectForKey:@"app_id"];
          self.SSOClientContext = [handledParams objectForKey:@"context"];
          self.SSOClientRequestToken = requestTokenOfSSOClient;
          [self popupLaunch];
          [self.popup closeButtonHidden:YES];
          [self loadAuthorizePage:aParams];
        });
      } else {
        //This is the case which selected SSO server actually has not logged in yet.
        dispatch_async(dispatch_get_main_queue(), ^{
          [self resetStatus];
          [self resetAccessToken];
          [self setupAuthorizationType:AuthorizationTypeSSOServerWithLogin];
          [self updateAuthorizationStatus:AuthorizationStatusRequestTokenBeforeGot];
          self.SSOClientApplicationId = [handledParams objectForKey:@"app_id"];
          self.SSOClientContext = [handledParams objectForKey:@"context"];
          self.SSOClientRequestToken = requestTokenOfSSOClient;
          [self authorizeAction:aParams];
        });
      }
      [aParams removeObjectForKey:@"context"];  // avoid multiple keys
    }
    else {
      //SSO by session
      self.greeSSOLegacy = [[[GreeSSO alloc] 
        initAsServerWithSeedKey:[handledParams objectForKey:@"key"] 
        clientApplicationId:[handledParams objectForKey:@"app_id"]] autorelease];      
      if (self.accessToken && self.accessTokenSecret) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self setupAuthorizationType:AuthorizationTypeSSOLegacyServer];
          [self loadSSOAcceptPage];
        });        
      }
      else{
        //This is the case which selected SSO server actually has not logged in yet.
        dispatch_async(dispatch_get_main_queue(), ^{
          [self resetStatus];
          [self resetAccessToken];
          [self setupAuthorizationType:AuthorizationTypeSSOLegacyServerWithLogin];
          [self updateAuthorizationStatus:AuthorizationStatusRequestTokenBeforeGot];
          NSMutableDictionary* aParams = [NSMutableDictionary dictionary];
          [aParams setObject:kSelfId forKey:kParamAuthorizationTarget];                
          [self authorizeAction:aParams];
        });        
      }
    }
    return;
  }
  
  //reboot as SSOClient
  if ([handledCommand isEqualToString:@"sso"]){        
    NSString *key = [handledParams objectForKey:@"key"];    
    if ([key length]) {
      dispatch_async(dispatch_get_main_queue(), ^{      
        [self resetStatus];
        [self resetAccessToken];
        if (_popup == nil) {
          [self authorizeAction:nil];
        } else {
          [_greeSSOLegacy setDecryptGssIdWithEncryptedGssId:key];
          [self updateAuthorizationStatus:AuthorizationStatusRequestTokenBeforeGot];
          NSMutableDictionary* aParams = [NSMutableDictionary dictionary];
          [aParams setObject:kSelfId forKey:kParamAuthorizationTarget];
          [self authorizeAction:aParams];
        }
      });      
    }
    return;
  }
}

- (BOOL)handleReOpenWithCommand:(NSString*)command params:(NSMutableDictionary *)params
{
  if ([command isEqualToString:kCommandReOpen]){
    if (!self.accessToken || !self.accessTokenSecret) {
      //finished sign up
      [self updateAuthorizationStatus:AuthorizationStatusRequestTokenBeforeGot];
      [self authorizeAction:params];
    } else {
      //finished upgrade
      if ([[params objectForKey:@"result"] isEqualToString:@"succeeded"]) {
        if (_authorizationType == AuthorizationTypeUpgrade) {
          _upgradeComplete = YES;
        }
      }      
      [self popupDismiss];
    }    
    return YES;
  }
  return NO;
}

- (void)getGssidWithCompletionBlock:(void(^)(void))completion
{
  [self getGssidWithCompletionBlock:completion forceUpdate:NO];
}

- (void)getGssidWithCompletionBlock:(void(^)(void))completion forceUpdate:(BOOL)forceUpdate
{
  if (forceUpdate || ![GreeWebSession hasWebSession]) {
    [GreeWebSession regenerateWebSessionWithBlock:^(NSError* error) {
      if (completion)
        completion();
    }];
  } else {
    if (completion)
      completion();
  }
}

- (void)resetStatus
{
  _authorizationStatus = AuthorizationStatusInit;
  _authorizationType = AuthorizationTypeDefault;
  _upgradeComplete = NO;
  self.SSOClientApplicationId = nil;
  self.SSOClientRequestToken = nil;
  self.SSOClientContext = nil;
}

- (void)resetAccessToken
{
  self.userOAuthKey = nil;
  self.userOAuthSecret = nil;
  self.userId = nil;
  [_httpClient setUserToken:nil secret:nil];
  [_httpClient setOAuthVerifier:nil];
  [NSHTTPCookieStorage greeDeleteCookieWithName:@"gssid" domain:_configGreeDomain];
  [NSHTTPCookieStorage greeDeleteCookieWithName:@"gssid_smsandbox" domain:_configGreeDomain];
  [GreeKeyChain removeWithKey:GreeKeyChainUserIdIdentifier];
  [GreeKeyChain removeWithKey:GreeKeyChainAccessTokenIdentifier];
  [GreeKeyChain removeWithKey:GreeKeyChainAccessTokenSecretIdentifier];  
}

- (void)resetCookies
{
  NSHTTPCookieStorage* storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  for (NSHTTPCookie* cookie in storage.cookies) {
    [storage deleteCookie:cookie];
  }
  [[GreePlatform sharedInstance] performSelector:@selector(setDefaultCookies)];
}

- (void)addAuthVerifierToHttpClient:(NSMutableDictionary*)params
{
  NSString* verifier = [params objectForKey:@"oauth_verifier"];
  if (verifier) {
    [_httpClient setOAuthVerifier:verifier];
  }
}

- (void)updateAuthorizationStatus:(AuthorizationStatus)status
{
  _authorizationStatus = status;
}

- (void)setupAuthorizationType:(AuthorizationType)type
{
  _authorizationType = type;
}

- (void)removeOfAuthorizationData
{
  [GreeDeviceIdentifier removeOfAccessToken];
  [GreeDeviceIdentifier removeOfApplicationId];
  [GreeDeviceIdentifier removeOfUserId];
}

@end
