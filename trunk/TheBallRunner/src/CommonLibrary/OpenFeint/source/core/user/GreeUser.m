//
// Copyright 2011 GREE, Inc.
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

#import "GreeUser+Internal.h"
#import "GreePlatform+Internal.h"
#import "GreeHTTPClient.h"
#import "AFNetworking.h"
#import "AFImageRequestOperation.h"
#import "GreeSerializer.h"
#import "GreeEnumerator+Internal.h"
#import "GreeError+Internal.h"
#import "GreeLogger.h"
#import "NSString+GreeAdditions.h"
#import "GreeSettings.h"

static NSString* const kGreeUserDefaultsLocalUserKey = @"GreeUserDefaults.LocalUser";

@interface GreeFriendEnumerator : GreeEnumeratorBase
@end

@interface GreeIgnoredUserIdEnumerator : GreeEnumeratorBase
@end

@interface GreeUser ()
@property(nonatomic, readonly, assign) BOOL hasThisApplication;
@property(nonatomic, readwrite, retain) NSURL* thumbnailUrl;
@property(nonatomic, readwrite, retain) NSURL* thumbnailUrlSmall;
@property(nonatomic, readwrite, retain) NSURL* thumbnailUrlLarge;
@property(nonatomic, readwrite, retain) NSURL* thumbnailUrlHuge;
@property(nonatomic, readwrite, retain) id thumbnailHandle;
@property(nonatomic, readwrite, assign) GreeUserGrade userGrade;
@property(nonatomic, readwrite, retain) NSDate* creationDate;
@property(nonatomic, readwrite, copy) void(^thumbnailCompletionBlock)(UIImage* icon, NSError* error);
- (void)_loadThumbnailWithSize:(GreeUserThumbnailSize)size;
@end

@implementation GreeUser

@synthesize userId = _userId;
@synthesize nickname = _nickname;
@synthesize userGrade =  _userGrade;
@synthesize aboutMe = _aboutMe;
@synthesize birthday = _birthday;
@synthesize gender = _gender;
@synthesize age = _age;
@synthesize bloodType = _bloodType;
@synthesize region =  _region;
@synthesize subRegion =  _subRegion;
@synthesize language =  _language;
@synthesize timeZone =  _timeZone;
@synthesize creationDate = _creationDate;
@synthesize thumbnailCompletionBlock = _thumbnailCompletionBlock;

@synthesize displayName = _displayName;
@synthesize hasThisApplication = _hasThisApplication;
@synthesize userHash = _userHash;
@synthesize userType = _userType;
@synthesize profileUrl = _profileUrl;
@synthesize thumbnailUrl = _thumbnailUrl;
@synthesize thumbnailUrlSmall = _thumbnailUrlSmall;
@synthesize thumbnailUrlLarge = _thumbnailUrlLarge;
@synthesize thumbnailUrlHuge = _thumbnailUrlHuge;
@synthesize thumbnailHandle =  _thumbnailHandle;

#pragma mark - Object Lifecycle

- (void)dealloc
{
  [_userId release];
  [_nickname release];
  [_aboutMe release];
  [_birthday release];
  [_gender release];
  [_age release];
  [_bloodType release];
  [_region release];
  [_subRegion release];
  [_language release];
  [_timeZone release];
  [_creationDate release];
  [_thumbnailCompletionBlock release];
  
  [_displayName release];
  [_userHash release];
  [_userType release];
  [_profileUrl release];
  [_thumbnailUrl release];
  [_thumbnailUrlSmall release];
  [_thumbnailUrlLarge release];
  [_thumbnailUrlHuge release];
  [_thumbnailHandle release];
  
  [super dealloc];
}

#pragma mark - GreeSerializable Protocol

- (id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  self = [super init];
  if (self != nil) {
    _userId = [[serializer objectForKey:@"id"] retain];
    _nickname = [[serializer objectForKey:@"nickname"] retain];
    _aboutMe = [[serializer objectForKey:@"aboutMe"] retain];
    _birthday = [[serializer objectForKey:@"birthday"] retain];
    _gender = [[serializer objectForKey:@"gender"] retain];
    _age = [[serializer objectForKey:@"age"] retain];
    _bloodType = [[serializer objectForKey:@"bloodType"] retain];    
    _userGrade = [serializer integerForKey:@"userGrade"];
    _region = [[serializer objectForKey:@"region"] retain];
    _subRegion = [[serializer objectForKey:@"subregion"] retain];
    _language = [[serializer objectForKey:@"language"] retain];    
    _timeZone = [[serializer objectForKey:@"timezone"] retain];
    
    _displayName = [[serializer objectForKey:@"displayName"] retain];
    _hasThisApplication = [serializer boolForKey:@"hasApp"];
    _userHash = [[serializer objectForKey:@"userHash"] retain];
    _userType = [[serializer objectForKey:@"userType"] retain];
    _profileUrl = [[serializer urlForKey:@"profileUrl"] retain];
    _thumbnailUrl = [[serializer urlForKey:@"thumbnailUrl"] retain];
    _thumbnailUrlSmall = [[serializer urlForKey:@"thumbnailUrlSmall"] retain];
    _thumbnailUrlLarge = [[serializer urlForKey:@"thumbnailUrlLarge"] retain];
    _thumbnailUrlHuge = [[serializer urlForKey:@"thumbnailUrlHuge"] retain];
    
    _creationDate = [[serializer dateForKey:@"creationDate"] retain];
    if(!_creationDate) {
      _creationDate = [[NSDate alloc] init];
    }
  }
  
  return self;
}

- (void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
  [serializer serializeObject:_userId forKey:@"id"];
  [serializer serializeObject:_nickname forKey:@"nickname"];
  [serializer serializeObject:_aboutMe forKey:@"aboutMe"];
  [serializer serializeObject:_birthday forKey:@"birthday"];
  [serializer serializeObject:_gender forKey:@"gender"];
  [serializer serializeObject:_age forKey:@"age"];
  [serializer serializeObject:_bloodType forKey:@"bloodType"];
  [serializer serializeInteger:_userGrade forKey:@"userGrade"];
  [serializer serializeObject:_region forKey:@"region"];
  [serializer serializeObject:_subRegion forKey:@"subregion"];
  [serializer serializeObject:_language forKey:@"language"];    
  [serializer serializeObject:_timeZone forKey:@"timezone"];
  
  [serializer serializeObject:_displayName forKey:@"displayName"];
  [serializer serializeBool:_hasThisApplication forKey:@"hasApp"];
  [serializer serializeObject:_userHash forKey:@"userHash"];
  [serializer serializeObject:_userType forKey:@"userType"];
  [serializer serializeUrl:_profileUrl forKey:@"profileUrl"];
  [serializer serializeUrl:_thumbnailUrl forKey:@"thumbnailUrl"];
  [serializer serializeUrl:_thumbnailUrlSmall forKey:@"thumbnailUrlSmall"];
  [serializer serializeUrl:_thumbnailUrlLarge forKey:@"thumbnailUrlLarge"];
  [serializer serializeUrl:_thumbnailUrlHuge forKey:@"thumbnailUrlHuge"];
  
  [serializer serializeDate:_creationDate forKey:@"creationDate"];
}

#pragma mark - Public Interface

+ (void)loadUserWithId:(NSString*)userId block:(void(^)(GreeUser* user, NSError* error))block
{
  if (!block) {
    return;
  }

  void(^successBlock)(GreeAFHTTPRequestOperation*, id) = ^(GreeAFHTTPRequestOperation* operation, id responseObject){
    NSDictionary* entry = [responseObject objectForKey:@"entry"];                
    GreeSerializer* serializer = [GreeSerializer deserializerWithDictionary:entry];
    GreeUser* user = [[GreeUser alloc] initWithGreeSerializer:serializer];
    block(user, nil);
    [user release];
  };
  
  void(^failureBlock)(GreeAFHTTPRequestOperation*, NSError*) = ^(GreeAFHTTPRequestOperation* operation, NSError* error){
    block(nil, [GreeError convertToGreeError:error]);
  };
  
  NSString* path = [NSString stringWithFormat:@"/api/rest/people/%@/@self", userId];
  [[GreePlatform sharedInstance].httpClient 
    getPath:path 
    parameters:nil 
    success:successBlock
    failure:^(GreeAFHTTPRequestOperation *operation, NSError *error){
      failureBlock(operation, error);
    }];
}

- (id<GreeEnumerator>)loadFriendsWithBlock:(void(^)(NSArray* friends, NSError* error))block
{
  id<GreeEnumerator> enumerator = [[GreeFriendEnumerator alloc] initWithStartIndex:1 pageSize:0];
  [enumerator setGuid:self.userId];
  [enumerator loadNext:block];
  return [enumerator autorelease];
}

- (id<GreeEnumerator>)loadIgnoredUserIdsWithBlock:(void(^)(NSArray* ignoredUserIds, NSError* error))block
{
  id<GreeEnumerator> enumerator = [[GreeIgnoredUserIdEnumerator alloc] initWithStartIndex:1 pageSize:0];
  [enumerator setGuid:self.userId];
  [enumerator loadNext:block];
  return [enumerator autorelease];
}

- (void)loadThumbnailWithSize:(GreeUserThumbnailSize)size block:(void(^)(UIImage* icon, NSError* error))block
{
  [self cancelThumbnailLoad];
  
  self.thumbnailCompletionBlock = block;
  
  //if the creation date is too old, then reload to get updated thumbnails
  NSInteger timeout = [[GreePlatform sharedInstance].settings integerValueForSetting:GreeSettingUserThumbnailTimeoutInSeconds];
  NSInteger creationTime = [self.creationDate timeIntervalSinceReferenceDate];
  NSInteger currentTime = [NSDate timeIntervalSinceReferenceDate];
  
  if(creationTime + timeout < currentTime) {    
    [GreeUser loadUserWithId:self.userId block:^(GreeUser *user, NSError *error) {
      if(user) {
        self.thumbnailUrl = user.thumbnailUrl;
        self.thumbnailUrlSmall = user.thumbnailUrlSmall;
        self.thumbnailUrlLarge = user.thumbnailUrlLarge;
        self.thumbnailUrlHuge = user.thumbnailUrlHuge;
        self.creationDate = [NSDate date];
        //need to store it if this is the local user
        if([[GreePlatform sharedInstance].localUserId isEqualToString:self.userId]) {
          [GreeUser storeLocalUser:self];
        }
      }
      if(self.thumbnailCompletionBlock) {
        [self _loadThumbnailWithSize:size];
      }
    }];
  }
  else {
    [self _loadThumbnailWithSize:size];
  }
}

- (void)cancelThumbnailLoad
{
  [[[GreePlatform sharedInstance] httpClient] cancelWithHandle:self.thumbnailHandle]; 
  self.thumbnailHandle = nil;
  self.thumbnailCompletionBlock = nil;
}

- (void)isIgnoringUserWithId:(NSString*)ignoredUserId block:(void(^)(BOOL isIgnored, NSError* error))block
{
  if (!block) {
    return;
  }
  
  NSString* path = [NSString stringWithFormat:@"/api/rest/ignorelist/%@/@all/%@", self.userId, ignoredUserId];
  [[GreePlatform sharedInstance].httpClient 
    getPath:path 
    parameters:nil
    success:^(GreeAFHTTPRequestOperation* operation, id responseObject){
      id responseEntry = [responseObject objectForKey:@"entry"];
      if ([responseEntry isKindOfClass:[NSString class]]) {
        block(NO, nil);
      }else if([responseEntry isKindOfClass:[NSArray class]] || [responseEntry isKindOfClass:[NSDictionary class]]){                                           
        block(YES, nil);                                           
      }else {
        block(NO, [GreeError localizedGreeErrorWithCode:GreeErrorCodeBadDataFromServer]);
      }
    }
    failure:^(GreeAFHTTPRequestOperation* operation, NSError* error){
      block(NO, [GreeError convertToGreeError:error]); 
    }];
}

#pragma mark - NSObject Overrides

- (NSString*)description
{  
  return [NSString stringWithFormat:
    @"<%@:%p, id:%@, nickname:%@, hasThisApplication:%@, userGrade:%d, region:%@, subRegion:%@, language:%@, timeZone:%@>", 
    NSStringFromClass([self class]),
    self,
    self.userId,
    self.nickname,
    self.hasThisApplication ? @"YES" : @"NO",
    self.userGrade,
    self.region,
    self.subRegion,
    self.language,
    self.timeZone];
}

- (BOOL)isEqual:(id)object
{
  if ([object isKindOfClass:[GreeUser class]]) {
    return [self.userId isEqualToString:[object userId]];
  }
  
  return NO;
}

- (NSUInteger)hash
{
  return [self.userId hash];
}

#pragma mark - Internal Methods
- (void)_loadThumbnailWithSize:(GreeUserThumbnailSize)size 
{  
  NSURL* url = nil;
  switch (size) {
    case GreeUserThumbnailSizeSmall:
      url = self.thumbnailUrlSmall;
      break;
    default:
    case GreeUserThumbnailSizeStandard:
      url = self.thumbnailUrl;
      break;
    case GreeUserThumbnailSizeLarge:
      url = self.thumbnailUrlLarge;
      break;
    case GreeUserThumbnailSizeHuge:
      url = self.thumbnailUrlHuge;
      break;
  }
  
  self.thumbnailHandle = [[[GreePlatform sharedInstance] httpClient] downloadImageAtUrl:url withBlock:self.thumbnailCompletionBlock];  
  self.thumbnailCompletionBlock = nil;
}



#pragma mark - LocalUser Methods

+ (GreeUser*)localUserFromCache
{
  GreeUser* anUser = nil;
  NSDictionary* serializedObject = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kGreeUserDefaultsLocalUserKey];
  if (serializedObject) {
    GreeSerializer* serializer = [GreeSerializer deserializerWithDictionary:[serializedObject objectForKey:@"user"]];
    anUser = [[[GreeUser alloc] initWithGreeSerializer:serializer] autorelease];
  }
  return anUser;
}

+ (void)storeLocalUser:(GreeUser*)aUser
{
  GreeSerializer* serializer = [GreeSerializer serializer];
  [serializer serializeObject:aUser forKey:@"user"];
  [[NSUserDefaults standardUserDefaults] setObject:serializer.rootDictionary forKey:kGreeUserDefaultsLocalUserKey];
}

+ (void)removeLocalUserInCache
{
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kGreeUserDefaultsLocalUserKey];
}

+ (void)upgradeLocalUser:(GreeUserGrade)grade
{
  [GreePlatform sharedInstance].localUser.userGrade = grade;
}

@end

#pragma mark - GreeFriendEnumerator

@implementation GreeFriendEnumerator

#pragma mark - GreeEnumeratorBase Overrides

- (NSString*)httpRequestPath
{
  return [NSString stringWithFormat:@"/api/rest/people/%@/@friends", self.guid];
}

- (NSArray*)convertData:(NSArray*)input
{
  return [GreeSerializer deserializeArray:input withClass:[GreeUser class]];
}

@end

#pragma mark - GreeIgnoredUserIdEnumerator

@implementation GreeIgnoredUserIdEnumerator

#pragma mark - GreeEnumeratorBase Overrides

- (NSString*)httpRequestPath
{
  return [NSString stringWithFormat:@"/api/rest/ignorelist/%@/@all", self.guid];
}

- (NSArray*)convertData:(NSArray*)input
{
  NSMutableArray* ignoredIds = [[NSMutableArray alloc] initWithCapacity:[input count]];
  for (NSDictionary* entry in input) {
    if ([entry isKindOfClass:[NSDictionary class]]) {
      [ignoredIds addObject:[NSString stringWithFormat:@"%@", [entry objectForKey:@"ignorelistId"]]];
    }
  }

  NSArray* immutableResponse = [NSArray arrayWithArray:ignoredIds];
  [ignoredIds release];
  return immutableResponse;
}

@end
