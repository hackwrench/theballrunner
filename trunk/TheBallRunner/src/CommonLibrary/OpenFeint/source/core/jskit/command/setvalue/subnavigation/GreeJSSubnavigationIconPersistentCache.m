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

#import "GreeJSSubnavigationIconPersistentCache.h"

static inline NSString * imageCacheKeyFromURLAndCacheName(NSURL *url, NSString *cacheName) {
  return [[url absoluteString] stringByAppendingFormat:@"#%@", cacheName];
}

@interface GreeJSSubnavigationIconPersistentCache ()
@property (nonatomic, readwrite, retain) NSString *cacheDirectory;
@end

@implementation GreeJSSubnavigationIconPersistentCache

@synthesize cacheDirectory = _cacheDirectory;

#pragma mark -
#pragma mark Object Lifecycle

- (id)init
{
  if ((self = [super init])) {
    NSArray *pathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    self.cacheDirectory = [NSString stringWithFormat:@"%@/subnavicons", [pathList lastObject]];
    [[NSFileManager defaultManager] createDirectoryAtPath:_cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
  }
  return self;
}

- (void)dealloc
{
  [_cacheDirectory release];
  [super dealloc];
}

#pragma mark Internal Methods
- (NSString*)filenameForCacheKey:(NSString*)key
{
  return [NSString stringWithFormat:@"%@/%u", _cacheDirectory, [key hash]];
}

- (NSData*)retrieveCacheContentForKey:(NSString*)key
{
  NSString* filename = [self filenameForCacheKey:key];
  if ([[NSFileManager defaultManager] fileExistsAtPath:filename] == NO) {
    return nil;
  }
  
  return [NSData dataWithContentsOfFile:filename];
}

#pragma mark Public Interface

+ (id)sharedImageCache {
  static id _sharedImageCache = nil;
  static dispatch_once_t oncePredicate;
  dispatch_once(&oncePredicate, ^{
    _sharedImageCache = [[self alloc] init];
  });
  return _sharedImageCache;
}

- (void)clearCache
{
  [self clearMemoryCache];
  [self clearDiskCache];
}

- (void)clearMemoryCache
{
  [self removeAllObjects];
}

- (void)clearDiskCache
{
  NSFileManager* fm = [NSFileManager defaultManager];
  NSDirectoryEnumerator* en = [fm enumeratorAtPath:self.cacheDirectory];    
  
  NSError* err = nil;
  NSString* file;
  while (file = [en nextObject]) {
    [fm removeItemAtPath:[self.cacheDirectory stringByAppendingPathComponent:file] error:&err];
  }
}


#pragma mark AFImageCache Overrides

- (UIImage *)cachedImageForURL:(NSURL *)url cacheName:(NSString *)cacheName
{
  UIImage *image = [super cachedImageForURL:url cacheName:cacheName];
  if (image) {
    return image;
  }

  NSString* key = imageCacheKeyFromURLAndCacheName(url, cacheName);
  NSData* data = [self retrieveCacheContentForKey:key];
  if (data) {
    image = [UIImage imageWithData:data];
    if (image) {
      [super cacheImageData:data forURL:url cacheName:cacheName];
    }
  }
  return image;
}

- (void)cacheImageData:(NSData *)imageData forURL:(NSURL *)url cacheName:(NSString *)cacheName
{
  NSString* key = imageCacheKeyFromURLAndCacheName(url, cacheName);
  NSString* filename = [self filenameForCacheKey:key];
  [imageData writeToFile:filename atomically:YES];

  [super cacheImageData:imageData forURL:url cacheName:cacheName];
}
@end

