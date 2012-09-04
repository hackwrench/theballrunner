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

#import "GreeJSWebViewController+ModalView.h"
#import "GreeJSShowModalViewCommand.h"
#import "GreeJSInputViewController.h"
#import "GreeJSInputSuccessCommand.h"
#import "GreeJSInputFailureCommand.h"

#import "GreePlatform+Internal.h"
#import "GreeNetworkReachability.h"
#import "GreeGlobalization.h"
#import "UIViewController+GreeAdditions.h"

NSString *const kGreeJSErrorKey = @"error";

@implementation GreeJSWebViewController (ModalView)

#pragma mark - UIViewController Overrides

- (void)dismissModalViewControllerAnimated:(BOOL)animated
{
  GreeJSModalNavigationController *navigationController;
  if (self.inputViewController) {
    navigationController = (GreeJSModalNavigationController*)self.inputViewController.navigationController;
  } else if (self.nextWebViewController) {
    navigationController = (GreeJSModalNavigationController*)self.nextWebViewController.navigationController;
  } else {
    navigationController = (GreeJSModalNavigationController*)self.navigationController;
  }
  if (navigationController.block)
    navigationController.block();
  
  if (self.inputViewController) {
    self.inputViewController = nil;
  }
  if (self.modalRightButtonCallback) {
    self.modalRightButtonCallback = nil;
  }
  if (self.modalRightButtonCallbackInfo) {
    self.modalRightButtonCallbackInfo = nil;
  }

  [super dismissModalViewControllerAnimated:animated];
}

#pragma mark - Internal Methods

- (void)greeJSPresentModalNavigationController:(GreeJSModalNavigationController *)navigationController
                                      animated:(BOOL)animated
{
  __block void (^oldBlock)(void) = navigationController.block;
  
  navigationController.block = ^{
    UIViewController *lastPresentedViewController = [[UIViewController greeLastPresentedViewController] retain];
    [lastPresentedViewController greeDismissViewControllerAnimated:YES completion:oldBlock];
    [lastPresentedViewController release];
  };
  
  [[UIViewController greeLastPresentedViewController] greePresentViewController:navigationController animated:YES completion:nil];
}

- (void)greeJSModalRightButtonFailure:(NSNotification*)notification
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:[GreeJSInputSuccessCommand notificationName] object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:[GreeJSInputFailureCommand notificationName] object:nil];
  
  if (self.inputViewController) {
    [self.inputViewController hideIndicator];
    self.inputViewController.navigationItem.rightBarButtonItem.enabled = YES;
  } else {
    [self displayLoadingIndicator:NO];
    self.navigationItem.rightBarButtonItem.enabled = YES;
  }
  
  NSString *errorMessage = [notification.userInfo objectForKey:kGreeJSErrorKey];
  
  if ([errorMessage isEqual:[NSNull null]]) {
    // Use preset error messages if none provided by userInfo.
    if (![[GreePlatform sharedInstance].reachability isConnectedToInternet]) {
      errorMessage = GreePlatformString(@"GreeJS.InputViewController.InputFailure.NoConnection", 
                                  @"Could not establish a network connection. Please make sure your network connection "
                                  @"is active and try again.");
    } else {
      errorMessage = GreePlatformString(@"GreeJS.InputViewController.InputFailure.UnknownError", 
                                  @"An error occurred that prevented completion of your request. Please try again.");
    }
  }
  
  UIAlertView *av = [[UIAlertView alloc] initWithTitle:GreePlatformString(@"GreeJS.InputViewController.InputFailure.Alert.Title", 
                                                                    @"An Error Occurred")
                                               message:errorMessage
                                              delegate:nil
                                     cancelButtonTitle:GreePlatformString(@"GreeJS.InputViewController.InputFailure.Alert.Confirm",
                                                                    @"OK")
                                     otherButtonTitles:nil];
  [av show];
  [av release];
}

- (void)greeJSModalRightButtonSucceed:(NSNotification*)notification
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:[GreeJSInputSuccessCommand notificationName] object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:[GreeJSInputFailureCommand notificationName] object:nil];
  
  if (self.inputViewController) {
    [[UIViewController greeLastPresentedViewController] greeDismissViewControllerAnimated:YES completion:nil];
    [self.inputViewController hideIndicator];
    self.inputViewController.navigationItem.rightBarButtonItem.enabled = YES;
  } else {
    [self displayLoadingIndicator:NO];
    [[UIViewController greeLastPresentedViewController] greeDismissViewControllerAnimated:YES completion:nil];
    self.navigationItem.rightBarButtonItem.enabled = YES;
  }
}

- (void)greeJSDismissModalViewController:(UIButton*)sender
{
  if (sender.tag == kModalTypeInputTextViewCancel && 
      [[[self.inputViewController data] objectForKey:@"text"] length] > 0) {
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:GreePlatformString(@"GreeJS.InputViewController.CancelAlert.Title", @"Cancel")  
                                                 message:GreePlatformString(@"GreeJS.InputViewController.CancelAlert.Message", @"Are you sure you want to cancel?")
                                                delegate:self 
                                       cancelButtonTitle:GreePlatformString(@"GreeJS.InputViewController.CancelAlert.Button.No", @"No") 
                                       otherButtonTitles:GreePlatformString(@"GreeJS.InputViewController.CancelAlert.Button.Yes", @"Yes"), nil];
    [av show];
    [av release];
    
  } else {
    [[UIViewController greeLastPresentedViewController] greeDismissViewControllerAnimated:YES completion:nil];
  }
}

- (void)greeJSModalRightButtonPressed:(UIButton*)sender
{
  if (!self.modalRightButtonCallback) {
    [[UIViewController greeLastPresentedViewController] greeDismissViewControllerAnimated:YES completion:nil];
    return;
  }
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(greeJSModalRightButtonSucceed:)
                                               name:[GreeJSInputSuccessCommand notificationName]
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(greeJSModalRightButtonFailure:)
                                               name:[GreeJSInputFailureCommand notificationName]
                                             object:nil];
  if (sender.tag == kModalTypeInputTextView) {
    [self.inputViewController showIndicator];
    self.inputViewController.navigationItem.rightBarButtonItem.enabled = NO;
    
    NSDictionary *data = [self.inputViewController data];
    NSDictionary *params = [self.inputViewController callbackParams];
    NSArray *arguments = [NSArray arrayWithObjects:data, params, nil];
    [self.handler callback:self.modalRightButtonCallback arguments:arguments];
  } else {
    [self displayLoadingIndicator:YES];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    if (self.modalRightButtonCallbackInfo) {
      NSString *namespace = [self.modalRightButtonCallbackInfo valueForKey:@"namespace"];
      NSString *method = [self.modalRightButtonCallbackInfo valueForKey:@"method"];
      [self.handler addCallback:namespace method:method];
    }
    [self.handler callback:self.modalRightButtonCallback params:nil];
  }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (buttonIndex != 0) {
    UIViewController *lastPresentedViewController = [[UIViewController greeLastPresentedViewController] retain];
    [lastPresentedViewController greeDismissViewControllerAnimated:YES completion:nil];
    [lastPresentedViewController release];
  }
}

@end
