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


#import "GreeWebAppCache.h"
#import "GreeJSSyncCommand.h"
#import "GreeJSWebViewMessageEvent.h"

@interface GreeJSSyncCommand ()
-(void)cacheUpdatedNotification:(NSNotification*)notification;
-(void)allFilesUpdatedNotification:(NSNotification*)notification;
@end


@implementation GreeJSSyncCommand
#pragma mark - Object Lifecycle

- (id)init
{
  if ((self = [super init])) {
    updatedFiles_ = [[NSMutableArray alloc] init];
    failedFiles_ = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc
{
  [baseURL_ release];
  [updatedFiles_ release];
  [failedFiles_ release];
  [super dealloc];
}

#pragma mark - GreeJSCommand Overrides

+ (NSString *)name
{
  return @"sync";
}

- (void)execute:(NSDictionary *)params
{
  // create manifest object if does not exist
  NSString *appName = [params objectForKey:@"app"];
  NSString *versionString = [params objectForKey:@"version"];
  long long version = [versionString longLongValue];

  NSArray *files = [params objectForKey:@"files"];
  if ([appName length] <= 0) {
    NSLog(@"sync command requires app parameter");
    return;
  }

  NSString *href = [[self.environment webviewForCommand:self] 
    stringByEvaluatingJavaScriptFromString:@"document.location.href.replace(/[^/]+$/,'')"];
  baseURL_ = [[NSURL URLWithString:href] retain];
  GreeWebAppCache *cache = [GreeWebAppCache appCacheForName:appName];
  if (cache == nil) {
    if (baseURL_ == nil) {
      NSLog(@"invalid sync command issued in %@", href);
      return;
    }
    cache = [GreeWebAppCache registerAppCacheForName:appName withBaseURL:baseURL_];
  } else {
    // baseURL cound be nil when command is issued from file:// pages.
    if (baseURL_ == nil) {
      baseURL_ = [cache.baseURL retain];
    }
  }

  int enqueued = 0;
  for (NSDictionary *file in files) {
    if (![file isKindOfClass:[NSDictionary class]]) {
      NSLog(@"sync file description should be an object");
      continue;
    }
    GreeWebAppCacheItem *item = [[[GreeWebAppCacheItem alloc] initWithDictionary:file withBaseURL:baseURL_] autorelease];
    // File is not newer than cached one. skip to update.
    // This situation can be occured in the case the client sent a request without version number.
    long long cachedVersion = [cache versionOfCachedContentForURL:item.url];
    if (item.version <= cachedVersion) {
      [failedFiles_ addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                               [item.url absoluteString], GreeWebAppCacheFileUpdatedNotificationUrlKey,
                               [NSString stringWithFormat:@"Newer version %lld is already in cache", item.version], @"reason",
                               nil]];
      continue;
    }
    
    if ([cache isItemAlreadyInQueue:item]) {
      continue;
    }
    
    if ([cache enqueueItem:item]) {
      ++enqueued;
    }
  }

  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(cacheUpdatedNotification:) name:GreeWebAppCacheFileUpdatedNotification object:cache];
  [center addObserver:self selector:@selector(cacheFailedNotification:) name:GreeWebAppCacheFailedToUpdatNotification object:cache];
  
  [center addObserver:self selector:@selector(allFilesUpdatedNotification:) name:GreeWebAppCacheAllFilesUpdatedNotification object:cache];
  [center addObserver:self selector:@selector(synchronizationCompletedNotification:) name:GreeWebAppCacheSynchronizationCompletedNotification object:cache];

  version_ = version;    

  [cache startSync];
}


#pragma mark - Internal Methods

-(void)cacheUpdatedNotification:(NSNotification*)notification
{
  // values of userInfo should be JSON.stringifiable objects.
  NSMutableDictionary *userInfo = [[notification.userInfo mutableCopy] autorelease];
  [userInfo setObject:[[userInfo objectForKey:GreeWebAppCacheFileUpdatedNotificationUrlKey] absoluteString]
               forKey:GreeWebAppCacheFileUpdatedNotificationUrlKey];
  [GreeJSWebViewMessageEvent postMessageEventName:@"cacheUpdated" object:nil userInfo:userInfo];
  
  [updatedFiles_ addObject:userInfo];
}
-(void)cacheFailedNotification:(NSNotification*)notification
{
  NSMutableDictionary *userInfo = [[notification.userInfo mutableCopy] autorelease];
  [userInfo setObject:[[userInfo objectForKey:GreeWebAppCacheFileUpdatedNotificationUrlKey] absoluteString]
               forKey:GreeWebAppCacheFileUpdatedNotificationUrlKey];
  
  [failedFiles_ addObject:userInfo];
}

-(void)allFilesUpdatedNotification:(NSNotification*)notification
{
  GreeWebAppCache *cache = [notification object];
  NSDictionary *userInfo = notification.userInfo;
  BOOL success = [[userInfo objectForKey:GreeWebAppCacheAllFilesUpdatedNotificationSuccessKey] boolValue];
  if (success) {
    [cache allFilesUpdatedToVersion:version_];
  }
  
  self.result = [NSDictionary dictionaryWithObjectsAndKeys:
                 cache.applicationName, @"app",
                 [baseURL_ absoluteString], @"baseURL",
                 updatedFiles_, @"updated",
                 failedFiles_, @"failed",
                 nil
  ];
  [self callback];
}

@end
