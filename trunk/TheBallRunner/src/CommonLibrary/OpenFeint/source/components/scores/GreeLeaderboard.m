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

#import "GreeLeaderboard.h"
#import "GreeEnumerator+Internal.h"
#import "GreeSerializer.h"
#import "GreeHTTPClient.h"
#import "GreePlatform+Internal.h"
#import "AFNetworking.h"

@interface GreeLeaderboard ()
@property (nonatomic, retain, readwrite) NSString* identifier;
@property (nonatomic, retain, readwrite) NSString* name;
@property (nonatomic, assign, readwrite) GreeLeaderboardFormat format;
@property (nonatomic, retain, readwrite) NSString* formatSuffix;
@property (nonatomic, assign, readwrite) NSInteger formatDecimal;
@property (nonatomic, retain, readwrite) NSURL* iconUrl;
@property (nonatomic, assign, readwrite) GreeLeaderboardSortOrder sortOrder;
@property (nonatomic, assign, readwrite) BOOL allowWorseScore;
@property (nonatomic, assign, readwrite) BOOL isSecret;
@property (nonatomic, assign, readwrite) BOOL status;
@property (nonatomic, retain, readwrite) id handle;
@end

@interface GreeLeaderboardEnumerator : GreeEnumeratorBase
@end

@implementation GreeLeaderboard

@synthesize identifier = _identifier;
@synthesize name = _name;
@synthesize format = _format;
@synthesize formatSuffix = _formatSuffix;
@synthesize formatDecimal = _formatDecimal;
@synthesize iconUrl = _iconUrl;
@synthesize sortOrder = _sortOrder;
@synthesize allowWorseScore = _allowWorseScore;
@synthesize isSecret = _isSecret;
@synthesize status = _status;
@synthesize handle = _handle;

#pragma mark - Object Lifecycle

- (void)dealloc
{
  [_identifier release];
  [_name release];
  [_formatSuffix release];
  [_iconUrl release];
  [_handle release];
  [super dealloc];
}

#pragma mark - Public Interface

+ (id<GreeEnumerator>)loadLeaderboardsWithBlock:(void(^)(NSArray* leaderboards, NSError* error)) block
{
  id<GreeEnumerator> enumerator = [[GreeLeaderboardEnumerator alloc] initWithStartIndex:1 pageSize:0];
  [enumerator loadNext:block];
  return [enumerator autorelease];
}

- (void)loadIconWithBlock:(void(^)(UIImage* image, NSError* error))block
{
  self.handle = [[GreePlatform sharedInstance].httpClient downloadImageAtUrl:self.iconUrl withBlock:block];
}

- (void)cancelIconLoad
{
  [[GreePlatform sharedInstance].httpClient cancelWithHandle:self.handle];
}

#pragma mark - GreeSerializable Protocol

- (id)initWithGreeSerializer:(GreeSerializer *)serializer
{
  self = [super init];
  if(self) {
    _identifier = [[serializer objectForKey:@"id"] retain];
    _name = [[serializer objectForKey:@"name"] retain];
    _format = [serializer integerForKey:@"format"];
    _formatSuffix = [[serializer objectForKey:@"format_suffix"] retain];
    _formatDecimal = [serializer integerForKey:@"format_decimal"];
    _iconUrl = [[serializer urlForKey:@"thumbnail_url"] retain];
    _sortOrder = [serializer integerForKey:@"sort"];
    _allowWorseScore = [serializer boolForKey:@"allow_worse_score"];
    _isSecret = [serializer boolForKey:@"secret"];
    _status = [serializer boolForKey:@"status"];
  }
  return self;
}

- (void)serializeWithGreeSerializer:(GreeSerializer *)serializer
{
  [serializer serializeObject:_identifier forKey:@"id"];
  [serializer serializeObject:_name forKey:@"name"];
  [serializer serializeInteger:_format forKey:@"format"];
  [serializer serializeObject:_formatSuffix forKey:@"format_suffix"];
  [serializer serializeInteger:_formatDecimal forKey:@"format_decimal"];
  [serializer serializeUrl:_iconUrl forKey:@"thumbnail_url"];
  [serializer serializeInteger:_sortOrder forKey:@"sort"];
  [serializer serializeBool:_allowWorseScore forKey:@"allow_worse_score"];
  [serializer serializeBool:_isSecret forKey:@"secret"];
  [serializer serializeBool:_status forKey:@"status"];
}

#pragma mark - NSObject Overrides

- (NSString*)description
{
#define PRINTBOOL(x) x ? @"YES" : @"NO"
  
  const static NSString* sortOrderTitles[2] =  { @"Descending", @"Ascending" };
  const static NSString* formatTitles[] =  { @"Integer", @"Unknown", @"Time" };
  return [NSString stringWithFormat:@"<%@:%p, identifier:%@, name:%@, "
          "format:%d[%@], formatSuffix:%@, formatDecimal:%d, "
          "iconUrl:%@, sortOrder:%d[%@], "
          "allowWorseScore:%@, isSecret:%@>", 
          NSStringFromClass([self class]), self, self.identifier, self.name, 
          self.format, formatTitles[self.format > 2 ? 0 : self.format], self.formatSuffix, self.formatDecimal,
          self.iconUrl, self.sortOrder, sortOrderTitles[self.sortOrder > 1 ? 0 : self.sortOrder],
          PRINTBOOL(self.allowWorseScore), PRINTBOOL(self.isSecret)];
}

#pragma mark - Internal Methods

@end

@implementation GreeLeaderboardEnumerator

- (NSString*)httpRequestPath
{
  return @"api/rest/sgpleaderboard/@me/@app";
}

- (NSArray*)convertData:(NSArray*)input
{
  return [GreeSerializer deserializeArray:input withClass:[GreeLeaderboard class]];
}

@end
