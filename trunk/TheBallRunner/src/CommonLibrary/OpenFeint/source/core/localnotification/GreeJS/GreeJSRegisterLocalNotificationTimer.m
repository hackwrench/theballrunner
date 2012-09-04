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

#import "GreeJSRegisterLocalNotificationTimer.h"
#import "GreeLocalNotification.h"

#define kGreeJSRegisterLocalNotificationTimerCallbackFunction @"callback"

@implementation GreeJSRegisterLocalNotificationTimer

#pragma mark - Public Interface

+ (NSString *)name
{
  return @"register_local_notification_timer";
}

- (void)execute:(NSDictionary *)params
{
  
  NSDictionary *callbackParam = [params objectForKey:@"callbackParam"];
  NSString *notifyId = [params objectForKey:@"notifyId"];
  NSString *interval = [params objectForKey:@"interval"];
  NSString *message = [params objectForKey:@"message"];
  
  NSDictionary *aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                               message, @"message",
                               [NSDate dateWithTimeIntervalSinceNow:[interval doubleValue]], @"interval", 
                               notifyId, @"notifyId",
                               callbackParam, @"callbackParam",
                               nil];
  BOOL isRegistered = NO;
  isRegistered = [[GreePlatform sharedInstance].localNotification registerLocalNotificationWithDictionary:aDictionary];

  NSDictionary *callbackParameters = [NSMutableDictionary dictionary];
  if(isRegistered)[callbackParameters setValue:@"registered" forKey:@"result"];
  else [callbackParameters setValue:@"error" forKey:@"result"];

  [[self.environment handler]
   callback:[params objectForKey:kGreeJSRegisterLocalNotificationTimerCallbackFunction]
   params:callbackParameters];

}

- (NSString*)description
{  
  return [NSString stringWithFormat:@"<%@:%p>",
          NSStringFromClass([self class]),
          self];
}

@end
