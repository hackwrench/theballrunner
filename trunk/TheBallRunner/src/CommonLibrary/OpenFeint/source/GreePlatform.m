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

#import <UIKit/UIApplication.h>
#import <QuartzCore/QuartzCore.h>

#import "GreePlatform.h"
#import "NSHTTPCookieStorage+GreeAdditions.h"
#import "GreeSettings.h"
#import "GreeHTTPClient.h"
#import "GreeNetworkReachability.h"
#import "GreeAnalyticsEvent.h"
#import "GreeAnalyticsQueue.h"
#import "GreeNotificationQueue.h"
#import "GreeNotification+Internal.h"
#import "GreeWidget+Internal.h"
#import "NSString+GreeAdditions.h"
#import "GreeWriteCache.h"
#import "GreeUser.h"
#import "GreeUser+Internal.h"
#import "GreeLogger.h"
#import <GameKit/GameKit.h>
#import "GreeNSNotification.h"
#import "GreeNSNotification+Internal.h"
#import "NSBundle+GreeAdditions.h"
#import "GreeDeviceIdentifier.h"
#import "NSData+GreeAdditions.h"
#import "NSString+GreeAdditions.h"
#import "GreeUtility.h"
#import "GreeBadgeValues+Internal.h"
#import "GreeNotificationBoard+Internal.h"
#import "GreeNotificationBoardLauncher.h"
#import "GreeNotificationBoardViewController.h"
#import "GreeWidget+Internal.h"
#import "NSObject+GreeAdditions.h"
#import "GreeLocalNotification+Internal.h"
#import "NSURL+GreeAdditions.h"
#import "UIViewController+GreeAdditions.h"
#import "GreeConsumerProtect.h"
#import "JSONKit.h"
#import "GreeAuthorization.h"

#import "GreeJSCloseCommand.h"
#import "GreeJSCommandFactory.h"
#import "GreeJSDeleteCookieCommand.h"
#import "GreeJSGetConfigCommand.h"
#import "GreeJSGetConfigListCommand.h"
#import "GreeJSInviteExternalUserCommand.h"
#import "GreeJSFlushAnalyticsDataCommand.h"
#import "GreeJSLaunchServiceCommand.h"
#import "GreeJSModalNavigationController.h"
#import "GreeJSNotifyServiceResultCommand.h"
#import "GreeJSPopupCloseSharePopupCommand.h"
#import "GreeJSPopupNeedReAuthorizeCommand.h"
#import "GreeJSPopupNeedUpgradeCommand.h"
#import "GreeJSPopupLogoutCommand.h"
#import "GreeJSRecordAnalyticsDataCommand.h"
#import "GreeJSSeeMoreCommand.h"
#import "GreeJSSetConfigCommand.h"
#import "GreeJSShowDashboardCommand.h"
#import "GreeJSShowDashboardFromNotificationBoardCommand.h"
#import "GreeJSShowWebviewDialogCommand.h"
#import "GreeJSShowRequestDialogCommand.h"
#import "GreeJSShowShareDialogCommand.h"
#import "GreeJSShowInviteDialogCommand.h"
#import "GreeJSModalNavigationController.h"
#import "GreeJSRegisterLocalNotificationTimer.h"
#import "GreeJSCancelLocalNotificationTimer.h"
#import "GreeJSGetLocalNotificationEnabled.h"
#import "GreeJSSetLocalNotificationEnabled.h"
#import "GreeJSGetAppListCommand.h"
#import "GreeJSGetViewInfoCommand.h"
#import "GreeCampaignCode.h"
#import "UIViewController+GreeAdditions.h"
#import "GreeRotator.h"
#import "GreeLocalNotification+Internal.h"

#define kActivityIndicatorFileName @"GreePopupActivityIndicator.html"

static GreePlatform* sSharedSDKInstance = nil;
static NSString* consumerScramble = nil;
static const int kGreePlatformRemoteNotificationTypeSNS = 1;

@interface GreePlatform () <GreeAuthorizationDelegate>
@property (nonatomic, retain) GreeLogger* logger;
@property (nonatomic, retain) GreeSettings* settings;
@property (nonatomic, retain) GreeWriteCache* writeCache;
@property (nonatomic, retain) GreeNetworkReachability* reachability;
@property (nonatomic, assign, readonly) id reachabilityObserver;
@property (nonatomic, retain) GreeAnalyticsQueue *analyticsQueue;
@property (nonatomic, retain) id rawNotificationQueue;
@property (nonatomic, retain) GreeLocalNotification* localNotification;
@property (nonatomic, assign) id<GreePlatformDelegate> delegate;
@property (nonatomic, retain) GreeHTTPClient* httpClient;
@property (nonatomic, retain) GreeHTTPClient* httpsClient;
@property (nonatomic, retain) GreeUser* localUser;
@property (nonatomic, copy) NSString* localUserId;
@property (nonatomic, retain) id moderationList;
@property (nonatomic, retain) GreeAuthorization* authorization;
@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;
@property (nonatomic, retain) GreeBadgeValues *badgeValues;
@property (nonatomic, assign) BOOL didGameCenterInitialization;
@property (nonatomic, assign) UIWindow* previousWindow;
@property (nonatomic, assign) UIViewController* previousRootController;
@property (nonatomic, assign) UIInterfaceOrientation previousOrientation;
@property (nonatomic, retain, readonly) NSString* activityIndicatorContentsString;
@property  NSUInteger deviceNotificationCount;
@property (nonatomic, retain) GreeRotator *rotator;
@property (nonatomic, assign) BOOL finished;  //tells performSelector targets they are finished
@property (nonatomic, assign) BOOL manuallyRotate;

- (id)initWithApplicationId:(NSString*)applicationId
  consumerKey:(NSString*)consumerKey
  consumerSecret:(NSString*)consumerSecret
  settings:(NSDictionary*)settings
  delegate:(id<GreePlatformDelegate>)delegate;
- (void)setDefaultCookies;
- (void)updateLocalUser:(GreeUser*)newUser;
- (void)updateLocalUser:(GreeUser*)newUser withNotification:(BOOL)notification;
- (void)retryToUpdateLocalUser;
+ (void)showConnectionServer;
- (NSDictionary*)bootstrapSettingsDictionary;
- (void)writeBootstrapSettingsDictionary:(NSDictionary*)bootstrapSettings;
- (void)updateBootstrapSettingsWithAttemptNumber:(NSInteger)attemptNumber statusBlock:(BOOL(^)(BOOL didSucceed))statusBlock;
@end

@implementation GreePlatform

@synthesize logger = _logger;
@synthesize settings = _settings;
@synthesize writeCache = _writeCache;
@synthesize httpClient = _httpClient;
@synthesize httpsClient = _httpsClient;
@synthesize reachability = _reachability;
@synthesize reachabilityObserver = _reachabilityObserver;
@synthesize analyticsQueue = _analyticsQueue;
@synthesize rawNotificationQueue = _rawNotificationQueue;
@synthesize localNotification = _localNotification;
@synthesize delegate = _delegate;
@synthesize localUser = _localUser;
@synthesize localUserId = _localUserId;
@synthesize moderationList = _moderationList;
@synthesize authorization = _authorization;
@synthesize interfaceOrientation = _interfaceOrientation;
@synthesize badgeValues = _badgeValues;
@synthesize didGameCenterInitialization = _didGameCenterInitialization;
@synthesize previousWindow = _previousWindow;
@synthesize previousRootController = _previousRootController;
@synthesize previousOrientation = _previousOrientation;
@synthesize activityIndicatorContentsString = _activityIndicatorContentsString;
@synthesize deviceNotificationCount = _deviceNotificationCount;
@synthesize finished = _finished;
@synthesize rotator = _rotator;
@synthesize manuallyRotate = _manuallyRotate;

#pragma mark - Object Lifecycle

// Designated initializer
- (id)initWithApplicationId:(NSString*)applicationId
  consumerKey:(NSString*)consumerKey
  consumerSecret:(NSString*)consumerSecret
  settings:(NSDictionary*)settings
  delegate:(id<GreePlatformDelegate>)delegate
{
  if (consumerScramble) {
    consumerKey = [GreeConsumerProtect decryptedHexString:consumerKey keyString:consumerScramble];
    consumerSecret = [GreeConsumerProtect decryptedHexString:consumerSecret keyString:consumerScramble];
  }  
  NSAssert(applicationId != nil && consumerKey != nil && consumerSecret != nil, @"Missing required parameters!");
  self = [super init];
  if (self !=  nil) {
    _settings = [[GreeSettings alloc] init];
    [_settings applySettingDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
      applicationId, GreeSettingApplicationId,
      consumerKey, GreeSettingConsumerKey,
      consumerSecret, GreeSettingConsumerSecret,
      [NSNumber numberWithBool:YES], GreeSettingUpdateBadgeValuesAfterRemoteNotification,
      nil]];
    [_settings applySettingDictionary:[self bootstrapSettingsDictionary]];
    [_settings applySettingDictionary:settings];
    [_settings loadInternalSettingsFile];
    
    [_settings finalizeSettings];
    
    if ([_settings boolValueForSetting:GreeSettingEnableLogging]) {
      BOOL shouldIncludeFileLineInfo = YES;
      NSInteger level = GreeLogLevelWarn;
      if ([_settings settingHasValue:GreeSettingLogLevel]) {
        level = [_settings integerValueForSetting:GreeSettingLogLevel];
      } else if ([[_settings stringValueForSetting:GreeSettingDevelopmentMode] isEqualToString:GreeDevelopmentModeProduction]) {
        level = GreeLogLevelPublic;
        shouldIncludeFileLineInfo = NO;
      }
      
      BOOL writeLogToFile = NO;
      if([_settings boolValueForSetting:GreeSettingWriteLogToFile]) {
        writeLogToFile = YES;
      }
      
      _logger = [[GreeLogger alloc] init];
      _logger.level = level;
      _logger.includeFileLineInfo = shouldIncludeFileLineInfo;
      _logger.logToFile = writeLogToFile;
    }
    
    _delegate = delegate;
    _httpClient = [[GreeHTTPClient alloc] 
      initWithBaseURL:[NSURL URLWithString:[_settings stringValueForSetting:GreeSettingServerUrlOs]] 
      key:[_settings stringValueForSetting:GreeSettingConsumerKey]
      secret:[_settings stringValueForSetting:GreeSettingConsumerSecret]];
    _httpClient.denyRequestWithoutAuthorization = YES;
    _httpsClient = [[GreeHTTPClient alloc] 
      initWithBaseURL:[NSURL URLWithString:[_settings stringValueForSetting:GreeSettingServerUrlOsWithSSL]] 
      key:[_settings stringValueForSetting:GreeSettingConsumerKey]
      secret:[_settings stringValueForSetting:GreeSettingConsumerSecret]];
    _httpsClient.denyRequestWithoutAuthorization = YES;
    [self setDefaultCookies];
    
    __block GreePlatform* nonRetainedSelf = self;
    _reachability = [[GreeNetworkReachability alloc] initWithHost:@"http://www.apple.com"];
    _reachabilityObserver = [_reachability addObserverBlock:^(GreeNetworkReachabilityStatus previous, GreeNetworkReachabilityStatus current) {
      if (!GreeNetworkReachabilityStatusIsConnected(previous) &&
          GreeNetworkReachabilityStatusIsConnected(current)) {
        //[nonRetainedSelf.writeCache commitAllObjectsOfClass:NSClassFromString(@"GreeScore")];
        //[nonRetainedSelf.writeCache commitAllObjectsOfClass:NSClassFromString(@"GreeAchievement")];
        [nonRetainedSelf updateBootstrapSettingsWithAttemptNumber:1 statusBlock:nil];
      }
    }];

    _analyticsQueue = [[GreeAnalyticsQueue alloc] initWithSettings:_settings];

    Class notificationQueueClass = NSClassFromString(@"GreeNotificationQueue");
    if(notificationQueueClass) {
      //NOTE: ignore the memory leak warning here from static analyzer, it's not a real memory leak.
      _rawNotificationQueue = [[notificationQueueClass alloc] performSelector:@selector(initWithSettings:) withObject:_settings];
    }
    
    _localNotification = [[GreeLocalNotification alloc] initWithSettings:_settings];
    
    _interfaceOrientation = (UIInterfaceOrientation)[_settings integerValueForSetting:GreeSettingInterfaceOrientation];

    _manuallyRotate = NO;
    if ([_settings settingHasValue:GreeSettingManuallyRotateGreePlatform]) {
      _manuallyRotate = [_settings boolValueForSetting:GreeSettingManuallyRotateGreePlatform];
    }
    
    NSDictionary *greeSDKJSSommandsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
      [GreeJSInviteExternalUserCommand class], [GreeJSInviteExternalUserCommand name],
      [GreeJSSeeMoreCommand class], [GreeJSSeeMoreCommand name],
      [GreeJSShowShareDialogCommand class], [GreeJSShowShareDialogCommand name],
      [GreeJSShowWebViewDialogCommand class], [GreeJSShowWebViewDialogCommand name],
      [GreeJSRecordAnalyticsDataCommand class], [GreeJSRecordAnalyticsDataCommand name],
      [GreeJSFlushAnalyticsDataCommand class], [GreeJSFlushAnalyticsDataCommand name],
      [GreeJSShowDashboardCommand class], [GreeJSShowDashboardCommand name],
      [GreeJSShowRequestDialogCommand class], [GreeJSShowRequestDialogCommand name],
      [GreeJSShowInviteDialogCommand class], [GreeJSShowInviteDialogCommand name],
      [GreeJSPopupCloseSharePopupCommand class], [GreeJSPopupCloseSharePopupCommand name],
      [GreeJSPopupNeedReAuthorizeCommand class], [GreeJSPopupNeedReAuthorizeCommand name],
      [GreeJSPopupNeedUpgradeCommand class], [GreeJSPopupNeedUpgradeCommand name],
      [GreeJSPopupLogoutCommand class], [GreeJSPopupLogoutCommand name],
      [GreeJSShowDashboardFromNotificationBoardCommand class], [GreeJSShowDashboardFromNotificationBoardCommand name],
      [GreeJSRegisterLocalNotificationTimer class], [GreeJSRegisterLocalNotificationTimer name],
      [GreeJSCancelLocalNotificationTimer class], [GreeJSCancelLocalNotificationTimer name],
      [GreeJSSetLocalNotificationEnabled class], [GreeJSSetLocalNotificationEnabled name],
      [GreeJSGetLocalNotificationEnabled class], [GreeJSGetLocalNotificationEnabled name],
      [GreeJSLaunchServiceCommand class], [GreeJSLaunchServiceCommand name],
      [GreeJSNotifyServiceResultCommand class], [GreeJSNotifyServiceResultCommand name],
      [GreeJSCloseCommand class], [GreeJSCloseCommand name],
      [GreeJSGetConfigCommand class], [GreeJSGetConfigCommand name],
      [GreeJSGetConfigListCommand class], [GreeJSGetConfigListCommand name],
      [GreeJSSetConfigCommand class], [GreeJSSetConfigCommand name],
      [GreeJSGetAppListCommand class], [GreeJSGetAppListCommand name],
      [GreeJSGetViewInfoCommand class], [GreeJSGetViewInfoCommand name],
      [GreeJSDeleteCookieCommand class], [GreeJSDeleteCookieCommand name],
      nil];
    
    [[GreeJSCommandFactory instance] importCommandMap:greeSDKJSSommandsDictionary];
            
    Class moderationListClass = NSClassFromString(@"GreeModerationList");
    if(moderationListClass) {
      _moderationList = [[moderationListClass alloc] performSelector:@selector(initWithSerialization)];
    }    
    _authorization = [[GreeAuthorization alloc] 
                      initWithConsumerKey:[_settings stringValueForSetting:GreeSettingConsumerKey] 
                      consumerSecret:[_settings stringValueForSetting:GreeSettingConsumerSecret] 
                      settings:_settings 
                      delegate:self];
    _badgeValues = [[GreeBadgeValues alloc] initWithSocialNetworkingServiceBadgeCount:0 applicationBadgeCount:0];
    
    NSString *aFilePath = [[NSBundle greePlatformCoreBundle] pathForResource:kActivityIndicatorFileName ofType:nil];
    _activityIndicatorContentsString = [[NSString stringWithContentsOfFile:aFilePath encoding:NSUTF8StringEncoding error:nil] retain];
    
    _rotator = [[GreeRotator alloc] init];
  }
  
  return self;
}

- (void)dealloc
{
  [_writeCache cancelOutstandingOperations];
  [_analyticsQueue release];
  [_reachability removeObserverBlock:_reachabilityObserver];
  _reachabilityObserver = nil;
  [_reachability release];
  _reachability = nil;
  [_rawNotificationQueue release];
  [_localNotification release];
  [_settings release];
  [_httpClient release];
  [_httpsClient release];
  [_writeCache release];
  [_logger release];
  [_localUser release];
  [_localUserId release];
  if(_moderationList) {
    [_moderationList performSelector:@selector(finish)]; //break timer circular reference
    [_moderationList release];
  }
  [_authorization release];
  [_badgeValues release];
  [_activityIndicatorContentsString release];
  [consumerScramble release];
  [_rotator release];
  [super dealloc];
}

#pragma mark - Public Interface

+ (void)initializeWithApplicationId:(NSString*)applicationId 
  consumerKey:(NSString*)consumerKey 
  consumerSecret:(NSString*)consumerSecret 
  settings:(NSDictionary*)settings
  delegate:(id<GreePlatformDelegate>)delegate;
{
  NSAssert(!sSharedSDKInstance, @"You must only initialize GreePlatform once!");
  if (!sSharedSDKInstance) {
    sSharedSDKInstance = [[GreePlatform alloc] 
      initWithApplicationId:applicationId 
      consumerKey:consumerKey 
      consumerSecret:consumerSecret 
      settings:settings
      delegate:delegate];
    GreeLogPublic(@"Initialized Gree Platform SDK %@ (Build %@)", [GreePlatform version], [GreePlatform build]);
    
#if DEBUG
    [GreePlatform showConnectionServer];
#endif
  }

  BOOL useWallet = [[GreePlatform sharedInstance].settings boolValueForSetting:GreeSettingUseWallet];
  if (useWallet) {
    Class walletClass = NSClassFromString(@"GreeWallet");
    if(walletClass) {
      [walletClass performSelector:@selector(initializeAndRunFetchProductsWithDelegate:) withObject:nil];      
    }
  }
}

+ (void)shutdown
{
  NSAssert(sSharedSDKInstance, @"You must initialize GreePlatform before calling shutdown!");
  if (sSharedSDKInstance) {
    sSharedSDKInstance.finished = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:sSharedSDKInstance]; //kill any outstanding requests
    [sSharedSDKInstance release];
    sSharedSDKInstance = nil;
  }
}

+ (GreePlatform*)sharedInstance
{
  return sSharedSDKInstance;
}

+ (NSString*)version
{
  return @"3.0.0";
}

+ (NSString*)build
{
  return @"ga94";
}

+ (NSString*)paddedAppVersion;
{
  static NSString* cachedCopy = nil;
  if(!cachedCopy) {
    NSString*rawVersion = [GreePlatform bundleVersion];
    cachedCopy = [[rawVersion formatAsGreeVersion] retain];
  }
  return cachedCopy;
}

+ (NSString*)bundleVersion
{
  static NSString* bundleVersionString = nil;
  if(!bundleVersionString) {
    bundleVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
  }
  return bundleVersionString;
}

- (void)signRequest:(NSMutableURLRequest*)request parameters:(NSDictionary *)params
{
  
  
  NSMutableDictionary* additionalParameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                               [_settings stringValueForSetting:GreeSettingApplicationId], @"opensocial_app_id",
                                               nil];
  NSString* localUserId = [[_localUserId copy] autorelease];
  if (!localUserId) {
    localUserId = @"";
  }

  [additionalParameters setObject:localUserId forKey:@"opensocial_viewer_id"];
  [additionalParameters setObject:localUserId forKey:@"opensocial_owner_id"];

  //need to add these parameters to the query
  NSString* additionalQuery = GreeAFQueryStringFromParametersWithEncoding(additionalParameters, NSUTF8StringEncoding);

  //stitch 'em together!
  NSMutableString* urlString = [[request.URL.absoluteString mutableCopy] autorelease];
  [urlString appendString:(request.URL.query ? @"&" : @"?")];
  
  [urlString appendString:additionalQuery];
  request.URL = [NSURL URLWithString:urlString];
  
  //and to the values sent for signing
  [additionalParameters addEntriesFromDictionary:params];
  [self.httpClient signRequest:request parameters:additionalParameters];
}

- (void)setDefaultCookies 
{
  NSString* appId = [_settings stringValueForSetting:GreeSettingApplicationId];
  NSString* urlSchemeString = [NSString stringWithFormat:@"%@%@", [_settings stringValueForSetting:GreeSettingApplicationUrlScheme], appId];
  NSDictionary* parames = [NSDictionary dictionaryWithObjectsAndKeys:
    urlSchemeString, @"URLScheme",
    @"iphone-app", @"uatype",
    [GreePlatform paddedAppVersion], @"appVersion",
    [GreePlatform bundleVersion], @"bundleVersion",
    [GreePlatform version], @"iosSDKVersion",
    [GreePlatform build], @"iosSDKBuild",
    nil]; 
  [NSHTTPCookieStorage greeSetCookieWithParams:parames domain:[_settings stringValueForSetting:GreeSettingServerUrlDomain]];  
}

- (void)addAnalyticsEvent:(GreeAnalyticsEvent*)event {
  [self.analyticsQueue addEvent:event];
}

- (void)flushAnalyticsQueueWithBlock:(void(^)(NSError* error))block {
  [self.analyticsQueue flushWithBlock:block];
}

- (void)updateBadgeValuesWithBlock:(void(^)(GreeBadgeValues* badgeValues))block {
  BOOL forAllApplications = [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"jp.gree.greeapp"] ? YES : NO;
  [self updateBadgeValuesWithBlock:block forAllApplications:forAllApplications];
}

- (void)updateBadgeValuesWithBlock:(void(^)(GreeBadgeValues* badgeValues))block forAllApplications:(BOOL)forAllApplications {

  void (^completionBlock)(GreeBadgeValues*, NSError*) = ^(GreeBadgeValues* badgeValues, NSError *error){
    if (error) {
      GreeLogWarn(@"Badge Values could not be loaded: %@", [error localizedDescription]);
      if (block) {
        // If there is a network problem, return the existing badge value
        block(_badgeValues);
      }
    } else {
      dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
      dispatch_sync(concurrentQueue, ^{
        [_badgeValues release];
        _badgeValues = [badgeValues retain];
      });
      if (block) {
        block(badgeValues);
      }
    }
  };

  if (forAllApplications) {
    [GreeBadgeValues loadBadgeValuesForAllApplicationsWithBlock:completionBlock];
  } else {
    [GreeBadgeValues loadBadgeValuesForCurrentApplicationWithBlock:completionBlock];
  }
}

+ (NSString*)greeApplicationURLScheme
{
  static dispatch_once_t onceToken;
  static NSString *theApplicationURLScheme;
  
  dispatch_once(&onceToken, ^{
    NSString *aGreeURLScheme = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationUrlScheme];
    NSString *anApplicationIdString = [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingApplicationId];
    theApplicationURLScheme = [[NSString stringWithFormat:@"%@%@", aGreeURLScheme, anApplicationIdString] retain];
  });
  
  return theApplicationURLScheme;
}

+ (void)authorize;
{  
  [[GreeAuthorization sharedInstance] authorize];  
}

+ (void)revokeAuthorization
{
  [[GreeAuthorization sharedInstance] revoke];
}

+ (BOOL)isAuthorized
{
  return [[GreeAuthorization sharedInstance] isAuthorized];
}

+ (void)upgradeWithParams:(NSDictionary*)params
  successBlock:(void(^)(void))successBlock
  failureBlock:(void(^)(void))failureBlock
{
  [[GreeAuthorization sharedInstance] upgradeWithParams:params 
    successBlock:successBlock 
    failureBlock:failureBlock];
}

- (NSString*)accessToken
{
  return _authorization.accessToken;
}

- (NSString*)accessTokenSecret
{
  return _authorization.accessTokenSecret;
}

+ (void)printEncryptedStringWithConsumerKey:(NSString*)consumerKey
    consumerSecret:(NSString*)consumerSecret
    scramble:(NSString*)scramble
{
  NSString*  encryptedConsumerKey = [GreeConsumerProtect encryptedHexString:consumerKey keyString:scramble];
  NSLog(@"[Encrypted ConsumerKey:%@]", encryptedConsumerKey);
  NSString*  encryptedConsumerSecret = [GreeConsumerProtect encryptedHexString:consumerSecret keyString:scramble];
  NSLog(@"[Encrypted ConsumerSecret:%@]", encryptedConsumerSecret);
}

+ (void)setConsumerProtectionWithScramble:(NSString*)scramble
{
  consumerScramble = [scramble copy];
}

+ (void)setInterfaceOrientation:(UIInterfaceOrientation)orientation
{
  sSharedSDKInstance.interfaceOrientation = orientation;
  [sSharedSDKInstance.rotator rotateViewsToInterfaceOrientation:orientation animated:YES duration:0.3f];
}

+ (BOOL)handleOpenURL:(NSURL*)url application:(UIApplication*)application
{
  if([url isSelfGreeURLScheme]) {
    NSString* handledCommand = [url host];
    if([handledCommand isEqualToString:@"start"]){
      NSString* handledCommandType = nil;
      if([[url pathComponents] count] > 1) handledCommandType = [[url pathComponents] objectAtIndex:1];
      
      // Request - greeappXXXX://start/request?.id=xxx&.type=xxx&...
      if([handledCommandType isEqualToString:@"request"] || [handledCommandType isEqualToString:@"message"]){
        NSDictionary* query = [url.query greeDictionaryFromQueryString];
        NSDictionary* param = [NSDictionary dictionaryWithObjectsAndKeys:
                               [query objectForKey:@".id"], @"info-key",
                               query, @"params",
                               nil];
        
        UIViewController *presentingViewController = [UIViewController greeLastPresentedViewController];
        
        if ([presentingViewController isKindOfClass:[GreeDashboardViewController class]]) {
            UIViewController *presentingPresentingViewController = [presentingViewController greePresentingViewController];
            [presentingPresentingViewController dismissGreeDashboardAnimated:YES completion:^(id results){
              
              // close dashboard and notify params to app
              [[GreePlatform sharedInstance] notifyLaunchParameterToApp:param];
              
            }];
        } else {

          // just notifying params to app
          [[GreePlatform sharedInstance] notifyLaunchParameterToApp:param];

        }
        
        return TRUE;
      }
    }
  }
  
  return [[GreeAuthorization sharedInstance] handleOpenURL:url];  
}

- (void)sendParamsToApplication:(NSDictionary*)params
{
  if([_delegate respondsToSelector:@selector(greePlatformParamsReceived:)]){
    [_delegate greePlatformParamsReceived:params];
  }
}

+ (void)postDeviceToken:(NSData*)deviceToken block:(void(^)(NSError* error))block
{
  dispatch_block_t handler = ^{
    NSString *macAddr = [GreeDeviceIdentifier macAddress];
    NSString *uiid = [GreeApplicationUuid() stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    NSString *deviceId = [NSString stringWithFormat:@"%@%@", macAddr, uiid];
    NSString* deviceTokenString = [deviceToken greeBase64EncodedString];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"ios", @"device",
                            deviceId, @"device_id",
                            deviceTokenString, @"notification_key",
                            nil];
    
    GreeLog(@"params:%@", params);

    [[GreePlatform sharedInstance].httpClient
     postPath:@"/api/rest/registerpnkey/@me/@self/@app"
     parameters:params
     success:^(GreeAFHTTPRequestOperation *operation, id responseObject) {
       GreeLog(@"Okay, posted a token");
       if (block) {
         block(nil);
       }
     }
     failure:^(GreeAFHTTPRequestOperation *operation, NSError *error){
       GreeLogWarn(@"error:%@", error);
       if (block) {
         block(error);
       }
     }];
  };
  
  if ([GreePlatform sharedInstance].localUserId) {
    handler();
  } else {
    GreeLog(@"Tasks in %s have been skipped since user has not logged in.", __FUNCTION__);
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.f * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
      if ([GreePlatform sharedInstance].localUserId) {
        handler();
      }
    });
  }
}

+ (void)handleLaunchOptions:(NSDictionary*)launchOptions application:(UIApplication *)application
{
  dispatch_block_t handler = ^{
    //Local Notification
    Class localNotificationClass = NSClassFromString(@"UILocalNotification");
    if (localNotificationClass != nil) {
      if ([launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey]) {
        UILocalNotification* localNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        [[GreePlatform sharedInstance].localNotification handleLocalNotification:localNotification application:application];
      }
    }
    //Remote Notification
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
      NSDictionary* userInfo = [launchOptions valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
      [self handleRemoteNotification:userInfo application:application];
    }
  };

  GreeLog(@"launchOptions:%@", launchOptions);
  
  if ([GreePlatform sharedInstance].localUserId) {
    handler();
  } else {
    GreeLog(@"Tasks in %s have been skipped since user has not logged in.", __FUNCTION__);
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.f * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
      if ([GreePlatform sharedInstance].localUserId) {
        handler();
      }
    });
  }
}

+ (BOOL)handleRemoteNotification:(NSDictionary *)notificationDictionary application:(UIApplication *)application
{
  dispatch_block_t handler = ^{
    if (application.applicationState != UIApplicationStateActive) {
      NSString* appId = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingApplicationId];
      NSNumber* notificationType = [notificationDictionary valueForKey:@"ntype"];
      
      NSMutableDictionary* analyticsParamters = [NSMutableDictionary dictionaryWithObject:appId forKey:@"app_id"];
      if (notificationType) {
        [analyticsParamters setObject:notificationType forKey:@"ntype"];
      }
      
      if([notificationDictionary objectForKey:@"aps"]){
        NSDictionary* aps = [notificationDictionary valueForKey:@"aps"];
        if([aps objectForKey:@"request_id"]){
          // launch notification board
          NSDictionary* param = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [aps valueForKey:@"request_id"], @"info-key",
                                 nil];
          
          [[GreePlatform sharedInstance] performBlock:^(void){
            UIViewController *viewController = [UIViewController greeLastPresentedViewController];
            [viewController
             presentGreeNotificationBoardWithType:GreeNotificationBoardLaunchWithRequestDetail
             parameters:param
             delegate:viewController
             animated:YES
             completion:nil];
          } afterDelay:1.0f];
          
          [analyticsParamters setObject:[aps valueForKey:@"request_id"] forKey:@"request_id"];
        } else if([aps objectForKey:@"message_id"]){
          // launch notification board
          NSDictionary* param = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [aps valueForKey:@"message_id"], @"info-key",
                                 nil];
          
          [[GreePlatform sharedInstance] performBlock:^(void){
            UIViewController *viewController = [UIViewController greeLastPresentedViewController];
            [viewController
             presentGreeNotificationBoardWithType:GreeNotificationBoardLaunchWithMessageDetail
             parameters:param
             delegate:viewController
             animated:YES
             completion:nil];
          } afterDelay:1.0f];
          
          [analyticsParamters setObject:[aps valueForKey:@"message_id"] forKey:@"message_id"];
        } else if([notificationType isEqualToNumber:[NSNumber numberWithInt:kGreePlatformRemoteNotificationTypeSNS]]){
          UIViewController *viewController = [UIViewController greeLastPresentedViewController];
          [viewController
           presentGreeNotificationBoardWithType:GreeNotificationBoardLaunchAutoSelect
           parameters:nil
           delegate:viewController
           animated:YES
           completion:nil];
        }
      }
      
      [[GreePlatform sharedInstance] addAnalyticsEvent:[GreeAnalyticsEvent eventWithType:@"evt"
                                                                                    name:@"boot_app"
                                                                                    from:@"push_notification"
                                                                              parameters:analyticsParamters]];
    }
    
    if ([[GreePlatform sharedInstance].settings boolValueForSetting:GreeSettingUpdateBadgeValuesAfterRemoteNotification]) {
      [[GreePlatform sharedInstance] updateBadgeValuesWithBlock:nil];
    }
    
    [[GreePlatform sharedInstance].rawNotificationQueue performSelector:@selector(handleRemoteNotification:)
                                                             withObject:notificationDictionary];
  };
  
  if ([GreePlatform sharedInstance].localUserId) {
    handler();
    return YES;
  } else {
    GreeLog(@"Received a push notification, but ignored since user has not logged in.");
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.f * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
      if ([GreePlatform sharedInstance].localUserId) {
        handler();
      }
    });
    return NO;
  }
}

+ (void)handleLocalNotification:(UILocalNotification *)notification application:(UIApplication *)application {
  [[GreePlatform sharedInstance].localNotification handleLocalNotification:notification application:application];
}

#pragma mark - Internal Methods

- (void)notifyLaunchParameterToApp:(NSDictionary*)param
{
  if ([_delegate respondsToSelector:@selector(greePlatformParamsReceived:)]) {
    [_delegate greePlatformParamsReceived:param];
  }
}

- (GreeNetworkReachability*)analyticsReachability
{
  return self.reachability;
}

- (void)updateLocalUser:(GreeUser *)newUser
{
  [self updateLocalUser:newUser withNotification:NO];
}

- (void)updateLocalUser:(GreeUser*)newUser withNotification:(BOOL)notification
{
  if (newUser == self.localUser) {
    return;
  }
  
  self.localUser = newUser;

  if (newUser) {
    self.writeCache = [[[GreeWriteCache alloc] initWithUserId:newUser.userId] autorelease];
    [self.writeCache setHashKey:[self.settings stringValueForSetting:GreeSettingConsumerSecret]];
  } else {
    self.writeCache = nil;
  }
  
  if (newUser) {
    [GreeUser storeLocalUser:newUser];
  } else {
    [GreeUser removeLocalUserInCache];
  }

  NSDictionary* info = nil;
  if (newUser) {
    info = [NSDictionary dictionaryWithObject:newUser forKey:GreeNSNotificationKeyUser];
  }

  if (notification) {
    [self updateBadgeValuesWithBlock:nil];
    [self.rawNotificationQueue performSelector:@selector(generateLoginNotificationWithNickname:) withObject:newUser.nickname];

    [[NSNotificationCenter defaultCenter] postNotificationName:GreeNSNotificationUserLogin object:nil userInfo:info];
    if ([_delegate respondsToSelector:@selector(greePlatform:didLoginUser:)]) {
      [_delegate greePlatform:self didLoginUser:self.localUser];
    }
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:GreeNSNotificationKeyDidUpdateLocalUserNotification object:nil userInfo:info];
  if ([_delegate respondsToSelector:@selector(greePlatform:didUpdateLocalUser:)]) {
    [_delegate greePlatform:self didUpdateLocalUser:self.localUser];
  }
}

- (void)retryToUpdateLocalUser
{
  if(self.finished) {
    return;   
  }
  [GreeUser loadUserWithId:@"@me" block:^(GreeUser* user, NSError* error) {
    if (user) {
      [self updateLocalUser:user];
    } else {
      [self performSelector:@selector(retryToUpdateLocalUser) withObject:nil afterDelay:1.f];
    }
  }];
}

+ (void)showConnectionServer
{
  GreeSettings* settings = [GreePlatform sharedInstance].settings;
  if(![settings boolValueForSetting:GreeSettingShowConnectionServer]){
    return;
  }
  
  //this delay is for the competition of the startup login popup.
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.7f * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
    NSString* title = @"Current settings";
    NSString* message = [NSString stringWithFormat:@"mode:%@\nsuffix:%@", 
                         [settings stringValueForSetting:GreeSettingDevelopmentMode],
                         [settings stringValueForSetting:GreeSettingServerUrlSuffix]];
    UIAlertView* alert = [[[UIAlertView alloc]
                           initWithTitle:title
                           message:message
                           delegate:nil
                           cancelButtonTitle:nil
                           otherButtonTitles:@"OK", nil] autorelease];
    [alert show];
    GreeLogWarn(@"%@\n%@", title, message);
  });
}

#pragma mark Bootstrap Settings

- (NSDictionary*)bootstrapSettingsDictionary
{
  NSDictionary* bootstrapSettings = nil;
  
  NSString* path = [NSString greeCachePathForRelativePath:@"bootstrapSettings"];
  NSData* data = [[NSData alloc] initWithContentsOfFile:path];
  NSString* hash = [data greeHashWithKey:[self.settings stringValueForSetting:GreeSettingConsumerSecret]];
  NSString* expectedHash = [[NSUserDefaults standardUserDefaults] stringForKey:@"GreeBootstrapSettings"];
  if ([hash isEqualToString:expectedHash]) {
    NSDictionary* deserialized = [data greeObjectFromJSONData];
    if ([deserialized count] > 0) {
      bootstrapSettings = deserialized;
    }
  }

  [data release];
  return bootstrapSettings;
}

- (void)writeBootstrapSettingsDictionary:(NSDictionary*)bootstrapSettings
{
  if ([bootstrapSettings count] == 0)
    return;

  NSString* path = [NSString greeCachePathForRelativePath:@"bootstrapSettings"];
  [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:0x0 error:nil];
  NSData* data = [bootstrapSettings greeJSONData];
  NSString* hash = [data greeHashWithKey:[self.settings stringValueForSetting:GreeSettingConsumerSecret]];
  NSError* writeError = nil;
  BOOL succeeded = [data writeToFile:path options:NSDataWritingAtomic error:&writeError];
  if (succeeded && writeError == nil) {
    [[NSUserDefaults standardUserDefaults] setObject:hash forKey:@"GreeBootstrapSettings"];
  }
}

- (void)updateBootstrapSettingsWithAttemptNumber:(NSInteger)attemptNumber statusBlock:(BOOL(^)(BOOL didSucceed))statusBlock
{
  __block GreePlatform* nonRetainedSelf = self;
  
  void(^failureBlock)(NSInteger) = ^(NSInteger failingAttempt) {
    BOOL retryHint = YES;
    if (statusBlock != NULL) {
      retryHint = statusBlock(NO);
    }
    if (retryHint && failingAttempt < 5) {
      double delay = pow(3.0, (double)failingAttempt);
      dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
      dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (sSharedSDKInstance == nonRetainedSelf) {
          [nonRetainedSelf updateBootstrapSettingsWithAttemptNumber:failingAttempt+1 statusBlock:statusBlock];
        }
      });
    }
  };
  
  NSMutableString* path = [NSMutableString stringWithFormat:@"api/rest/sdkbootstrap/%@/ios", [self.settings stringValueForSetting:GreeSettingApplicationId]];
  if (self.localUserId) {
    [path appendFormat:@"/%@", self.localUserId];
  }
  [self.httpsClient
    performTwoLeggedRequestWithMethod:@"GET"
    path:path
    parameters:nil
    success:^(GreeAFHTTPRequestOperation* operation, id settings) {
      settings = [settings valueForKeyPath:@"entry.settings"];
      if ([settings isKindOfClass:[NSDictionary class]] && [settings count] > 0) {
        [self writeBootstrapSettingsDictionary:settings];
        if (statusBlock) {
          statusBlock(YES);
        }
      } else {
        if (statusBlock) {
          statusBlock(NO);
        }
      }
    }
    failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
      failureBlock(attemptNumber);
    }];
}

#pragma mark - GreeAuthorization Delegate Method

- (void)authorizeDidUpdateUserId:(NSString*)userId withToken:(NSString*)token withSecret:(NSString*)secret
{
  self.localUserId = userId;
  [_httpClient setUserToken:token secret:secret];
  [_httpsClient setUserToken:token secret:secret];
}

- (void)authorizeDidFinishWithLogin:(BOOL)blogin
{
  if(!self.didGameCenterInitialization) {
    self.didGameCenterInitialization = YES;
    if ([[_settings objectValueForSetting:GreeSettingGameCenterAchievementMapping] count] > 0 ||
        [[_settings objectValueForSetting:GreeSettingGameCenterLeaderboardMapping] count] > 0) {
      [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:nil];
    }
  }
  
  GreeAuthorization* authorization = [GreeAuthorization sharedInstance];
  
  //great, now if we have a token, we should try to get the user
  //otherwise, we have somehow lost the user, so we should log out
  
  //we should clear out the old user during this time period
  [[NSNotificationCenter defaultCenter] postNotificationName:GreeNSNotificationUserInvalidated object:nil userInfo:nil];
  GreeUser* previousUser = [self.localUser retain];
  [self updateLocalUser:nil];
  if(authorization.accessToken) {
    GreeUser* cachedUser = [GreeUser localUserFromCache];
    if ([cachedUser.userId isEqualToString:self.localUserId]) {
      [self updateLocalUser:cachedUser withNotification:blogin];
      // localUser should update also there is cache because user can update him/herself profile on the web.
      [self performSelector:@selector(retryToUpdateLocalUser) withObject:nil afterDelay:1.f];
    } else {
      [GreeUser loadUserWithId:@"@me" block:^(GreeUser* user, NSError* error) {
        [self updateLocalUser:user withNotification:blogin];
        if (!user) {
          [self performSelector:@selector(retryToUpdateLocalUser) withObject:nil afterDelay:1.f];
        }
      }];
    }
  } else {
    if ([_delegate respondsToSelector:@selector(greePlatform:didLogoutUser:)]) {
      [_delegate greePlatform:self didLogoutUser:previousUser];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:GreeNSNotificationUserLogout object:nil userInfo:nil];
  }
  [previousUser release];
}
     
- (void)revokeDidFinish
{
  GreeUser* oldUser = [self.localUser retain];
  [self updateLocalUser:nil];
  [[NSNotificationCenter defaultCenter] postNotificationName:GreeNSNotificationUserLogout object:nil userInfo:nil];
  if ([_delegate respondsToSelector:@selector(greePlatform:didLogoutUser:)]) {
    [_delegate greePlatform:self didLogoutUser:oldUser];
  }
  [oldUser release];
  
  self.localUserId = nil;
    
  [_badgeValues release];
  _badgeValues = [[GreeBadgeValues alloc] initWithSocialNetworkingServiceBadgeCount:0 applicationBadgeCount:0];
  [GreeBadgeValues resetBadgeValues];
}

+ (void)endGeneratingRotation {
  sSharedSDKInstance.deviceNotificationCount = 0;
  while ([[UIDevice currentDevice] isGeneratingDeviceOrientationNotifications]) {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    sSharedSDKInstance.deviceNotificationCount++;
    
    // for safety, in case something goes wrong
    if (sSharedSDKInstance.deviceNotificationCount > 1000) {
      break;
    }
  }
}

+ (void)beginGeneratingRotation {
  for (int i = 0; i < sSharedSDKInstance.deviceNotificationCount; i++) {
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  }
}
@end
