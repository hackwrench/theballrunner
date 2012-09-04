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
#import "GreeJSReadyCommand.h"
#import "GreeJSStartLoadingCommand.h"
#import "GreeJSContentsReadyCommand.h"
#import "GreeJSFailedWithErrorCommand.h"
#import "GreeJSInputSuccessCommand.h"
#import "GreeJSInputFailureCommand.h"
#import "GreeJSPushViewCommand.h"
#import "GreeJSPushViewWithUrlCommand.h"
#import "GreeJSPopViewCommand.h"
#import "GreeJSShowModalViewCommand.h"
#import "GreeJSShowInputViewCommand.h"
#import "GreeJSDismissModalViewCommand.h"
#import "GreeJSOpenExternalViewCommand.h"
#import "GreeJSSetViewTitleCommand.h"
#import "GreeJSSetPullToRefreshEnabledCommand.h"
#import "GreeJSSetSubnavigationMenuCommand.h"
#import "GreeJSShowPhotoCommand.h"
#import "GreeJSTakePhotoCommand.h"
#import "GreeJSGetContactListCommand.h"
#import "GreeJSOpenFromMenuCommand.h"
#import "GreeJSSetValueCommand.h"
#import "GreeJSGetValueCommand.h"
#import "GreeJSShowAlertViewCommand.h"
#import "GreeJSShowActionSheetCommand.h"
#import "GreeJSLaunchMailComposerCommand.h"
#import "GreeJSLaunchSMSComposerCommand.h"
#import "GreeJSLaunchNativeBrowserCommand.h"
#import "GreeJSLaunchNativeAppCommand.h"
#import "GreeJSSnsApiRequestCommand.h"
#import "GreeJSGetAppInfoCommand.h"

@interface GreeJSCommandFactory ()
+ (NSMutableDictionary*)parametersFromQueryString:(NSString*)query;
@end


@implementation GreeJSCommandFactory
@synthesize commands = _commands;


static GreeJSCommandFactory *_instance = nil;

#pragma mark - Object Lifecycle (Singleton)

+ (GreeJSCommandFactory *)instance
{
  @synchronized(self)
  {
    if (!_instance)
    {
      _instance = [[GreeJSCommandFactory alloc] init];
    }
  }
  return _instance;
}

- (id)init
{
  self = [super init];
  if (self)
  {
    _commands = [[NSDictionary alloc] initWithObjectsAndKeys:
                  [GreeJSReadyCommand class], [GreeJSReadyCommand name],
                  [GreeJSStartLoadingCommand class], [GreeJSStartLoadingCommand name],
                  [GreeJSContentsReadyCommand class], [GreeJSContentsReadyCommand name],
                  [GreeJSFailedWithErrorCommand class], [GreeJSFailedWithErrorCommand name],
                  [GreeJSInputSuccessCommand class], [GreeJSInputSuccessCommand name],
                  [GreeJSInputFailureCommand class], [GreeJSInputFailureCommand name],
                  [GreeJSPushViewCommand class], [GreeJSPushViewCommand name],
                  [GreeJSPushViewWithUrlCommand class], [GreeJSPushViewWithUrlCommand name],
                  [GreeJSPopViewCommand class], [GreeJSPopViewCommand name],
                  [GreeJSShowModalViewCommand class], [GreeJSShowModalViewCommand name],
                  [GreeJSShowInputViewCommand class], [GreeJSShowInputViewCommand name],
                  [GreeJSDismissModalViewCommand class], [GreeJSDismissModalViewCommand name],
                  [GreeJSOpenExternalViewCommand class], [GreeJSOpenExternalViewCommand name],
                  [GreeJSSetViewTitleCommand class], [GreeJSSetViewTitleCommand name],
                  [GreeJSSetPullToRefreshEnabledCommand class], [GreeJSSetPullToRefreshEnabledCommand name],
                  [GreeJSShowPhotoCommand class], [GreeJSShowPhotoCommand name],
                  [GreeJSTakePhotoCommand class], [GreeJSTakePhotoCommand name],
                  [GreeJSSetSubnavigationMenuCommand class], [GreeJSSetSubnavigationMenuCommand name],
                  [GreeJSOpenFromMenuCommand class], [GreeJSOpenFromMenuCommand name],
                  [GreeJSGetContactListCommand class], [GreeJSGetContactListCommand name],
                  [GreeJSGetValueCommand class], [GreeJSGetValueCommand name],
                  [GreeJSSetValueCommand class], [GreeJSSetValueCommand name],
                  [GreeJSShowAlertViewCommand class], [GreeJSShowAlertViewCommand name],
                  [GreeJSShowActionSheetCommand class], [GreeJSShowActionSheetCommand name],
                  [GreeJSLaunchMailComposerCommand class], [GreeJSLaunchMailComposerCommand name],
                  [GreeJSLaunchSMSComposerCommand class], [GreeJSLaunchSMSComposerCommand name],
                  [GreeJSLaunchNativeBrowserCommand class], [GreeJSLaunchNativeBrowserCommand name],
                  [GreeJSLaunchNativeAppCommand class], [GreeJSLaunchNativeAppCommand name],
                  [GreeJSSnsApiRequestCommand class], [GreeJSSnsApiRequestCommand name],
                  [GreeJSGetAppInfoCommand class], [GreeJSGetAppInfoCommand name],
                  nil];
  }
  return self;
}

- (void)dealloc
{
  [_commands release];
  _commands = nil;

  [super dealloc];
}

+ (id)allocWithZone:(NSZone*)zone
{
  @synchronized(self)
  {
    if (!_instance)
    {
      _instance = [super allocWithZone:zone];
      return _instance;
    }
  }
  return nil;
}

- (id)copyWithZone:(NSZone*)zone
{
  return self;
}

- (id)retain
{
  return self;
}

- (unsigned)retainCount
{
  return UINT_MAX;
}

- (oneway void)release
{
  // Do nothing.
}

- (id)autorelease
{
  return self;
}


#pragma mark - Public Interface

+ (GreeJSCommand*)createCommand:(NSString*)name withCommandMap:(NSDictionary*)commands {
  Class commandType = [commands valueForKey:name];
  if (commandType == nil) {
    NSString *firstChar = [name substringToIndex:1];
    NSString *body = [name substringFromIndex:1];
    NSString *className = [NSString stringWithFormat:@"GreeJS%@%@Command", [firstChar uppercaseString], body];
    commandType = NSClassFromString(className);
  }
  if (commandType)
  {
    return [[[commandType alloc] init] autorelease];
  }
  return nil;
}

- (id)createCommand:(NSURLRequest*)request
{
  NSURL *u = [request URL];
  NSString *name = [u host];
  GreeJSCommand *command = [[self class] createCommand:name withCommandMap:self.commands];
  NSDictionary *params = [[self class] parametersFromQueryString:[u query]];
  NSUInteger serial = [[params objectForKey:@"serial"] integerValue];
  command.serial = serial;
  return command;
}


#pragma mark - Internal Methods

+ (NSMutableDictionary*)parametersFromQueryString:(NSString*)query
{
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  NSArray *components = [query componentsSeparatedByString:@"&"];
  for (NSString *pair in components) {
    NSArray *kv = [pair componentsSeparatedByString:@"="];
    if ([kv count] == 2) {
      NSString *k = [[kv objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      NSString *v = [[kv objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      [params setObject:v forKey:k];
    }
  }
  return params;
}

- (void)importCommandMap:(NSDictionary*)commandMap {
  NSMutableDictionary *mutableCommandDictionary = [NSMutableDictionary dictionaryWithDictionary:_commands];
  [mutableCommandDictionary addEntriesFromDictionary:commandMap];
  self.commands = [NSDictionary dictionaryWithDictionary:mutableCommandDictionary];
}

@end
