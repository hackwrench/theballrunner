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


#import "GreeJSNotifyServiceResultCommand.h"
#import "GreeLogger.h"
#import "GreePopup.h"
#import "GreePopup+Internal.h"


@interface GreeJSNotifyServiceResultCommand ()
@end


@implementation GreeJSNotifyServiceResultCommand


#pragma mark - GreeJSCommand Overrides

+ (NSString *)name
{
  return @"notify_service_result";
}

- (void)execute:(NSDictionary *)params
{
  NSString* anAction = [params objectForKey:@"action"];
  
  if ([anAction isEqualToString:@"reload"]) {
    GreePopup* popup = (GreePopup*)[self.environment viewControllerForCommand:self];
    [popup reloadWithParameters:params];
  }
}


#pragma mark - NSObject Overrides

- (NSString*)description
{  
  return [NSString stringWithFormat:@"<%@:%p>",
          NSStringFromClass([self class]), self];
}

@end
