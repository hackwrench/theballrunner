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

#import "UIViewController+GreePlatform.h"
#import "UIViewController+GreeAdditions.h"
#import "UIView+GreeAdditions.h"
#import "GreePopup+Internal.h"
#import "GreeWidget+Internal.h"
#import "GreePlatform+Internal.h"
#import "GreeDashboardViewController.h"
#import "GreeAuthorization.h"
#import "GreeCampaignCode.h"
#import "GreeAuthorizationPopup.h"

static GreeNotificationBoardLaunchType sTypeMap[GreeNotificationBoardTypeSNS+1] = {
  GreeNotificationBoardLaunchWithPlatform,
  GreeNotificationBoardLaunchWithSns
};

@interface UIViewController (GreeAdditionsInternal)
- (void)greeNotifyDelegateWillDisplay;
- (void)greeNotifyDelegateDidDismiss;
@end

@implementation UIViewController (GreePlatform)

- (void)presentGreeDashboardWithParameters:(NSDictionary*)parameters animated:(BOOL)animated
{
  NSURL* dashboardURL = [GreeDashboardViewController dashboardURLWithParameters:parameters];
  [self presentGreeDashboardWithBaseURL:dashboardURL delegate:self animated:animated completion:nil];
}

- (void)presentGreeNotificationBoardWithType:(GreeNotificationBoardType)type animated:(BOOL)animated
{
  [self 
    presentGreeNotificationBoardWithType:sTypeMap[type]
    parameters:nil 
    delegate:self 
    animated:YES 
    completion:nil];
}

- (void)dismissActiveGreeViewControllerAnimated:(BOOL)animated
{
  [self dismissGreeDashboardAnimated:animated completion:nil];
  [self dismissGreeNotificationBoardAnimated:animated completion:nil];
}

#pragma mark GreePopup Display Methods

- (void)showGreePopup:(GreePopup*)popup
{
  GreePopup *currentPopup = [self greeCurrentPopup];

  if (currentPopup != nil) {
    popup.hostViewController = currentPopup.hostViewController;
    currentPopup.popupView.containerView.hidden = YES;
  } else {
    popup.hostViewController = self;
  }

  if(![popup isKindOfClass:[GreeAuthorizationPopup class]]){
    NSString* campaignCode = nil;
    if ([popup.action isEqualToString:GreePopupShareAction]) campaignCode = GreeCampaignCodeServiceTypeShare;
    if ([popup.action isEqualToString:GreePopupInviteAction]) campaignCode = GreeCampaignCodeServiceTypeInvite;
    if ([popup.action isEqualToString:GreePopupRequestServiceAction]) campaignCode = GreeCampaignCodeServiceTypeRequest;

    if (campaignCode != nil && [[GreeAuthorization sharedInstance] handleBeforeAuthorize:campaignCode]) {
      return;
    }  
  }
  
  GreePopupBlock originalWillDismissBlock = popup.willDismissBlock;
  GreePopupBlock originalDidDismissBlock = popup.didDismissBlock;
  
  popup.view.frame = self.view.bounds;
  
  popup.willDismissBlock = ^(GreePopup *sender) {
    currentPopup.popupView.containerView.hidden = NO;
  
    if (originalWillDismissBlock) {
      originalWillDismissBlock(sender);
    }
  };
  
  popup.didDismissBlock = ^(GreePopup *sender) {
    if (originalDidDismissBlock) {
      originalDidDismissBlock(sender);
    }
  
    [sender.view greeRemoveRotatingSubviewFromSuperview];

    [sender.hostViewController greeNotifyDelegateDidDismiss];
    [sender.hostViewController greeRemovePopup];
  };
  
  [self greeNotifyDelegateWillDisplay];
    
  [self.view greeAddRotatingSubview:popup.view relativeToInterfaceOrientation:self.interfaceOrientation];
  [self greeAddPopup:popup];
  [popup show];
}

- (void)dismissGreePopup
{
  GreePopup *popup = [self greeCurrentPopup];
  [popup dismiss];
}

#pragma mark GreeWidget Display Methods
- (void)showGreeWidgetWithDataSource:(id<GreeWidgetDataSource>)dataSource
{
  //lazy initialize the widget
  if (![self greeCurrentWidget]) {
    GreeWidget* widget = [[GreeWidget alloc] initWithSettings:[[GreePlatform sharedInstance] settings]];
    widget.dataSource = dataSource;
    widget.hostViewController = self;
    [self greeSetCurrentWidget:widget];
    [widget release];
  }else {
    if ([self greeCurrentWidget].dataSource != dataSource) {
      [self greeCurrentWidget].dataSource = dataSource;
    }
  }
  if ([self greeCurrentWidget].superview == nil) {
    [self.view greeAddRotatingSubview:[self greeCurrentWidget] relativeToInterfaceOrientation:self.interfaceOrientation];
  }
}

- (void)hideGreeWidget
{
  [[self greeCurrentWidget] greeRemoveRotatingSubviewFromSuperview];
}

- (GreeWidget*)activeGreeWidget
{
  if ([self greeCurrentWidget] && [[self greeCurrentWidget] superview] != nil) {
    return [self greeCurrentWidget];
  }else {
    return nil;
  }
}

@end
