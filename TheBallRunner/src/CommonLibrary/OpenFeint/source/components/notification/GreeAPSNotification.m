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

#import "GreeAPSNotification.h"
#import "GreeSerializer.h"

@implementation GreeAPSNotification
@synthesize actorId = _actorId;
@synthesize text = _text; 
@synthesize type = _type;
@synthesize iconFlag = _iconFlag;
@synthesize iconToken = _iconToken;
@synthesize iconURL = _iconURL;
@synthesize contentId = _contentId;

#pragma mark - 

- (void)dealloc
{
  [_actorId release];
  [_text release];
  [_iconToken release];
  [_iconURL release];
  [_contentId release];
  
  [super dealloc];
}

#pragma mark - GreeSerializable Protocol
- (id)initWithGreeSerializer:(GreeSerializer *)serializer
{
  self = [super init];
  if (self != nil) {
    //the actor is sent over as an int!
    _actorId = [[[serializer objectForKey:@"act"] description] copy]; 
    _text = [[serializer objectForKey:@"text"] copy];
    _type = [serializer integerForKey:@"type"];
    _iconFlag = [serializer integerForKey:@"iflag"];
    _iconToken = [[serializer objectForKey:@"itoken"] copy];
    _contentId = [[serializer objectForKey:@"cid"] copy];
    
    switch (_iconFlag) {
      case GreeAPSNotificationIconGreeType:
        _iconURL = nil;
        break;
      case GreeAPSNotificationIconApplicationType:
        _iconURL = nil;
        break;
      case GreeAPSNotificationIconDownloadType:
        _iconURL = [[NSURL URLWithString:[serializer objectForKey:@"itoken"]] retain];
        break;
    } 
  }
  return self;
}

- (void)serializeWithGreeSerializer:(GreeSerializer *)serializer
{
  [serializer serializeObject:_actorId forKey:@"act"];
  [serializer serializeObject:_text forKey:@"text"];
  [serializer serializeInteger:_type forKey:@"type"];
  [serializer serializeInteger:_iconFlag forKey:@"iflag"];
  [serializer serializeObject:_iconToken forKey:@"itoken"];
  [serializer serializeObject:_contentId forKey:@"cid"];
}


- (NSString*)description {
  return [NSString stringWithFormat:@"<%@:%p, act:%@, text:%@, type:%@, iflag:%@, itoken:%@, cid:%@>",
    NSStringFromClass([self class]),
    self,
    self.actorId,
    self.text,
    NSStringFromGreeNotificationSource(self.type),
    NSStringFromGreeAPSNotificationIconType(self.iconFlag),
    self.iconToken,
    self.contentId];
}

@end
