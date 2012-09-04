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

#include <sys/sysctl.h>

#import <UIKit/UIKit.h>
#import "GreeAnalyticsHeader.h"
#import "GreePlatform.h"

@interface GreeAnalyticsHeader ()
+ (NSString*)hardwareVersion;
@end

@implementation GreeAnalyticsHeader

@synthesize hardwareVersion = _hardwareVersion;
@synthesize bundleVersion = _bundleVersion;
@synthesize sdkVersion = _sdkVersion;
@synthesize osVersion = _osVersion;
@synthesize localeCountryCode = _localeCountryCode;

#pragma mark - Object Lifecycle

+ (id)header
{
  NSString *hardwareVersion = [self hardwareVersion];
  NSString *bundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
  NSString *sdkVersion = [GreePlatform version];
  NSString *osVersion = [NSString stringWithFormat:@"%@ %@", [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]];
  NSString *localeCountryCode = [[NSLocale currentLocale] localeIdentifier];
  
  return [[[GreeAnalyticsHeader alloc] initWithHardwareVersion:hardwareVersion
    bundleVersion:bundleVersion
    sdkVersion:sdkVersion
    osVersion:osVersion
    localCountryCode:localeCountryCode] autorelease];
}

- (id)initWithHardwareVersion:(NSString*)hardwareVersion
    bundleVersion:(NSString*)bundleVersion
    sdkVersion:(NSString*)sdkVersion
    osVersion:(NSString*)osVersion
    localCountryCode:(NSString*)localeCountryCode
{
  if ((self = [super init])) {
    _hardwareVersion = [hardwareVersion retain];
    _bundleVersion = [bundleVersion retain];
    _sdkVersion = [sdkVersion retain];
    _osVersion = [osVersion retain];
    _localeCountryCode = [localeCountryCode retain];
  }
  
  return self;
}

- (void)dealloc
{
  [_hardwareVersion release];
  [_bundleVersion release];
  [_sdkVersion release];
  [_osVersion release];
  [_localeCountryCode release];

  [super dealloc];
}

#pragma mark - GreeSerializer Protocol

- (id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  if((self = [super init])) {
    _hardwareVersion = [[serializer objectForKey:@"hv"] retain];
    _bundleVersion = [[serializer objectForKey:@"bv"] retain];
    _sdkVersion = [[serializer objectForKey:@"sv"] retain];
    _osVersion = [[serializer objectForKey:@"ov"] retain];
    _localeCountryCode = [[serializer objectForKey:@"lc"] retain];
  }
  return self;
}

- (void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
  [serializer serializeObject:_hardwareVersion forKey:@"hv"];
  [serializer serializeObject:_bundleVersion forKey:@"bv"];
  [serializer serializeObject:_sdkVersion forKey:@"sv"];
  [serializer serializeObject:_osVersion forKey:@"ov"];
  [serializer serializeObject:_localeCountryCode forKey:@"lc"];
}

#pragma mark - NSObject Overrides
- (NSString*)description
{  
  return [NSString stringWithFormat:@"<%@:%p, hardwareVersion:%@, bundleVersion:%@, sdkVersion:%@, osVersion:%@, localeCountryCode:%@>",
      NSStringFromClass([self class]),
      self,
      self.hardwareVersion,
      self.bundleVersion,
      self.sdkVersion,
      self.osVersion,
      self.localeCountryCode];
}

#pragma mark - Interval methods
+ (NSString*)hardwareVersion
{
  size_t size;
  sysctlbyname("hw.machine", NULL, &size, NULL, 0);

  char *machine = malloc(size);
  sysctlbyname("hw.machine", machine, &size, NULL, 0);
  
  NSString *hardwareVersion = [NSString stringWithUTF8String:machine];
  free(machine);
  
  return hardwareVersion;
}
@end
