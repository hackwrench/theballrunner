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

#import "GreeJSGetLocalNotificationEnabled.h"
#import "GreePlatform.h"
#import "GreeLocalNotification+Internal.h"

#define kGreeJSGetLocalNotificationEnabledCallbackFunction @"callback"

@implementation GreeJSGetLocalNotificationEnabled

#pragma mark - Public Interface

+ (NSString *)name
{
  return @"get_local_notification_enabled";
}

- (void)execute:(NSDictionary *)params
{
  
  NSDictionary *callbackParameters = [NSMutableDictionary dictionary];
  if([GreePlatform sharedInstance].localNotification.localNotificationsEnabled)[callbackParameters setValue:@"true" forKey:@"enabled"];
  else [callbackParameters setValue:@"false" forKey:@"enabled"];
  
  [[self.environment handler]
   callback:[params objectForKey:kGreeJSGetLocalNotificationEnabledCallbackFunction]
   params:callbackParameters];
  
}

- (NSString*)description
{  
  return [NSString stringWithFormat:@"<%@:%p>",
          NSStringFromClass([self class]),
          self];
}

@end
