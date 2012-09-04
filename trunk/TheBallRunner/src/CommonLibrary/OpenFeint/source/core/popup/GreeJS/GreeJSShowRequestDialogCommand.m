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


#import "GreeJSShowRequestDialogCommand.h"
#import "GreePopup.h"
#import "GreePopupView.h"
#import "UIViewController+GreePlatform.h"

#define kGreeJSShowRequestDialogCommandCallbackFunction @"callback"

@implementation GreeJSShowRequestDialogCommand

#pragma mark - GreeJSCommand Overrides

+ (NSString *)name
{
  return @"show_request_dialog";
}

- (void)execute:(NSDictionary *)params
{
  __block GreeJSShowRequestDialogCommand *command = self;
  UIViewController *viewController = [self viewControllerWithRequiredBaseClass:nil];
  
  NSDictionary *request = [params objectForKey:@"request"];
  
  GreeRequestServicePopup *popup = [GreeRequestServicePopup popupWithParameters:request];
  
  popup.didDismissBlock = ^(GreePopup* sender){
    GreeRequestServicePopup *popup = (GreeRequestServicePopup*)sender;
  
    NSDictionary *callbackParameters = [NSMutableDictionary dictionary];
    [callbackParameters setValue:@"close" forKey:@"result"];
    if(popup.results != nil) [callbackParameters setValue:popup.results forKey:@"param"];

    [[command.environment handler]
      callback:[params objectForKey:kGreeJSShowRequestDialogCommandCallbackFunction]
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
