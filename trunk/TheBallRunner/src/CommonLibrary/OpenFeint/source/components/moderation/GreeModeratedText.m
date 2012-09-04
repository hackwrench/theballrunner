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

#import "GreeModeratedText.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"
#import "GreeHTTPClient.h"
#import "GreeSerializer.h"
#import "NSDateFormatter+GreeAdditions.h"
#import "GreeModerationList.h"
#import "GreeError+Internal.h"

NSString* const GreeModeratedTextUpdatedNotification = @"GreeModeratedTextUpdatedNotification";

@interface GreeModeratedText ()
@property (nonatomic, retain, readwrite) NSString* content;
@property (nonatomic, retain, readonly) NSString* ownerId;
@property (nonatomic, assign, readwrite) GreeModerationStatus status;
@property (nonatomic, retain, readwrite) NSDate* lastCheckedTimestamp;
@end

@implementation GreeModeratedText

@synthesize textId = _textId;
@synthesize appId = _appId;
@synthesize authorId = _authorId;
@synthesize ownerId = _ownerId;
@synthesize content = _content;
@synthesize status = _status;
@synthesize lastCheckedTimestamp = _lastCheckedTimestamp;

#pragma mark - Object Lifecycle

- (void)dealloc
{
  [_textId release];
  [_appId release];
  [_authorId release];
  [_ownerId release];
  
  [_content release];
  
  [_lastCheckedTimestamp release];
  
  [super dealloc];
}

#pragma mark - GreeSerializable Protocol

- (id)initWithGreeSerializer:(GreeSerializer*)serializer
{
  if ((self = [super init])) {
    _textId = [[serializer objectForKey:@"textId"] retain];
    _appId = [[serializer objectForKey:@"appId"] retain];
    _authorId = [[serializer objectForKey:@"authorId"] retain];
    _ownerId = [[serializer objectForKey:@"ownerId"] retain];
  
    _content = [[serializer objectForKey:@"data"] retain];
    NSString* statusString = [serializer objectForKey:@"status"];
    _status = [statusString integerValue];
    
    _lastCheckedTimestamp = [[serializer dateForKey:@"lastCheckedTimestamp"] retain];
  }
  
  return self;
}

- (void)serializeWithGreeSerializer:(GreeSerializer*)serializer
{
  [serializer serializeObject:_textId forKey:@"textId"];
  [serializer serializeObject:_appId forKey:@"appId"];
  [serializer serializeObject:_authorId forKey:@"authorId"];
  [serializer serializeObject:_ownerId forKey:@"ownerId"];
  
  [serializer serializeObject:_content forKey:@"data"];
  
  NSString* statusString = [NSString stringWithFormat:@"%d", _status];
  [serializer serializeObject:statusString forKey:@"status"];
  
  [serializer serializeDate:_lastCheckedTimestamp forKey:@"lastCheckTimestamp"];
}


#pragma mark - Public Interface

+ (void)createWithString:(NSString*)aString block:(void(^)(GreeModeratedText* createdUserText, NSError* error))block
{  
  NSString* path = @"/api/rest/moderation/@app";
  NSDictionary* parameters = [NSDictionary dictionaryWithObject:aString forKey:@"data"];

  [[GreePlatform sharedInstance].httpClient
      postPath:path
      parameters:parameters
      success:^(GreeAFHTTPRequestOperation *operation, id responseObject) {        
        NSArray* entryItems = [responseObject objectForKey:@"entry"];
        NSArray* userTexts = [GreeSerializer deserializeArray:entryItems withClass:[GreeModeratedText class]];
                
        NSAssert([userTexts count] == 1, @"Creating a user did not return exactly one moderated text");
                
        if (block) {
          GreeModeratedText* firstText = [userTexts objectAtIndex:0];
          firstText.lastCheckedTimestamp = [NSDate date];
          block(firstText, nil);
        }
      }
              
      failure:^(GreeAFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
          block(nil, error);
        }
      }];
}

+ (void)loadFromIds:(NSArray*)textIds block:(void(^)(NSArray* userTexts, NSError* error))block
{
  if (!block) {
    return;
  }
  
  NSString *joinedTextIds = [textIds componentsJoinedByString:@","];
  NSString* path = [NSString stringWithFormat:@"/api/rest/moderation/@app/%@", joinedTextIds];

  [[GreePlatform sharedInstance].httpClient
      getPath:path
      parameters:nil 
      success:^(GreeAFHTTPRequestOperation *operation, id responseObject){
        NSArray* entryItems = [responseObject objectForKey:@"entry"];                
        NSArray* userTexts = [GreeSerializer deserializeArray:entryItems withClass:[GreeModeratedText class]];
        block(userTexts, nil);
      }
   
      failure:^(GreeAFHTTPRequestOperation *operation, NSError *error){
        block(nil, error);
      }];
}

- (void)updateWithString:(NSString*)updatedString block:(void(^)(NSError* error))block
{
  self.lastCheckedTimestamp = nil;
  NSString* path = [NSString stringWithFormat:@"/api/rest/moderation/@app/%@", self.textId];
  NSDictionary* parameters = [NSDictionary dictionaryWithObject:updatedString forKey:@"data"];

  [[GreePlatform sharedInstance].httpClient
      putPath:path
      parameters:parameters
      success:^(GreeAFHTTPRequestOperation *operation, id responseObject) {
        self.content = updatedString;
        [[NSNotificationCenter defaultCenter] postNotificationName:GreeModeratedTextUpdatedNotification object:self];
        if (block) {
          block(nil);
        }
      }
              
      failure:^(GreeAFHTTPRequestOperation *operation, NSError *error){
        if (block) {
          block([GreeError convertToGreeError:error]);
        }
      }];
}

- (void)deleteWithBlock:(void(^)(NSError* error))block
{
  NSString* path = [NSString stringWithFormat:@"/api/rest/moderation/@app/%@", self.textId];

  [[GreePlatform sharedInstance].httpClient 
      deletePath:path
      parameters:nil
      success:^(GreeAFHTTPRequestOperation *operation, id responseObject) {
        if (block) {
          block(nil);
        }
      }
              
      failure:^(GreeAFHTTPRequestOperation *operation, NSError *error){
        if (block) {
          block([GreeError convertToGreeError:error]);
        }
      }];
}

- (void)beginNotification
{
  GreeModerationList* modList = [GreePlatform sharedInstance].moderationList;
  [modList addText:self];
}

- (void)endNotification
{
  GreeModerationList* modList = [GreePlatform sharedInstance].moderationList;
  [modList removeText:self];
}

#pragma mark - NSObject Overrides

- (NSString*)description
{  
  return [NSString stringWithFormat:@"<%@:%p, textId:%@, appId:%@, content:%@, status:%d lastUpdated:%@>", 
          NSStringFromClass([self class]),
          self,
          self.textId,
          self.appId,
          self.content,
          self.status,
          self.lastCheckedTimestamp];
}

- (BOOL)isEqual:(id)object 
{
  if (![object isMemberOfClass:[GreeModeratedText class]]) {
    return NO;
  }
  
  GreeModeratedText *userText = (GreeModeratedText*)object;
  
  return [self.textId isEqualToString:userText.textId];
}

- (NSUInteger)hash {
  return [self.textId hash];
}

@end
