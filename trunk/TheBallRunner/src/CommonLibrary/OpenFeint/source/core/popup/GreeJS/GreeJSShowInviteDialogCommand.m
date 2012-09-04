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


#import "GreeJSShowInviteDialogCommand.h"
#import "GreePopup.h"
#import "GreePopupView.h"
#import "UIViewController+GreePlatform.h"

#define kGreeJSShowInviteDialogCommandCallbackFunction @"callback"

@implementation GreeJSShowInviteDialogCommand

#pragma mark - GreeJSCommand Overrides

+ (NSString *)name
{
  return @"show_invite_dialog";
}

- (void)execute:(NSDictionary *)params
{
  __block GreeJSShowInviteDialogCommand *command = self;
  UIViewController *viewController = [self viewControllerWithRequiredBaseClass:nil];
  
  NSDictionary *invite = [params objectForKey:@"invite"];
  
  GreeInvitePopup *popup = [GreeInvitePopup popupWithParameters:params];
  
  NSString *message = [invite objectForKey:@"body"];
  
  if (message != nil) {
    popup.message = message;
  }
  
  NSString *callbackurl = [invite objectForKey:@"callbackurl"];
  if (callbackurl != nil) {
    popup.callbackURL = [NSURL URLWithString:callbackurl];
  }
  
  NSArray* toUserIds = [invite objectForKey:@"to_user_id"];
  if (toUserIds != nil) {
    popup.toUserIds = toUserIds;
  }
  
  popup.didDismissBlock = ^(GreePopup* sender){
    GreeInvitePopup *popup = (GreeInvitePopup*)sender;
  
    NSDictionary *callbackParameters = [NSMutableDictionary dictionary];
    [callbackParameters setValue:@"close" forKey:@"result"];
    if(popup.results != nil) [callbackParameters setValue:popup.results forKey:@"param"];

    [[command.environment handler]
      callback:[params objectForKey:kGreeJSShowInviteDialogCommandCallbackFunction]
      params:callbackParameters];
      [command callback];
  };
  
  [viewController showGreePopup:popup];
}

- (NSString*)description
{  
  return [NSString stringWithFormat:@"<%@:%p>",
    NSStringFromClass([self class]),
    self];
}

@end
