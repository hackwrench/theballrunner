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

#import "GreeNotification+Internal.h"
#import "GreeSerializer.h"
#import "GreeAPSNotification.h"
#import "GreeLocalNotification.h"
#import "AFNetworking.h"
#import "GreeError+Internal.h"
#import "GreePlatform+Internal.h"
#import "GreeHTTPClient.h"
#import "GreeGlobalization.h"
#import "UIImage+GreeAdditions.h"

@interface GreeNotification ()
@property (nonatomic, retain) NSDictionary* infoDictionary;

@property (nonatomic, assign) GreeAPSNotificationIconType iconFlag;
@property (nonatomic, retain) NSString* iconToken;
@property (nonatomic, retain) UIImage* iconImage;
@property (nonatomic, assign) BOOL showLogo;

- (id)initWithAPSDictionary:(NSDictionary*)dictionary;
- (id)initWithLocalNotificationDictionary:(NSDictionary*)dictionary;
@end

const static NSTimeInterval notificationDuration = 3.0f;

@implementation GreeNotification

@synthesize message = _message;
@synthesize displayType = _displayType;
@synthesize duration = _duration;
@synthesize infoDictionary = _infoDictionary;
@synthesize iconFlag = _iconFlag;
@synthesize iconToken = _iconToken;
@synthesize iconImage = _iconImage;
@synthesize showLogo = _showLogo;

- (id)initWithMessage:(NSString*)message
    displayType:(GreeNotificationViewDisplayType)displayType
    duration:(NSTimeInterval)duration
{
  self = [super init];
  if (self != nil) {
    _message = [message copy];        
    _displayType = displayType;
    _duration = duration;
  }
  
  return self;
}

- (id)initWithAPSDictionary:(NSDictionary*)dictionary
{
  NSDictionary* iam = [dictionary objectForKey:@"iam"];
  
  if(iam) {
    GreeSerializer *serializer = [GreeSerializer deserializerWithDictionary:[dictionary objectForKey:@"iam"]];
    GreeAPSNotification *apsNotification = [[[GreeAPSNotification alloc] initWithGreeSerializer:serializer] autorelease];
    
    self = [self 
            initWithMessage:apsNotification.text 
            displayType:GreeNotificationViewDisplayDefaultType 
            duration:notificationDuration];
    if (self != nil) {
      _infoDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:@"dash", @"type", 
                         [NSNumber numberWithInt:apsNotification.type], @"subtype", 
                         apsNotification.actorId, @"actor_id", 
                         apsNotification.contentId, @"cid",
                         nil];
      _iconFlag = apsNotification.iconFlag;
      _iconToken = [apsNotification.iconToken retain];
    }
    
  } else {
    NSDictionary* aps = [dictionary objectForKey:@"aps"];
    NSString* message_id = [aps objectForKey:@"message_id"];
    NSString* request_id = [aps objectForKey:@"request_id"];
    
    id alert = [aps objectForKey:@"alert"];
    NSString* text = [alert isKindOfClass:[NSDictionary class]] ? [alert objectForKey:@"body"] : alert;
    
    if(message_id) {
      self = [self initWithMessage:text displayType:GreeNotificationViewDisplayDefaultType duration:notificationDuration];
      _infoDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:@"message", @"type", message_id, @"info-key", nil];
    } else if(request_id) {
      self = [self initWithMessage:text displayType:GreeNotificationViewDisplayDefaultType duration:notificationDuration];
      _infoDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:@"request", @"type", request_id, @"info-key", nil];
    }
  }
  return self;
}

- (id)initWithLocalNotificationDictionary:(NSDictionary*)dictionary
{
  self = [self
          initWithMessage:[dictionary objectForKey:@"message"]
          displayType:GreeNotificationViewDisplayDefaultType
          duration:notificationDuration];
  
  return self;
}

- (void)dealloc
{
  [_message release];
  [_iconToken release];
  [_iconImage release];
  
  [_infoDictionary release];
    
  [super dealloc];
}

#pragma mark - NSObject Overrides

- (NSString*)description
{
    return [NSString stringWithFormat:@"<%@:%p, message:%@, type:%@, duration:%f>",
            NSStringFromClass([self class]),
            self,
            self.message,
            NSStringFromGreeNotificationViewDisplayType(self.displayType),
            self.duration];
}

#pragma mark - Public Interface

+ (id)notificationForLoginWithUsername:(NSString*)username
{
  if (username == nil) {
    return nil;
  }
  
  GreeNotification* notification = [[[GreeNotification alloc] initWithMessage:[NSString stringWithFormat:GreePlatformString(@"notificaton.welcomeback.message", @"Welcome, %@"),
                                                                             username]
                                                                displayType:GreeNotificationViewDisplayDefaultType
                                                                   duration:notificationDuration] autorelease];
  
  notification.infoDictionary = [[[NSDictionary alloc] initWithObjectsAndKeys:@"dash", @"type", [NSNumber numberWithInt:GreeNotificationSourceMyLogin], @"subtype", nil] autorelease];
  return notification;
}

+ (id)notificationWithAPSDictionary:(NSDictionary*)dictionary
{
  return [[[GreeNotification alloc] initWithAPSDictionary:dictionary] autorelease];
}

+ (id)notificationWithLocalNotificationDictionary:(NSDictionary*)dictionary
{
  return [[[GreeNotification alloc] initWithLocalNotificationDictionary:dictionary] autorelease];
}

- (void)loadIconWithBlock:(void(^)(NSError* error))block
{ 
  if(!block) return;  //we really need this to know when it is complete
  if(self.iconImage) return; //only do it once

  switch(self.iconFlag) {      
    case GreeAPSNotificationIconApplicationType:
      self.showLogo = YES;
      self.iconImage = [UIImage greeAppIconNearestWidth:60];
      block(nil);
      break;
    case GreeAPSNotificationIconDownloadType:
    {
      self.showLogo = NO;
      NSURL* url = [NSURL URLWithString:self.iconToken];
      [[GreePlatform sharedInstance].httpClient downloadImageAtUrl:url withBlock:^(UIImage *image, NSError *error) {
        if(image) {  //avoid erasing an image already loaded properly
          self.iconImage = image;
        }
        block(error);
      }];
    }
      break;
    default:
    case GreeAPSNotificationIconGreeType:
      self.showLogo = NO;
      self.iconImage = [UIImage greeImageNamed:@"gree_notification_logo.png"];
      block(nil);
      break;
  }
}

@end
