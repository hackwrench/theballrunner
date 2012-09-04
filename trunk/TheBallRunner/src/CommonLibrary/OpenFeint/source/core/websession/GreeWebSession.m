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

#import "GreeHTTPClient.h"
#import "GreeSettings.h"
#import "NSHTTPCookieStorage+GreeAdditions.h"
#import "GreePlatform+Internal.h"
#import "GreeError+Internal.h"
#import "GreeWebSession.h"
#import "AFNetworking.h"

static NSString* const GreeWebSessionDidUpdateNotification = @"GreeWebSessionDidUpdateNotification";

static const char touchsession[] = "tns`dn_lk`ec"; // encoded touchsession
static const char gssid[] = "grqf`"; // encoded touchsession

@interface NSString (WebSessionAdditions)
- (BOOL)isSandbox;
@end

@implementation NSString (WebSessionAdditions)

- (BOOL)isSandbox
{
  return ([self isEqualToString:GreeDevelopmentModeSandbox]
          || [self isEqualToString:GreeDevelopmentModeStagingSandbox]
          || [self isEqualToString:GreeDevelopmentModeDevelopSandbox]) ? YES : NO;
}

@end

@implementation GreeWebSession

+ (id)s:(const char *)encoded
{
  int n = strlen(encoded);
	
  char *bf = (char *)malloc(n + 1);
  strncpy(bf, encoded, n);
  int i;
  for (i = 0; i < n; i++) {
    *(bf + i) += i;
  }
  bf[n] = 0;
  NSString *servicename = [NSString stringWithCString:bf encoding:NSUTF8StringEncoding];
  free(bf);
  
  return servicename;
}

+ (id)observeWebSessionChangesWithBlock:(void(^)(void))block
{
  id handle = nil;

  if (block != nil) {
    handle = [[NSNotificationCenter defaultCenter] 
      addObserverForName:GreeWebSessionDidUpdateNotification 
      object:nil 
      queue:nil 
      usingBlock:^(NSNotification* note) {
        block();
      }];
  }
  
  return handle;
}

+ (void)stopObservingWebSessionChanges:(id)handle
{
  if (handle != nil) {
    [[NSNotificationCenter defaultCenter] removeObserver:handle name:GreeWebSessionDidUpdateNotification object:nil];
  }
}

+ (void)regenerateWebSessionWithBlock:(void(^)(NSError* error))block
{
  NSString *endpoint = [NSString stringWithFormat:@"/api/rest/%@/@%@/@%@", [self s:touchsession], @"me", @"self"];
  GreeHTTPClient *httpClient = [GreePlatform sharedInstance].httpClient;
  
  [httpClient 
    getPath:endpoint
    parameters:nil 
    success:^(GreeAFHTTPRequestOperation* operation, id responseObject) {
      id entry = [responseObject objectForKey:@"entry"];
      if (entry) {
        NSString* sgssid = [self s:gssid];
        id value = [entry objectForKey:sgssid];
        if (value && ![value isEqualToString:sgssid]) {
          NSString *greeDomain = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlDomain];
          NSString *developmentMode = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingDevelopmentMode];
          if ([developmentMode isSandbox]) {
            sgssid = @"gssid_smsandbox";
          }

          [NSHTTPCookieStorage greeSetCookie:value forName:sgssid domain:greeDomain];
          if ([developmentMode isEqualToString:GreeDevelopmentModeDevelop]) {
            [NSHTTPCookieStorage greeSetCookie:value forName:sgssid domain:@"gree.jp"];
          }
          
          [[NSNotificationCenter defaultCenter] postNotificationName:GreeWebSessionDidUpdateNotification object:nil];
          if (block) {
            block(nil);
          }
        } 
      } else {
        NSError* error = [[[NSError alloc] 
          initWithDomain:GreeErrorDomain 
          code:GreeErrorCodeWebSessionResponseUnrecognized 
          userInfo:nil] autorelease];
        if (block) {
          block(error);
        }
      }
    }
    failure:^(GreeAFHTTPRequestOperation* operation, NSError* error) {
      if(operation.response.statusCode == 401) {
        error = [[[NSError alloc] 
          initWithDomain:GreeErrorDomain 
          code:GreeErrorCodeWebSessionNeedReAuthorize 
          userInfo:nil] autorelease];
      }
      if (block) {
        block([GreeError convertToGreeError:error]);
      }
    }];
}

+ (BOOL)hasWebSession
{
  NSString *greeDomain = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingServerUrlDomain];
  NSString *developmentMode = [[GreePlatform sharedInstance].settings stringValueForSetting:GreeSettingDevelopmentMode];
  NSString* sgssid = [self s:gssid];
  if ([developmentMode isSandbox]) {
    sgssid = @"gssid_smsandbox";
  }
  
  NSString* value = [NSHTTPCookieStorage greeGetCookieValueWithName:sgssid domain:greeDomain];
  return (value) ? YES : NO;
}

@end
