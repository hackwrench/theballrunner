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

#import <MessageUI/MessageUI.h>
#import "GreeJSLaunchSMSComposerCommand.h"
#import "UIViewController+GreeAdditions.h"

#define kGreeJSSendSMSParamsCallbackKey @"callback"

@interface GreeJSLaunchSMSComposerCommand()
-(void)callbackWithResult:(NSDictionary*)callbackParameters;
@end

@implementation GreeJSLaunchSMSComposerCommand

#pragma mark - Object lifecycle

- (void)dealloc {
  [_parameters release];
  [super dealloc];
}

#pragma mark - GreeJSCommand Overrides

+ (NSString *)name
{
  return @"launch_sms_composer";
}

- (void)execute:(NSDictionary *)params
{
  NSString *recipient = [params objectForKey:@"to"];
  _parameters = [params retain];

  if (![MFMessageComposeViewController canSendText] || (recipient == nil)) {
    NSDictionary *callbackParameters = [NSDictionary dictionaryWithObject:@"fail" forKey:@"result"];
    [self callbackWithResult:callbackParameters];
    return;
  }
  
  MFMessageComposeViewController *messageViewController = [[MFMessageComposeViewController alloc] init];
  messageViewController.messageComposeDelegate = self;
  messageViewController.recipients = [NSArray arrayWithObject:recipient];
  messageViewController.body = [params objectForKey:@"body"];
  [[self viewControllerWithRequiredBaseClass:nil] greePresentViewController:messageViewController animated:YES completion:nil];
  [messageViewController release];
}

- (void)callback {
  [_parameters release];
  _parameters = nil;
  
  [super callback];
}


#pragma mark - Internal Methods
-(void)callbackWithResult:(NSDictionary*)callbackParameters {
  [[self.environment handler]
    callback:[_parameters objectForKey:kGreeJSSendSMSParamsCallbackKey]
    params:callbackParameters];
  
  [self callback];
}

#pragma mark - MFMailComposeViewController delegate method
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
    didFinishWithResult:(MessageComposeResult)result {
  NSDictionary *callbackParameters = nil;
  
  switch (result) {
    case MessageComposeResultSent:
      callbackParameters = [NSDictionary dictionaryWithObject:@"success" forKey:@"result"];
      break;
    case MessageComposeResultFailed:
    case MessageComposeResultCancelled:
    default:
      callbackParameters = [NSDictionary dictionaryWithObject:@"success" forKey:@"result"];
      break;
  }
  
  [[self viewControllerWithRequiredBaseClass:nil] greeDismissViewControllerAnimated:YES completion:nil];
  [self callbackWithResult:callbackParameters];
}

@end
