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

#import "GreeBadgeValues.h"
#import "GreeSerializer.h"
#import "GreePlatform+Internal.h"
#import "GreeHTTPClient.h"
#import "GreeError+Internal.h"
#import "GreeSerializable.h"


NSString* const GreeBadgeValuesDidUpdateNotification = @"GreeBadgeValuesDidUpdateNotification";

@interface GreeBadgeValues () <GreeSerializable>
@end

@implementation GreeBadgeValues

@synthesize socialNetworkingServiceBadgeCount = _socialNetworkingServiceBadgeCount;
@synthesize applicationBadgeCount = _applicationBadgeCount;

- (id)initWithSocialNetworkingServiceBadgeCount:(NSInteger)socialNetworkingServiceBadgeCount
  applicationBadgeCount:(NSInteger)applicationBadgeCount {
  if ((self = [super init])) {
    _socialNetworkingServiceBadgeCount = socialNetworkingServiceBadgeCount;
    _applicationBadgeCount = applicationBadgeCount;
  }
  
  return self;
}

- (id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  return [self initWithSocialNetworkingServiceBadgeCount:[serializer integerForKey:@"sns"]
    applicationBadgeCount:[serializer integerForKey:@"app"]];
}

- (void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
  [serializer serializeInteger:_socialNetworkingServiceBadgeCount forKey:@"sns"];
  [serializer serializeInteger:_applicationBadgeCount forKey:@"app"];
}

#pragma mark - NSObject Overrides

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, sns:%d, app:%d>",
    NSStringFromClass([self class]),
    self,
    _socialNetworkingServiceBadgeCount,
    _applicationBadgeCount];
}

#pragma mark - Public Interface

+ (void)loadBadgeValuesWithPath:(NSString*)path block:(void(^)(GreeBadgeValues* badgeValues, NSError* error))block;
{
  if (!block) {
    return;
  }
  
  [[GreePlatform sharedInstance].httpClient
      getPath:path
      parameters:nil 
      success:^(GreeAFHTTPRequestOperation *operation, id responseObject){
        GreeSerializer *serializer = [GreeSerializer deserializerWithDictionary:responseObject];
        GreeBadgeValues* badgeValues = [serializer objectOfClass:[GreeBadgeValues class] forKey:@"entry"];
        [[NSNotificationCenter defaultCenter]
          postNotificationName:GreeBadgeValuesDidUpdateNotification
          object:badgeValues];
        block(badgeValues, nil);
      }
   
      failure:^(GreeAFHTTPRequestOperation *operation, NSError *error){
        block(nil, [GreeError convertToGreeError:error]);
      }];
}

+ (void)loadBadgeValuesForCurrentApplicationWithBlock:(void(^)(GreeBadgeValues* badgeValues, NSError* error))block
{
  [self loadBadgeValuesWithPath:@"/api/rest/badge/@app/@self" block:block];
}

+ (void)loadBadgeValuesForAllApplicationsWithBlock:(void(^)(GreeBadgeValues* badgeValues, NSError* error))block
{
  [self loadBadgeValuesWithPath:@"/api/rest/badge/@app/@all" block:block];
}

+ (void)resetBadgeValues {
  GreeBadgeValues *badgeValues = [[GreeBadgeValues alloc]
    initWithSocialNetworkingServiceBadgeCount:0
    applicationBadgeCount:0];
  [[NSNotificationCenter defaultCenter] postNotificationName:GreeBadgeValuesDidUpdateNotification object:badgeValues];
  [badgeValues release];
}

@end
