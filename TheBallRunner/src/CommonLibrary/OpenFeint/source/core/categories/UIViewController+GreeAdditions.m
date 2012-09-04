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

#import "UIViewController+GreeAdditions.h"
#import "GreeDashboardViewController.h"
#import "GreeNotificationBoardViewController.h"
#import "UIViewController+GreeAdditions.h"
#import "GreeNotificationBoard+Internal.h"
#import "GreePlatform+Internal.h"
#import "GreeAuthorization.h"
#import "GreeCampaignCode.h"
#import "GreePopup.h"

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static char GreePresentationKey;
static char PopupKey;
static char PopupParentKey;
static char WidgetKey;

@interface UIViewController (GreeAdditionsInternal)
- (BOOL)greeIsPresenting;
- (void)greeNotifyDelegateWillDisplay;
- (void)greeNotifyDelegateDidDismiss;
@end

@implementation UIViewController (GreeAdditions)

#pragma mark Dashboard Methods

- (void)presentGreeDashboardWithBaseURL:(NSURL*)URL 
  delegate:(id<GreeDashboardViewControllerDelegate>)delegate 
  animated:(BOOL)animated 
  completion:(void(^)(void))completion
{  
  if ([[GreeAuthorization sharedInstance] handleBeforeAuthorize:GreeCampaignCodeServiceTypeDashboard]) {
    return;
  }  

  GreeDashboardViewController *dashboard = [[GreeDashboardViewController alloc] initWithBaseURL:URL];
  dashboard.dashboardDelegate = delegate;
  [self greePresentViewController:dashboard animated:YES completion:completion];
  [dashboard release];
}

- (void)dismissGreeDashboardAnimated:(BOOL)animated completion:(void(^)(id results))completion
{
  UIViewController *viewController = [self greePresentedViewController];
  
  if (![viewController isKindOfClass:[GreeDashboardViewController class]]) {
    return;
  }
  
  GreeDashboardViewController *dashboard = (GreeDashboardViewController*)viewController;
  __block id results = [dashboard.results retain];
  
  [self greeDismissViewControllerAnimated:animated completion:^{
    if (completion) {
      completion(results);
    }
    
    [results release];
  }];
}

- (void)dashboardCloseButtonPressed:(GreeDashboardViewController *)dashboardViewController
{
  [self dismissGreeDashboardAnimated:YES completion:nil];
}

#pragma mark Notification Board Methods

- (void)presentGreeNotificationBoardWithType:(GreeNotificationBoardLaunchType)type 
  parameters:(NSDictionary*)parameters 
  delegate:(id<GreeNotificationBoardViewControllerDelegate>)delegate 
  animated:(BOOL)animated 
  completion:(void(^)(void))completion 
{
  if (type == GreeNotificationBoardLaunchWithSns){
    if ([[GreeAuthorization sharedInstance] handleBeforeAuthorize:GreeCampaignCodeServiceTypeSNSNotificationBoard]) {
      return;
    }  
  } else {
    if ([[GreeAuthorization sharedInstance] handleBeforeAuthorize:GreeCampaignCodeServiceTypeGameNotificationBoard]) {
      return;
    }  
  }

  NSURL* URL = [GreeNotificationBoardViewController URLForLaunchType:type withParameters:parameters];
  GreeNotificationBoardViewController *viewController = [[GreeNotificationBoardViewController alloc] initWithURL:URL];
  viewController.delegate = delegate;
  [self greePresentViewController:viewController animated:animated completion:completion];
  [viewController release];
}

- (void)dismissGreeNotificationBoardAnimated:(BOOL)animated completion:(void(^)(id))completion
{
  UIViewController *viewController = [self greePresentedViewController];
  
  if (![viewController isKindOfClass:[GreeNotificationBoardViewController class]]) {
    return;
  }
  
  GreeNotificationBoardViewController *notificationBoard = (GreeNotificationBoardViewController*)viewController;
  __block id results = [notificationBoard.results retain];

  [self greeDismissViewControllerAnimated:animated completion:^{
    if (completion) {
      completion(results);
    }
    
    [results release];
  }];
}

- (void)notificationBoardCloseButtonPressed:(GreeNotificationBoardViewController *)notificationBoardController
{
  [self dismissGreeNotificationBoardAnimated:YES completion:nil];
}

#pragma mark Popup helper methods

- (GreePopup*)greeCurrentPopup
{
  GreePopup* popup = objc_getAssociatedObject(self, &PopupKey);

  if (!popup && [self isKindOfClass:[GreePopup class]]) {
    return (GreePopup*)self;
  }

  return [popup greeCurrentPopup];
}

- (void)greeAddPopup:(GreePopup *)popup
{
  UIViewController* parent = [self greeCurrentPopup];
  if (!parent) {
    parent = self;
  }

  objc_setAssociatedObject(parent, &PopupKey, popup, OBJC_ASSOCIATION_RETAIN_NONATOMIC);    
  objc_setAssociatedObject(popup, &PopupParentKey, parent, OBJC_ASSOCIATION_ASSIGN);
}

- (void)greeRemovePopup
{
  GreePopup* currentPopup = [self greeCurrentPopup];
  UIViewController* parent = objc_getAssociatedObject(currentPopup, &PopupParentKey);
  
  objc_setAssociatedObject(currentPopup, &PopupParentKey, nil, OBJC_ASSOCIATION_ASSIGN);  
  objc_setAssociatedObject(parent, &PopupKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark Widget helper methods

- (GreeWidget*)greeCurrentWidget
{
  return (GreeWidget*)objc_getAssociatedObject(self, &WidgetKey);
}

- (void)greeSetCurrentWidget:(GreeWidget*)widget
{
  objc_setAssociatedObject(self, &WidgetKey, widget, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark Notification helper methods

- (BOOL)greeShouldShowGreeNotification
{
  // We should show the notification if the view controller is a dashboard or a notification board or the view controller
  // is any view controller except one from GreePlatform.  The last is hard to detect, but the best way I have come up
  // with is to exclude those using the Gree namespace.
  
  return [self isKindOfClass:[GreeNotificationBoardViewController class]] ||
    [self isKindOfClass:[GreeDashboardViewController class]] ||
    ![NSStringFromClass([self class]) hasPrefix:@"Gree"];
}

#pragma mark Core Methods

- (void)greePresentViewController:(UIViewController*)viewController
  animated:(BOOL)animated
  completion:(void(^)(void))completion 
{
  UIInterfaceOrientation presentInterfaceOrientation;
  NSString *transitionDirection;
  
  if ([GreePlatform sharedInstance].manuallyRotate) {
    presentInterfaceOrientation = [GreePlatform sharedInstance].interfaceOrientation;
  } else {
    presentInterfaceOrientation = self.interfaceOrientation;
  }
    
  switch (presentInterfaceOrientation) {
    default:  // fall through to portrait if things go horribly wrong
    case UIInterfaceOrientationPortrait:
      transitionDirection = kCATransitionFromTop;
      break;
    case UIInterfaceOrientationPortraitUpsideDown:
      transitionDirection = kCATransitionFromBottom;
      break;
    case UIInterfaceOrientationLandscapeLeft:
      transitionDirection = kCATransitionFromRight;
      break;
    case UIInterfaceOrientationLandscapeRight:
      transitionDirection = kCATransitionFromLeft;
      break;
  }

  [CATransaction begin];
  [CATransaction begin];

  [CATransaction setCompletionBlock:completion];

  CATransition *transition = [CATransition animation];
  transition.type = kCATransitionMoveIn;
  transition.subtype = transitionDirection;
  transition.duration = animated ? 0.3f : 0.0f;
  transition.fillMode = kCAFillModeForwards;
  transition.removedOnCompletion = YES;
  
  [self.view.window.layer addAnimation:transition forKey:@"transition"];        
  
  [CATransaction commit];
  
  [self presentModalViewController:viewController animated:NO];
  
  if ([viewController isKindOfClass:[GreeDashboardViewController class]] ||
      [viewController isKindOfClass:[GreeNotificationBoardViewController class]]) {
    viewController.view.frame = [[UIScreen mainScreen] applicationFrame];
  }
  
  [CATransaction commit];
  
  // mark viewController as being Gree-presented
  objc_setAssociatedObject(viewController, &GreePresentationKey, [GreePlatform sharedInstance], OBJC_ASSOCIATION_ASSIGN);
  [self greeNotifyDelegateWillDisplay];
}

- (void)greeDismissViewControllerAnimated:(BOOL)animated
  completion:(void(^)(void))completion 
{
  UIViewController* toBeDismissed = [self greePresentedViewController];
  
  if (toBeDismissed == nil) {
    toBeDismissed = self;
  }
  
  UIViewController *presentingViewController = [toBeDismissed greePresentingViewController];

  // Since we are not using an animation, the toBeDismissed view controller will be deallocated immediately.  We do
  // want this behavior, however, we need it to stay in memory until the animation is completed.
  [toBeDismissed retain];
  
  UIInterfaceOrientation dismissInterfaceOrientation;
  NSString *transitionDirection;
  
  if ([GreePlatform sharedInstance].manuallyRotate) {
    dismissInterfaceOrientation = [GreePlatform sharedInstance].interfaceOrientation;
  } else {
    dismissInterfaceOrientation = toBeDismissed.interfaceOrientation;
  }
    
  switch (dismissInterfaceOrientation) {
    default:  // fall through to portrait if things go horribly wrong
    case UIInterfaceOrientationPortrait:
      transitionDirection = kCATransitionFromBottom;
      break;
    case UIInterfaceOrientationPortraitUpsideDown:
      transitionDirection = kCATransitionFromTop;
      break;
    case UIInterfaceOrientationLandscapeLeft:
      transitionDirection = kCATransitionFromLeft;
      break;
    case UIInterfaceOrientationLandscapeRight:
      transitionDirection = kCATransitionFromRight;
      break;
  }
  
  [CATransaction begin];
  [CATransaction setCompletionBlock:^{
    [toBeDismissed release];

    // clear toBeDismissed as being Gree-presented (just incase it's recycled)
    objc_setAssociatedObject(toBeDismissed, &GreePresentationKey, nil, OBJC_ASSOCIATION_ASSIGN);
    [self greeNotifyDelegateDidDismiss];
    
    if (completion) {
      completion();
    }
  }];
    
  CATransition *transition = [CATransition animation];
  transition.type = kCATransitionReveal;
  transition.subtype = transitionDirection;
  transition.duration = animated ? 0.3f : 0.0f;
  transition.fillMode = kCAFillModeForwards;
  transition.removedOnCompletion = YES;
    
  [toBeDismissed.view.window.layer addAnimation:transition forKey:@"transition"];        
    
  [self dismissModalViewControllerAnimated:NO];

  if (([presentingViewController isKindOfClass:[GreeDashboardViewController class]]) ) {
    presentingViewController.view.frame = [[UIScreen mainScreen] applicationFrame];
  }

  [CATransaction commit];
}

+ (UIViewController*)greeLastPresentedViewController
{
  UIWindow *window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
  UIViewController *rootViewController = [window rootViewController];
  return [rootViewController greeLastPresentedViewController];
}

- (UIViewController*)greeLastPresentedViewController 
{
  UIViewController *parentController = self;
  UIViewController *modalController = [parentController greePresentedViewController];
  
  while (modalController != nil) {
    parentController = modalController;
    modalController = [parentController greePresentedViewController];
  }

  return parentController;
}

- (UIViewController*)greePresentingViewController
{
  SEL parentSelector = @selector(parentViewController);
  
  if ([self respondsToSelector:@selector(presentingViewController)]) {
    parentSelector = @selector(presentingViewController);
  }
  
  return [self performSelector:parentSelector];
}

- (UIViewController*)greePresentedViewController
{
  SEL modalSelector = @selector(modalViewController);
  
  if ([self respondsToSelector:@selector(presentedViewController)]) {
    modalSelector = @selector(presentedViewController);
  }
  
  return [self performSelector:modalSelector];
}

#pragma mark Core internal methods

- (BOOL)greeIsPresenting
{
  id token = objc_getAssociatedObject([GreePlatform sharedInstance], &GreePresentationKey);
  return token != nil;
}

- (void)greeNotifyDelegateWillDisplay
{
  if (![self greeIsPresenting] && ![self greeCurrentPopup]) {
    [[[GreePlatform sharedInstance] delegate] greePlatformWillShowModalView:[GreePlatform sharedInstance]];
  }
}

- (void)greeNotifyDelegateDidDismiss
{
  if (![self greeIsPresenting] && ![self greeCurrentPopup]) {
    [[[GreePlatform sharedInstance] delegate] greePlatformDidDismissModalView:[GreePlatform sharedInstance]];
  }
}

@end
