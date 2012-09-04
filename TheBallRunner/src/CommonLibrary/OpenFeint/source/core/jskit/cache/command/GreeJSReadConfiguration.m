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


#import "GreeJSCommandFactory.h"
#import "GreeWebAppCache.h"

@interface GreeJSReadConfigurationCommand : GreeJSCommand
@end

@implementation GreeJSReadConfigurationCommand

#pragma mark - GreeJSCommand Overrides

+ (NSString *)name
{
  return @"readConfiguration";
}

- (void)execute:(NSDictionary *)params
{
  NSString *appName = [params objectForKey:@"app"];
  if ([appName length] <= 0) {
    NSLog(@"%@ command requires app parameter", [[self class] name]);
    return;
  }
  GreeWebAppCache *appCache = [GreeWebAppCache appCacheForName:appName];

  self.result = [NSDictionary dictionaryWithObjectsAndKeys:
                @"ios",  @"platform",
                [appCache.baseURL absoluteString],  @"baseURL",
                [NSNumber numberWithUnsignedInteger:appCache.versionOfCachedContent ],  @"cache_version",
                [NSNumber numberWithUnsignedInteger:appCache.synchronized],  @"cache_synchronized",
                [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithBool:YES], @"cache",
                nil], @"supports",
                nil];
}
@end
