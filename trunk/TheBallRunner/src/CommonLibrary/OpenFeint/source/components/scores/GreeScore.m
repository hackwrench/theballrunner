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

#import "GreeScore.h"
#import "GreeSerializer.h"
#import "GreeEnumerator+Internal.h"
#import "GreeHTTPClient.h"
#import "GreePlatform+Internal.h"
#import "NSString+GreeAdditions.h"
#import "GreeError+Internal.h"
#import "GreeWriteCache.h"
#import "GreeNetworkReachability.h"
#import "GreeSettings.h"
#import "GreeUser+Internal.h"
#import "GreeGlobalization.h"
#import "GreeLeaderboard.h"
#import <GameKit/GameKit.h>
#import "AFNetworking.h"

int64_t GreeScoreUnranked = INT64_MIN;

@interface GreeScore ()
@property (nonatomic, retain, readwrite) GreeUser* user;
@property (nonatomic, retain, readwrite) NSString* leaderboardId;
@property (nonatomic, retain, readwrite) NSString* formattedScore;
@property (nonatomic, assign, readwrite) int64_t rank;
@property (nonatomic, copy, readwrite) void(^gameCenterResponseBlock)(NSError*);
- (GKScore*)gameCenterScore;
@end

@interface GreeScoreEnumerator : GreeEnumeratorBase
@property (nonatomic, retain) NSString* leaderboardId;
@property (nonatomic, assign) GreeScoreTimePeriod timePeriod;
@property (nonatomic, assign) GreePeopleScope peopleScope;
- (id)initWithLeaderboardId:(NSString*)leaderboardId 
  timePeriod:(GreeScoreTimePeriod)timePeriod 
  peopleScope:(GreePeopleScope)peopleScope;
@end

@implementation GreeScore

@synthesize user = _user;
@synthesize leaderboardId = _leaderboardId;
@synthesize score = _score;
@synthesize formattedScore = _formattedScore;
@synthesize rank = _rank;
@synthesize gameCenterResponseBlock = _gameCenterResponseBlock;

#pragma mark - Object Lifecycle

- (id)initWithLeaderboard:(NSString*)leaderboardId score:(int64_t)score
{
  self = [super init];
  if (self != nil) {
    _user = [[GreePlatform sharedInstance].localUser retain];
    _leaderboardId = [leaderboardId retain];
    _score = score;
    _rank = GreeScoreUnranked;

    if ([leaderboardId length] == 0) {
      [self release];
      self = nil;
    }
  }
  
  return self;
}

- (void)dealloc
{
  [_user release];
  [_leaderboardId release];
  [_gameCenterResponseBlock release];
  [_formattedScore release];
  [super dealloc];
}

#pragma mark - Public Interface
+ (void)loadMyScoreForLeaderboard:(NSString*)leaderboardId 
  timePeriod:(GreeScoreTimePeriod)timePeriod 
  block:(void(^)(GreeScore* score, NSError* error))block;
{
  if (!block) {
    return;
  }
  id<GreeEnumerator> enumerator = [[GreeScoreEnumerator alloc] initWithLeaderboardId:leaderboardId timePeriod:timePeriod peopleScope:GreePeopleScopeSelf];
  [enumerator loadNext:^(NSArray* items, NSError* error) {
    block([items objectAtIndex:0], error);
  }];
  [enumerator autorelease];
}

+ (id<GreeEnumerator>)loadTopScoresForLeaderboard:(NSString*)leaderboardId 
  timePeriod:(GreeScoreTimePeriod)timePeriod 
  block:(void(^)(NSArray* scoreList, NSError* error))block
{
  id<GreeEnumerator> enumerator = [[GreeScoreEnumerator alloc] initWithLeaderboardId:leaderboardId timePeriod:timePeriod peopleScope:GreePeopleScopeAll];
  [enumerator loadNext:block];
  return [enumerator autorelease];
}

+ (id<GreeEnumerator>)loadTopFriendScoresForLeaderboard:(NSString*)leaderboardId 
  timePeriod:(GreeScoreTimePeriod)timePeriod 
  block:(void(^)(NSArray* scoreList, NSError* error))block
{
  id<GreeEnumerator> enumerator = [[GreeScoreEnumerator alloc] initWithLeaderboardId:leaderboardId timePeriod:timePeriod peopleScope:GreePeopleScopeFriends];
  [enumerator loadNext:block];
  return [enumerator autorelease];
}

+ (GreeScoreEnumerator*)scoreEnumeratorForLeaderboard:(NSString*)leaderboardId 
  timePeriod:(GreeScoreTimePeriod)timePeriod 
  peopleScope:(GreePeopleScope)peopleScope
{
  return [[[GreeScoreEnumerator alloc] initWithLeaderboardId:leaderboardId timePeriod:timePeriod peopleScope:peopleScope] autorelease];
}

- (void)submitWithBlock:(void(^)(void))block
{
  [[self gameCenterScore] reportScoreWithCompletionHandler:self.gameCenterResponseBlock];
  
  GreeWriteCache* cache = [[GreePlatform sharedInstance] writeCache];
  GreeWriteCacheOperationHandle handleToObserve = [cache writeObject:self];
  if ([[[GreePlatform sharedInstance] reachability] isConnectedToInternet]) {
    handleToObserve = [cache commitAllObjectsOfClass:[self class] inCategory:[self writeCacheCategory]];
  }

  if (block) {
    [[[GreePlatform sharedInstance] writeCache] observeWriteCacheOperation:handleToObserve forCompletionWithBlock:block];
  }
}

+ (void)deleteMyScoreForLeaderboard:(NSString*)leaderboardId withBlock:(void(^)(NSError*error))block
{
  [[[GreePlatform sharedInstance] writeCache] deleteAllObjectsOfClass:[GreeScore class] inCategory:leaderboardId];
  
  void(^successBlock)(GreeAFHTTPRequestOperation *operation, id responseObject) = ^(GreeAFHTTPRequestOperation *operation, id responseObject) {
    if (block) {
      block(nil);
    }
  };
  void(^failureBlock)(GreeAFHTTPRequestOperation *op, NSError *error) = ^(GreeAFHTTPRequestOperation *op, NSError *error){
    if(block) {
      block([GreeError convertToGreeError:error]);
    }
  };

  [[GreePlatform sharedInstance].httpClient 
    encodedDeletePath:@"api/rest/sgpscore/@me/@self/@app/" 
    parameters:[NSDictionary dictionaryWithObject:leaderboardId forKey:@"category"] 
    success:successBlock
    failure:^(GreeAFHTTPRequestOperation *operation, NSError *error) {
      failureBlock(nil, error);
    }];
}

- (NSString*)formattedScoreWithLeaderboard:(GreeLeaderboard*)leaderboard
{
  NSString* formattedScore = self.formattedScore;
  if (![formattedScore length]) {
    formattedScore = [NSString stringWithFormat:@"%lld", self.score];
  }

  if (leaderboard != nil && leaderboard.format != GreeLeaderboardFormatTime) {
    NSString* formatString = GreePlatformStringWithComment(@"GreeScore.formattedScoreWithLeaderboard.formatString", @"%1$@ %2$@", @"First field is the score value, Second field is the format suffix");
    formattedScore = [NSString stringWithFormat:formatString, formattedScore, leaderboard.formatSuffix];
  }
  
  return formattedScore;
}

#pragma mark - GreeWriteCacheable Protocol

- (NSString*)writeCacheCategory
{
  return self.leaderboardId;
}

+ (NSInteger)writeCacheMaxCategorySize
{
  return 20;
}

- (void)writeCacheCommitAndExecuteBlock:(void(^)(BOOL commitDidSucceed))block
{
  NSString* path = @"api/rest/sgpscore/@me/@self/@app/";
  NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
  NSString* userId = [GreePlatform sharedInstance].localUserId;
  NSString* scoreString = [NSString stringWithFormat:@"%lld", self.score];
  [parameters addEntriesFromDictionary:[scoreString greeHashWithNonceAndKeyPrefix:userId]];
  [parameters setObject:scoreString forKey:@"score"];
  [parameters setObject:self.leaderboardId forKey:@"category"];
  [[GreePlatform sharedInstance].httpClient 
    postPath:path 
    parameters:parameters 
    success:^(GreeAFHTTPRequestOperation *operation, id responseObject) {
      if(block) {
        block(YES);
      }
    }
    failure:^(GreeAFHTTPRequestOperation *operation, NSError *error) {
      if(block) {
        block(NO);
      }
    }];
}

#pragma mark - GreeSerializable Protocol

- (id)initWithGreeSerializer:(GreeSerializer *)serializer
{
  self = [super init];
  if (self != nil) {
    _user = [[GreeUser alloc] initWithGreeSerializer:serializer];

    id scoreObject = [serializer objectForKey:@"score"];
    if ([scoreObject isKindOfClass:[NSString class]]) {
      _formattedScore = [scoreObject retain];
    }

    if (![_formattedScore length]) {
      _score = [serializer int64ForKey:@"integralScore"];
    } else {
      NSRange colonRange = [_formattedScore rangeOfString:@":"];
      if (colonRange.location != NSNotFound) {
        NSArray* components = [_formattedScore componentsSeparatedByString:@":"];
        if ([components count] == 3) {
          _score = [[components objectAtIndex:2] longLongValue];
          _score += [[components objectAtIndex:1] longLongValue] * 60;
          _score += [[components objectAtIndex:0] longLongValue] * 60 * 60;
        }
      } else {
        _score = [_formattedScore longLongValue];
      }
    }

    _rank = [serializer int64ForKey:@"rank"];
    _leaderboardId = [[serializer objectForKey:@"leaderboardId"] retain];
  }
  return self;
}

- (void)serializeWithGreeSerializer:(GreeSerializer *)serializer
{
  [serializer serializeObject:_user.userId forKey:@"id"];
  [serializer serializeObject:_user.nickname forKey:@"nickname"];
  [serializer serializeObject:[_user.thumbnailUrlHuge absoluteString] forKey:@"thumbnailUrlHuge"];
  [serializer serializeInt64:_score forKey:@"integralScore"];
  if ([_formattedScore length]) {
    [serializer serializeObject:_formattedScore forKey:@"score"];
  }
  [serializer serializeInt64:_rank forKey:@"rank"];
  [serializer serializeObject:_leaderboardId forKey:@"leaderboardId"];
}

#pragma mark - NSObject Overrides

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, userId:%@, score:%lld, formattedScore:%@, leaderboardId:%@, rank:%lld, userNickName:%@, thumbnailUrlHuge:%@>", 
          NSStringFromClass([self class]), self, self.user.userId, self.score, self.formattedScore, self.leaderboardId, self.rank, self.user.nickname, self.user.thumbnailUrlHuge];
}

#pragma mark - Internal Methods

- (GKScore*)gameCenterScore
{
  GKScore* score = nil;
  
  NSDictionary* gameCenterMapping = [[[GreePlatform sharedInstance] settings] objectValueForSetting:GreeSettingGameCenterLeaderboardMapping];
  NSString* gameCenterIdentifier = [gameCenterMapping objectForKey:self.leaderboardId];
  if ([gameCenterIdentifier length] > 0) {
    score = [[[GKScore alloc] initWithCategory:gameCenterIdentifier] autorelease];
    score.value = self.score;
  }

  return score;
}

@end

#pragma mark - GreeScoreEnumerator

@implementation GreeScoreEnumerator

@synthesize leaderboardId = _leaderboardId;
@synthesize timePeriod = _timePeriod;
@synthesize peopleScope = _peopleScope;

- (id)initWithLeaderboardId:(NSString*)leaderboardId 
  timePeriod:(GreeScoreTimePeriod)timePeriod 
  peopleScope:(GreePeopleScope)peopleScope
{
  self = [super initWithStartIndex:0 pageSize:0];
  if (self != nil) {
    _leaderboardId = [leaderboardId retain];
    _timePeriod = timePeriod;
    _peopleScope = peopleScope;
  }
  return self;
}

- (void)dealloc
{
  [_leaderboardId release];
  [super dealloc];
}

#pragma mark - Internal Methods

- (NSString*)timePeriodToken
{
  switch (self.timePeriod) {
    case GreeScoreTimePeriodDaily:
      return @"daily";
    case GreeScoreTimePeriodWeekly:
      return @"weekly";
    default:
      return @"total";
  }
}

- (NSString*)peopleScopeToken
{
  switch (self.peopleScope) {
    case GreePeopleScopeSelf:
      return @"@self";
    case GreeScoreTimePeriodWeekly:
      return @"@friends";
    default:
      return @"@all";
  }
}

#pragma mark - GreeEnumerator overrides

- (NSString*)httpRequestPath
{
  return [NSString stringWithFormat:@"/api/rest/sgpranking/@me/%@/@app", [self peopleScopeToken]];
}

- (NSArray*)convertData:(NSArray *)input
{
  NSArray* deserialized = [GreeSerializer deserializeArray:input withClass:[GreeScore class]];
  [deserialized enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    if ([obj isKindOfClass:[GreeScore class]]) {
      GreeScore* score = (GreeScore*)obj;
      score.leaderboardId = self.leaderboardId;
    }
  }];

  return deserialized;
}

- (void)updateParams:(NSMutableDictionary *)params
{
  [params setObject:self.leaderboardId forKey:@"category"];
  [params setObject:[self timePeriodToken] forKey:@"period"];
}

@end
