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

#import <UIKit/UIKit.h>
#import "GreeSettings.h"
#import "JSONKit.h"
#import "NSString+GreeAdditions.h"

NSString* const GreeDevelopmentModeProduction = @"production";
NSString* const GreeDevelopmentModeSandbox = @"sandbox";
NSString* const GreeDevelopmentModeStaging = @"staging";
NSString* const GreeDevelopmentModeStagingSandbox = @"stagingSandbox";
NSString* const GreeDevelopmentModeDevelop = @"develop";
NSString* const GreeDevelopmentModeDevelopSandbox = @"developSandbox";

#pragma mark - Public Settings (declared in GreePlatformSettings.h)

NSString* const GreeSettingDevelopmentMode = @"developmentMode";
NSString* const GreeSettingInterfaceOrientation = @"interfaceOrientation";
NSString* const GreeSettingNotificationPosition = @"notificationPosition";
NSString* const GreeSettingNotificationEnabled = @"notificationEnabled";
NSString* const GreeSettingWidgetPosition = @"widgetPosition";
NSString* const GreeSettingWidgetExpandable = @"widgetExpandable";
NSString* const GreeSettingGameCenterAchievementMapping = @"gameCenterAchievementMapping";
NSString* const GreeSettingGameCenterLeaderboardMapping = @"gameCenterLeaderboardMapping";
NSString* const GreeSettingEnableLogging = @"enableLogging";
NSString* const GreeSettingWriteLogToFile = @"writeToFile";
NSString* const GreeSettingLogLevel = @"logLevel";
NSString* const GreeSettingUpdateBadgeValuesAfterRemoteNotification= @"updateBadgeValuesAfterRemoteNotification";
NSString* const GreeSettingUseWallet = @"useWallet";
NSString* const GreeSettingRemoveTokenWithReInstall  = @"removeTokenWithReInstall";
NSString* const GreeSettingEnableGrade0 = @"enableGrade0";
NSString* const GreeSettingManuallyRotateGreePlatform = @"manuallyRotateGreePlatform";


#pragma mark - Internal Settings (declared in GreeSettings.h)

NSString* const GreeSettingInternalSettingsFilename = @"internalSettingsFilename";
NSString* const GreeSettingApplicationId = @"applicationId";
NSString* const GreeSettingConsumerKey = @"consumerKey";
NSString* const GreeSettingConsumerSecret = @"consumerSecret";
NSString* const GreeSettingApplicationUrlScheme = @"applicationUrlScheme";
NSString* const GreeSettingServerUrlSuffix = @"serverUrlSuffix";
NSString* const GreeSettingAllowRegistrationCancel = @"GreeSettingAllowRegistrationCancel";
NSString* const GreeSettingAnalyticsMaximumStorageTime = @"analyticsMaximumStorageTime";
NSString* const GreeSettingAnalyticsPollingInterval = @"analyticsPollingInterval";
NSString* const GreeSettingEnableLocalNotification = @"enableLocalNotification";
NSString* const GreeSettingParametersForDeletingCookie = @"parametersForDeletingCookie";
NSString* const GreeSettingShowConnectionServer = @"showConnectionServer";
NSString* const GreeSettingUserThumbnailTimeoutInSeconds = @"userThumbnailTimeoutInSeconds";

#pragma mark - Dependent Settings (declared in GreeSettings.h)

NSString* const GreeSettingServerUrlDomain = @"serverUrlDomain";
NSString* const GreeSettingServerHostNamePrefix = @"serverHostNamePrefix";
NSString* const GreeSettingServerHostNameSuffix = @"serverHostNameSuffix";
NSString* const GreeSettingServerUrlApps = @"appsUrl";
NSString* const GreeSettingServerUrlPf = @"pfUrl";
NSString* const GreeSettingServerUrlOpen = @"openUrl";
NSString* const GreeSettingServerUrlId = @"idUrl";
NSString* const GreeSettingServerUrlOs = @"osUrl";
NSString* const GreeSettingServerUrlOsWithSSL = @"osWithSSLUrl";
NSString* const GreeSettingServerUrlPayment = @"paymentUrl";
NSString* const GreeSettingServerUrlNotice = @"noticeUrl";
NSString* const GreeSettingServerUrlGames = @"gamesUrl";
NSString* const GreeSettingServerUrlGamesRequestDetail = @"requestDetailUrl";
NSString* const GreeSettingServerUrlGamesMessageDetail = @"messageDetailUrl";
NSString* const GreeSettingServerUrlHelp = @"helpUrl";
NSString* const GreeSettingServerUrlSns = @"snsUrl";
NSString* const GreeSettingServerPortSns = @"snsPort";
NSString* const GreeSettingServerUrlSnsApi = @"snsapiUrl";
NSString* const GreeSettingServerUrlSandbox = @"sandboxUrl";
NSString* const GreeSettingUniversalMenuUrl = @"universalMenuUrl";
NSString* const GreeSettingUniversalMenuPath = @"universalMenuPath";
NSString* const GreeSettingMyLoginNotificationPath = @"myLoginNotificationPath";
NSString* const GreeSettingFriendLoginNotificationPath = @"friendLoginNotificationPath";


NSString* const GreeSettingSnsAppName = @"sns.appname";

#define kGreeSettingsKeyInStorage @"GreeSettings"


@interface GreeSettings ()
@property (nonatomic, retain) NSMutableDictionary* settings;
@property (nonatomic, assign, getter=isFinalized) BOOL finalized;
@end

@implementation GreeSettings

@synthesize settings = _settings;
@synthesize finalized = _finalized;

#pragma mark - Object Lifecycle

- (id)init
{
  self = [super init];
  if (self != nil) {
    _settings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
      @"greeapp", GreeSettingApplicationUrlScheme,
      [NSNumber numberWithInteger:UIInterfaceOrientationPortrait], GreeSettingInterfaceOrientation,
      [NSNumber numberWithBool:YES], GreeSettingEnableLogging,
      @"ggpsns",GreeSettingSnsAppName,
      [NSNumber numberWithInt:60*5], GreeSettingUserThumbnailTimeoutInSeconds,
      nil];
  }
  return self;
}

- (void)dealloc
{
  [_settings release];
  [super dealloc];
}

#pragma mark - Public Interface

- (BOOL)settingHasValue:(NSString*)setting
{
  return [self.settings objectForKey:setting] != nil;
}

- (id)objectValueForSetting:(NSString*)setting
{
  return [self.settings objectForKey:setting];
}

- (BOOL)boolValueForSetting:(NSString*)setting
{
  return [[self.settings objectForKey:setting] boolValue];
}

- (NSInteger)integerValueForSetting:(NSString*)setting
{
  return [[self.settings objectForKey:setting] integerValue];
}

- (NSString*)stringValueForSetting:(NSString*)setting
{
  return [self.settings objectForKey:setting];
}

- (void)applySettingDictionary:(NSDictionary*)settings
{
  NSDictionary* settingsInStorage = [[NSUserDefaults standardUserDefaults] objectForKey:kGreeSettingsKeyInStorage];
  NSMutableDictionary* savingSettings = nil;
  if (settingsInStorage) {
    savingSettings = [NSMutableDictionary dictionaryWithDictionary:settingsInStorage];
  } else {
    savingSettings = [NSMutableDictionary dictionary];
  }
  for (id key in settings) {
    if ([[GreeSettings needToSupportSavingToNonVolatileAreaArray] containsObject:key]) {
      [savingSettings setValue:[settings objectForKey:key] forKey:key];
    }
  }
  if (0 < [savingSettings count]) {
    [[NSUserDefaults standardUserDefaults] setValue:savingSettings forKey:kGreeSettingsKeyInStorage];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
  
  [self.settings addEntriesFromDictionary:settings];
}

- (void)loadInternalSettingsFile
{
  NSString* filename = [self stringValueForSetting:GreeSettingInternalSettingsFilename];
  if ([filename length] > 0) {
    NSString* pathToSettingsFile = [[NSBundle mainBundle] pathForResource:filename ofType:@"json"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToSettingsFile]) {
      NSError* parseError = nil;
      NSData* settingsData = [[[NSData alloc] initWithContentsOfFile:pathToSettingsFile] autorelease];
      GreeJSONDecoder* decoder = [[[GreeJSONDecoder alloc] initWithParseOptions:GreeJKParseOptionComments] autorelease];
      id settings = [decoder objectWithData:settingsData error:&parseError];
      if ([settings isKindOfClass:[NSDictionary class]]) {
        [self applySettingDictionary:settings];
      } else {
        NSLog(@"[Gree] Failed to load internal settings file %@, error: %@", filename, parseError);
      }
    } else {
      NSLog(@"[Gree] Failed to open internal settings file %@", filename);
    }
  }
}

- (void)finalizeSettings
{
  if (!self.finalized) {
    NSDictionary* settingsInStorage = [[NSUserDefaults standardUserDefaults] objectForKey:kGreeSettingsKeyInStorage];
    for (id key in settingsInStorage) {
      [self.settings setObject:[settingsInStorage objectForKey:key] forKey:key];
    }
    
    NSString* developmentMode = [self stringValueForSetting:GreeSettingDevelopmentMode];
    
    NSString* prefix = @"https://";
    NSString* suffix = @".";
    NSString* domain = @"gree.net";
    
    if ([developmentMode isEqualToString:GreeDevelopmentModeProduction]) {
    } else if ([developmentMode isEqualToString:GreeDevelopmentModeSandbox]) {
      prefix = @"http://";
      suffix = @"-sb.";
    } else if ([developmentMode isEqualToString:GreeDevelopmentModeStaging] || [developmentMode isEqualToString:GreeDevelopmentModeStagingSandbox]) {
      NSAssert([self settingHasValue:GreeSettingServerUrlSuffix], @"Must specify a serverUrl suffix if you are using development mode: staging");
      prefix = @"http://";
      NSString* sbSuffix = ([developmentMode isEqualToString:GreeDevelopmentModeStagingSandbox])?@"sb":@"";      
      suffix = [NSString stringWithFormat:@"-%@%@.", sbSuffix, [self stringValueForSetting:GreeSettingServerUrlSuffix]];      
    } else if ([developmentMode isEqualToString:GreeDevelopmentModeDevelop] || [developmentMode isEqualToString:GreeDevelopmentModeDevelopSandbox]) {
      NSAssert([self settingHasValue:GreeSettingServerUrlSuffix], @"Must specify a serverUrl suffix if you are using development mode: develop or developSandbox");
      prefix = @"http://";
      NSString* sbSuffix = ([developmentMode isEqualToString:GreeDevelopmentModeDevelopSandbox])?@"-sb":@"";      
      suffix = [NSString stringWithFormat:@"%@-dev-%@.", sbSuffix, [self stringValueForSetting:GreeSettingServerUrlSuffix]];
      domain = @"dev.gree-dev.net";
    }
    
    [self.settings setObject:domain forKey:GreeSettingServerUrlDomain];
    [self.settings setObject:prefix forKey:GreeSettingServerHostNamePrefix];
    [self.settings setObject:suffix forKey:GreeSettingServerHostNameSuffix];

    NSString* defaultHosts[] = {
      GreeSettingServerUrlApps,       @"apps",
      GreeSettingServerUrlPf,         @"pf",
      GreeSettingServerUrlOpen,       @"open",
      GreeSettingServerUrlId,         @"id",
      GreeSettingServerUrlOs,         @"os",
      GreeSettingServerUrlOsWithSSL,  @"os",
      GreeSettingServerUrlPayment,    @"payment",
      GreeSettingServerUrlNotice,     @"notice",
      GreeSettingServerUrlHelp,       @"help",
      GreeSettingServerUrlSns,        @"sns",
      GreeSettingServerUrlSnsApi,     @"api-sns",
      GreeSettingServerUrlGames,      @"games",
      NULL
    };

    NSArray *noHttps = nil;
    if ([developmentMode isEqualToString:GreeDevelopmentModeProduction]) {
      noHttps = [NSArray arrayWithObjects:
                 GreeSettingServerUrlApps, 
                 GreeSettingServerUrlGames, 
                 GreeSettingServerUrlSns, 
                 GreeSettingServerUrlOs, 
                 GreeSettingServerUrlNotice, 
                 GreeSettingServerUrlPf,
                 nil];
    }

    NSString** p = defaultHosts;
    while (NULL != *p) {
      NSString* key = *p++;
      NSString* hostname = *p++;
      if ([self.settings objectForKey:key] == nil) {
        NSString* protocol = [noHttps containsObject:key] ? @"http://" : prefix;
        [self.settings setObject:[NSString stringWithFormat:@"%@%@%@%@", protocol, hostname, suffix, domain] forKey:key];
      }
    }
    
    // Notification Board URL
    NSString* defaultNBURL[] = {
      GreeSettingServerUrlGamesMessageDetail, @"/service/message/detail/",
      GreeSettingServerUrlGamesRequestDetail, @"/service/request/detail/",
      NULL
    };
    
    NSString** q = defaultNBURL;
    while (NULL != *q) {
      NSString* key = *q++;
      NSString* path = *q++;
      if ([self.settings objectForKey:key] == nil) {
        [self.settings setObject:[NSString stringWithFormat:@"%@%@", [self.settings objectForKey:GreeSettingServerUrlGames], path] forKey:key];
      }
    }

    if ([developmentMode isEqualToString:GreeDevelopmentModeDevelop]) {
      NSString *settingPort = [self.settings objectForKey:GreeSettingServerPortSns];
      NSString *port = settingPort ? settingPort : @"3030";
      [self.settings setObject:port forKey:GreeSettingServerPortSns];
      if (port) {
        NSString *url = [NSString stringWithFormat:@"%@:%@", [self.settings objectForKey:GreeSettingServerUrlSns], port];
        [self.settings setObject:url forKey:GreeSettingServerUrlSns];
      }
    }

    if (![self.settings objectForKey:GreeSettingUniversalMenuPath]) {
      if ([developmentMode isEqualToString:GreeDevelopmentModeSandbox] ||
          [developmentMode isEqualToString:GreeDevelopmentModeDevelopSandbox] ||
          [developmentMode isEqualToString:GreeDevelopmentModeStagingSandbox]) {
        [self.settings setObject:@"?action=universalmenu" forKey:GreeSettingUniversalMenuPath];
      } else {
        NSURL* gameDashboardBaseURL = [NSURL URLWithString:[self stringValueForSetting:GreeSettingServerUrlApps]];
        NSString *applicationIdString = [self stringValueForSetting:GreeSettingApplicationId];
        NSString *gameDashboardPath = [NSString stringWithFormat:@"gd?app_id=%@", applicationIdString];
        NSURL *gameDashboardURL = [NSURL URLWithString:gameDashboardPath relativeToURL:gameDashboardBaseURL];
        [self.settings setObject:[NSString stringWithFormat:@"/um#view=universalmenu_top&gamedashboard=%@&appportal=%@",
                                  [[gameDashboardURL absoluteString] greeURLEncodedString],
                                  [[self stringValueForSetting:GreeSettingServerUrlGames] greeURLEncodedString]]
                          forKey:GreeSettingUniversalMenuPath];
      }
    }
       
    [self.settings setObject:[NSString stringWithFormat:@"%@%@%@", prefix, [suffix substringFromIndex:1], domain]
                      forKey:GreeSettingServerUrlSandbox];
    if ([developmentMode isEqualToString:GreeDevelopmentModeProduction] ||
        [developmentMode isEqualToString:GreeDevelopmentModeStaging]) {
      [self.settings setObject:[self.settings objectForKey:GreeSettingServerUrlSns] forKey:GreeSettingUniversalMenuUrl];
    } else if ([developmentMode isEqualToString:GreeDevelopmentModeSandbox] ||
        [developmentMode isEqualToString:GreeDevelopmentModeDevelopSandbox] ||
        [developmentMode isEqualToString:GreeDevelopmentModeStagingSandbox]) {
      [self.settings setObject:[self.settings objectForKey:GreeSettingServerUrlSandbox]
                        forKey:GreeSettingUniversalMenuUrl];
    } else {
      if (![self.settings objectForKey:GreeSettingUniversalMenuUrl]) {
        [self.settings setObject:[self.settings objectForKey:GreeSettingServerUrlSns] forKey:GreeSettingUniversalMenuUrl];
      }
    }
    
    if (![self.settings objectForKey:GreeSettingMyLoginNotificationPath]) {
      [self.settings setObject:@"?view=stream_home" forKey:GreeSettingMyLoginNotificationPath];
    }
    
    if (![self.settings objectForKey:GreeSettingFriendLoginNotificationPath]) {
      [self.settings setObject:@"?view=profile_messageboard" forKey:GreeSettingFriendLoginNotificationPath];
    }
    
    self.finalized = YES;
  }
}

- (NSString*)serverUrlWithHostName:(NSString*)hostname {
  NSString* domain = [self stringValueForSetting:GreeSettingServerUrlDomain];
  NSString* prefix = [self stringValueForSetting:GreeSettingServerHostNamePrefix];
  NSString* suffix = [self stringValueForSetting:GreeSettingServerHostNameSuffix];
  return [NSString stringWithFormat:@"%@%@%@%@", prefix, hostname, suffix, domain];
}

+ (NSArray*)blackListForRemoteConfig
{
  static dispatch_once_t onceToken;
  static NSArray* anArray = nil;
  dispatch_once(&onceToken, ^{
    anArray = [[NSArray arrayWithObjects:
                GreeSettingApplicationId,
                GreeSettingConsumerKey,
                GreeSettingConsumerSecret,
                nil] retain];
    atexit_b(^{
      [anArray release], anArray = nil;
    });
  });
  
  return anArray;
}

+ (NSArray*)needToSupportSavingToNonVolatileAreaArray
{
  static dispatch_once_t onceToken;
  static NSArray* anArray = nil;
  dispatch_once(&onceToken, ^{
    anArray = [[NSArray arrayWithObjects:
                GreeSettingNotificationEnabled,
                GreeSettingEnableLogging,
                GreeSettingWriteLogToFile,
                GreeSettingLogLevel,
                GreeSettingEnableLocalNotification,
                nil] retain];
    atexit_b(^{
      [anArray release], anArray = nil;
    });
  });
  
  return anArray;
}

+ (NSArray*)blackListForGetConfig
{
  static dispatch_once_t onceToken;
  static NSArray* anArray = nil;
  dispatch_once(&onceToken, ^{
    anArray = [[NSArray arrayWithObjects:
                GreeSettingConsumerKey,
                GreeSettingConsumerSecret,
                GreeSettingParametersForDeletingCookie,
                nil] retain];
    atexit_b(^{
      [anArray release], anArray = nil;
    });
  });
  
  return anArray;
}

+ (NSArray*)blackListForSetConfig
{
  static dispatch_once_t onceToken;
  static NSArray* anArray = nil;
  dispatch_once(&onceToken, ^{
    anArray = [[NSArray arrayWithObjects:
                GreeSettingApplicationId,
                GreeSettingConsumerKey,
                GreeSettingConsumerSecret,
                GreeSettingParametersForDeletingCookie,
                nil] retain];
    atexit_b(^{
      [anArray release], anArray = nil;
    });
  });
  
  return anArray;
}


#pragma mark - NSObject Overrides

- (NSString*)description;
{
  return [NSString stringWithFormat:
    @"<%@:%p, settings:%@, finalized:%@>", 
    NSStringFromClass([self class]), 
    self, 
    self.settings,
    self.finalized ? @"YES" : @"NO"];
}

@end
