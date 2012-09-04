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

#import "GreePlatform.h"
#import "GreeDashboardLauncher.h"
#import "GreeDashboardLauncher+Internal.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"
#import "UIImage+GreeAdditions.h"
#import "GreeLogger.h"
#import "GreeDashboardViewController.h"
#import "GreeAnalyticsEvent.h"
#import "GreeJSWebViewController.h"
//#import "GreeDashboard.h"
#import "NSString+GreeAdditions.h"
#import "NSURL+GreeAdditions.h"
#import "GreeNSNotification.h"
#import "GreeNSNotification+Internal.h"
#import "GreeJSExternalWebViewController.h"
#import "UIViewController+GreePlatform.h"
#import "GreeDashboardViewControllerLaunchMode.h"


@interface GGPDashboard : GreeDashboardViewController
@end

@interface GreeDashboardLauncher()
- (NSString*)createGameDashboardUrlParams:(NSString*)appId userId:(NSString*)userId;
@end

@implementation GreeDashboardLauncher

#pragma mark - Object Lifecycle

@synthesize completion = _completion;
@synthesize currentDashboard = _currentDashboard;
@synthesize hostViewController = _hostViewController;

- (id)initWithHostViewController:(UIViewController*)viewController {
  if ((self = [super init])) {
    _hostViewController = viewController;
  }
  
  return self;
}

- (void)dealloc
{
  self.completion = nil;
  [super dealloc];
}

#pragma mark - Public Interface

- (void)launchDashboardWithParameters:(NSDictionary*)parameters completion:(void (^)(id))completion
{ 
  if ([GreePlatform isShowingModalView]) {
    return;
  }
  [self launchDashboardWithBaseURL:[NSURL URLWithString:[self dashboardURLStringWithParameters:parameters]] completion:completion];
}

- (NSString*)dashboardURLStringWithParameters:(NSDictionary *)parameters
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
        return [NSString stringWithFormat:@"%@", gameDashboardPath];
      }      
    } else {
      gameDashBoadPathAddParamsUrl = [self dashboardPathString:GreeDashboardModeTop appId:gameDashboardAppId userId:gameDashboardUserId];
    }
  } else {
    gameDashBoadPathAddParamsUrl = [NSString stringWithFormat:@"%@", GreeDashboardModeTop];
  }
  
  return [NSString stringWithFormat:@"%@%@", gameDashboardBaseURLString, gameDashBoadPathAddParamsUrl];
}

- (NSString*)dashboardPathString:(NSString*)pathString appId:(NSString*)appId userId:(NSString*)userId
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

- (NSString*)createGameDashboardUrlParams:(NSString*)appId userId:(NSString*)userId
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

- (void)launchDashboardWithPath:(NSString*)path completion:(void (^)(id))completion
{
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
  
  [self launchDashboardWithBaseURL:URL completion:completion];
}

- (void)launchDashboardWithBaseURL:(NSURL*)URL completion:(void (^)(id))completion
{
  if (self.currentDashboard != nil) {
    GreeLogWarn(@"Already launched the dashboard");
    return;
  }
  
  if (URL == nil) {
    GreeLogWarn(@"Cannot launch the dashboard without a base URL");
    return;
  }
  
  GreeDashboardViewController *dashboard = [[GreeDashboardViewController alloc] initWithBaseURL:URL];  
  _originalStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
  
  
  dashboard.dashboardDelegate = (id<GreeDashboardViewControllerDelegate>)self;
  self.currentDashboard = dashboard;
  
  [self.hostViewController presentViewController:self.currentDashboard animated:YES completion:nil];
  self.completion = completion;
  
  GreeAnalyticsEvent *event = [GreeAnalyticsEvent
                               eventWithType:@"pg"
                               name:[GreeDashboardLauncher viewNameFromURL:URL]
                               from:@"game"
                               parameters:[[URL query] greeDictionaryFromQueryString]];
  
  [[GreePlatform sharedInstance] addAnalyticsEvent:event];
  [dashboard release];
}

- (void)dismissDashboard
{
  [self dismissDashboardWithResults:nil];
}

- (void)dismissDashboardWithResults:(id)results
{
  if (self.currentDashboard) {
    [[UIApplication sharedApplication] setStatusBarStyle:_originalStatusBarStyle animated:YES];
    [self.hostViewController dismissViewControllerAnimated:YES completion:nil];
      
    GreeDashboardViewController *dashboard = (GreeDashboardViewController*)self.currentDashboard;
    NSAssert([dashboard isKindOfClass:[GreeDashboardViewController class]], @"Expecting an instance of GreeDashboardViewController");
    
    NSURL *fromURL = [GreeDashboardLauncher URLFromMenuViewController:dashboard.rootViewController];
    GreeAnalyticsEvent *event = [GreeAnalyticsEvent
                                 eventWithType:@"pg"
                                 name:@"game"
                                 from:[GreeDashboardLauncher viewNameFromURL:fromURL]
                                 parameters:nil];
    
    [[GreePlatform sharedInstance] addAnalyticsEvent:event];
  }
  
  [[NSNotificationCenter defaultCenter]
   postNotificationName:GreeNSNotificationKeyDidCloseNotification
   object:self
   userInfo:results];
  
  if (self.completion) {
    self.completion(results);
  }
  self.currentDashboard = nil;
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

#pragma mark - NSObject Overrides

- (NSString*)description
{  
  return [NSString stringWithFormat:@"<%@:%p, showingViewController:%@ completionIsSet:%@>",
          NSStringFromClass([self class]),
          self,
          self.currentDashboard == nil ? @"NO" : @"YES",
          (_completion != nil) ? @"YES" : @"NO"];
}

@end
