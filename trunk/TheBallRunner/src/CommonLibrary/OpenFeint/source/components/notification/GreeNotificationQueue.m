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

#import "GreeNotificationQueue.h"
#import "GreeNotificationContainerView.h"
#import "GreeNotificationView.h"
#import "GreeNotification+Internal.h"
#import "GreeDashboardViewController.h"
#import "GreeNotificationBoardViewController.h"
#import "GreeJSExternalWebViewController.h"
#import "GreeJSWebViewController.h"
#import "UIImage+GreeAdditions.h"
#import "GreeSettings.h"
#import "GreePlatform+Internal.h"
#import "GreeDashboardViewControllerLaunchMode.h"
#import "UIViewController+GreeAdditions.h"
#import "UIViewController+GreePlatform.h"
#import "UIView+GreeAdditions.h"

#define HALF_OF(x) (x / 2.0f)

/**
 * We match a GreeNotificationView to a GreeNotification using the notification's index
 * in the array.  A UIView should not have a tag of 0, however, so we use this macro to
 * make the adjustment. 
 */
#define TAG_FROM_INDEX(x) x+1

#define DEGREES_TO_RADIANS(x) M_PI * (x) / 180.0

@interface GreeNotificationQueue ()
@property (nonatomic, readonly, retain) NSMutableArray* notifications;
@property (nonatomic, readonly, retain)  GreeNotificationContainerView* notificationContainerView;
@property (nonatomic, readonly, retain) NSTimer* notificationDisplayDurationTimer;
@property (nonatomic, readonly, assign) BOOL showingNextNotificationView;
@property (nonatomic, readonly, assign) BOOL removingNotificationContainerView;

- (void)createAndDisplayNotificationContainerView;
- (void)addNotificationViewAtIndex:(NSUInteger)anIndex;
- (void)scheduleNotificationChange;
- (void)notificationFinishedDisplaying;
- (void)showNotificationViewAnimated:(BOOL)animated;
- (void)showNextNotificationAnimated:(BOOL)animated;
- (void)removeNotificationViewAnimated:(BOOL)animated;
@end

@interface GreePlatform (GreeNotificationsInternal)
- (id)rawNotificationQueue;
@end

@implementation GreeNotificationQueue

@synthesize displayPosition = _displayPosition;

@synthesize notifications = _notifications;
@synthesize notificationContainerView = _notificationContainerView;
@synthesize notificationDisplayDurationTimer = _notificationDisplayDurationTimer;
@synthesize showingNextNotificationView = _showingNextNotificationView;
@synthesize removingNotificationContainerView = _removingNotificationContainerView;
@synthesize notificationsEnabled = _notificationsEnabled;

#pragma mark - Object Lifecycle

- (id)initWithSettings:(GreeSettings*)settings
{
  if ((self = [super init])) {
    _notifications = [[NSMutableArray alloc] initWithCapacity:8];
    _displayPosition = GreeNotificationDisplayTopPosition;
    
    _removingNotificationContainerView = NO;
    _showingNextNotificationView = NO;
    
    _notificationsEnabled = YES;

    if([settings settingHasValue:GreeSettingNotificationPosition]) {
      _displayPosition = [settings integerValueForSetting:GreeSettingNotificationPosition];
    }

    if([settings settingHasValue:GreeSettingNotificationEnabled]) {
      _notificationsEnabled = [settings boolValueForSetting:GreeSettingNotificationEnabled];
    }
  }
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [_notificationDisplayDurationTimer invalidate];
  _notificationDisplayDurationTimer = nil;

  [_notificationContainerView greeRemoveRotatingSubviewFromSuperview];
  [_notificationContainerView release];
  
  [_notifications release];

  [super dealloc];
}

#pragma mark - Public Interface

- (void)addNotification:(GreeNotification*)notification
{
  UIViewController *lastPresentedViewController = [UIViewController greeLastPresentedViewController];

  if (!self.notificationsEnabled || ![lastPresentedViewController greeShouldShowGreeNotification]) {
    return;
  }

  __block GreeNotificationQueue *queue = self;

  //will be added when the icon is loaded, errors are currently being ignored
  [notification loadIconWithBlock:^(NSError *error) {
    [queue.notifications addObject:notification];
    if (queue.notifications.count == 1) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [queue createAndDisplayNotificationContainerView];
      });
    }
  }];
}

- (void)setDisplayPosition:(GreeNotificationDisplayPosition)aDisplayPosition
{
  _displayPosition = aDisplayPosition;
}

#pragma mark - NSObject overrides
- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, notification count:%d, displayPosition:%@>",
            NSStringFromClass([self class]),
            self,
            [self.notifications count],
            NSStringFromGreeNotificationDisplayPosition(self.displayPosition)];
}

#pragma mark - Internal Methods
- (void)createAndDisplayNotificationContainerView
{
  NSAssert(_notificationContainerView == nil, @"Trying to display a new notification view while it is already being displayed");
  NSAssert([self.notifications count] > 0, @"Displaying a notification view without any notifications.");
    
  _notificationContainerView = [[GreeNotificationContainerView alloc] initWithDisplayPosition:self.displayPosition];    
  _notificationContainerView.alpha = 0.0f;
  
  
  UIViewController *viewController = [UIViewController greeLastPresentedViewController];
  [viewController.view greeAddRotatingSubview:_notificationContainerView relativeToInterfaceOrientation:viewController.interfaceOrientation];
  
  [self addNotificationViewAtIndex:0];
  [self showNotificationViewAnimated:YES];
  [self scheduleNotificationChange];
}

- (void)addNotificationViewAtIndex:(NSUInteger)anIndex
{
  NSAssert([self.notifications count] > anIndex, @"The notification index is higher than the number of notifications");

  CGSize containerSize = _notificationContainerView.contentView.frame.size;

  GreeNotification *notification = [self.notifications objectAtIndex:anIndex];
    
  GreeNotificationView *notificationView = [[GreeNotificationView alloc]
    initWithMessage:notification.message
    icon:notification.iconImage
    frame:CGRectMake(0.0f, -containerSize.height * anIndex, containerSize.width, containerSize.height)];
   
  notificationView.tag = TAG_FROM_INDEX(anIndex);
  
  notificationView.logoView.hidden = !notification.showLogo;
  notificationView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
  
  if (notification.displayType == GreeNotificationViewDisplayCloseType) {
    notificationView.showsCloseButton = YES;
  }
    
  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] 
    initWithTarget:self
    action:@selector(notificationViewTapped:)
  ];
  
  tapGestureRecognizer.delegate = self;
  [notificationView addGestureRecognizer:tapGestureRecognizer];
  [tapGestureRecognizer release];
  
  [notificationView.closeButton
    addTarget:self
    action:@selector(closeButtonPressed:)
    forControlEvents:UIControlEventTouchUpInside];
  
  [_notificationContainerView.contentView addSubview:notificationView];
  [notificationView release];
}

- (void)scheduleNotificationChange
{
  NSAssert([self.notifications count] > 0, @"Scheduling a notification queue change with no notifications.");
  
  GreeNotification *notification = [self.notifications objectAtIndex:0];
  
  if (notification.duration < GreeNotificationInfiniteDuration) {
    _notificationDisplayDurationTimer = [NSTimer scheduledTimerWithTimeInterval:notification.duration
                                          target:self
                                          selector:@selector(notificationFinishedDisplaying)
                                          userInfo:nil
                                          repeats:NO];
  }
}

- (void)notificationFinishedDisplaying
{
  NSAssert([self.notifications count] > 0, @"Updating notification view with no notifications.");
  _notificationDisplayDurationTimer = nil;

  if ([self.notifications count] > 1) {
    [self addNotificationViewAtIndex:1];
    [self showNextNotificationAnimated:YES];
  } else {
    [self removeNotificationViewAnimated:YES];
  }
}

- (void)showNotificationViewAnimated:(BOOL)animated
{
  void(^viewChanges)(void) = ^{
    _notificationContainerView.alpha = 1.0f;
  };

  if (animated) {
    [UIView animateWithDuration:0.5f
      animations:viewChanges];
  } else {
    viewChanges();
  }
}

- (void)showNextNotificationAnimated:(BOOL)animated
{
  if (_showingNextNotificationView) {
    return;
  }
  
  NSAssert([self.notifications count] > 1, @"Switching notifications without two notifications in the queue");
  
  _showingNextNotificationView = YES;

  GreeNotificationView *currentView = (GreeNotificationView*) [_notificationContainerView viewWithTag:TAG_FROM_INDEX(0)];
  GreeNotificationView *nextView = (GreeNotificationView*) [_notificationContainerView viewWithTag:TAG_FROM_INDEX(1)];
  
  void(^viewChanges)(void) = ^{
    currentView.frame = CGRectMake(
      0.0f,
      currentView.bounds.size.height,
      currentView.bounds.size.width,
      currentView.bounds.size.height
    );
    nextView.frame = CGRectMake(
      0.0f,
      0.0f,
      nextView.bounds.size.width,
      nextView.bounds.size.height
    );
  };
  
  void(^completionHandler)(BOOL) = ^(BOOL finished) {
    [currentView removeFromSuperview];
    nextView.tag = TAG_FROM_INDEX(0);
    [self.notifications removeObjectAtIndex:0];
    [self scheduleNotificationChange];
    _showingNextNotificationView = NO;
  };
  
  if (animated) {
    [UIView animateWithDuration:0.5f
      delay:0.0f
      options:0
      animations:viewChanges
      completion:completionHandler];
  } else {
    viewChanges();
    completionHandler(YES);
  }
}
   
- (void)removeNotificationViewAnimated:(BOOL)animated
{
  if (_removingNotificationContainerView) {
    return;
  }
  
  NSAssert([self.notifications count] > 0, @"Removing the notification container without having displayed the last notification");

  _removingNotificationContainerView = YES;

  void(^viewChanges)(void) = ^{
    _notificationContainerView.alpha = 0.0f;
  }; 
  
  void(^completionHandler)(BOOL) = ^(BOOL finished) {
    [_notificationContainerView greeRemoveRotatingSubviewFromSuperview];
    [_notificationContainerView release];
    _notificationContainerView = nil;
    
    [self.notifications removeObjectAtIndex:0];
    
    if ([self.notifications count] > 0) {
      [self createAndDisplayNotificationContainerView];
    }

    _removingNotificationContainerView = NO;
  };

  if (animated) {
    [UIView animateWithDuration:0.5f
      delay:0.0f
      options:0
      animations:viewChanges
      completion:completionHandler
    ];
  } else {
    viewChanges();
    completionHandler(YES);
  }
}

//NOTE: called by use of performSelector from GreePlatform
-(void)generateLoginNotificationWithNickname:(NSString*)nickname
{
  dispatch_async(dispatch_get_main_queue(),
    ^{
      [self addNotification:[GreeNotification notificationForLoginWithUsername:nickname]];
    }
  );
}

//NOTE: called by use of performSelector from GreePlatform
- (id)handleRemoteNotification:(NSDictionary *)notificationDictionary
{
  GreeNotification *notification = [GreeNotification notificationWithAPSDictionary:notificationDictionary];
  [[[GreePlatform sharedInstance] notificationQueue] addNotification:notification];
  return notification;
}

#pragma mark - UIGestureRecognizer target method
- (void)notificationViewTapped:(UIGestureRecognizer*)gestureRecognizer
{
  NSAssert([self.notifications count] > 0, @"Notification tapped but notification does not exist");
  NSDictionary* info = [[self.notifications objectAtIndex:0] infoDictionary];
  NSString* type = [info objectForKey:@"type"];
  gestureRecognizer.enabled = NO;
    
  if([type isEqualToString:@"dash"]) {
    int subType = [[info objectForKey:@"subtype"] intValue];
    NSDictionary* parameters = nil;

    switch (subType) {
      case GreeNotificationSourceMyLogin:
      {
        NSString *urlString = [NSString stringWithFormat:@"%@%@", [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingServerUrlSns], [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingMyLoginNotificationPath]];
        NSURL* url = [NSURL URLWithString:urlString];
        UIViewController *viewController = [[[[UIApplication sharedApplication]
          keyWindow] rootViewController] greeLastPresentedViewController];
        [viewController
          presentGreeDashboardWithBaseURL:url 
          delegate:viewController
          animated:YES
          completion:nil];
        break;
      }
      case GreeNotificationSourceFriendLogin:
      {
        NSString *urlString = [NSString stringWithFormat:@"%@%@&user_id=%@", [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingServerUrlSns], [[GreePlatform sharedInstance].settings objectValueForSetting:GreeSettingFriendLoginNotificationPath], [info objectForKey:@"actor_id"]];
        NSURL* url = [NSURL URLWithString:urlString];
        UIViewController *viewController = [[[[UIApplication sharedApplication]
          keyWindow] rootViewController] greeLastPresentedViewController];
        [viewController
          presentGreeDashboardWithBaseURL:url 
          delegate:viewController
          animated:YES
          completion:nil];
        break;
      }
      case GreeNotificationSourceMyAchievementUnlocked:
      {
        parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                      GreeDashboardModeAchievementList, GreeDashboardMode,                                 
                      nil];
        [[UIViewController greeLastPresentedViewController] presentGreeDashboardWithParameters:parameters animated:YES];
        break;
      }        
      case GreeNotificationSourceFriendAchievementUnlocked:
      {
        parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                      GreeDashboardModeAchievementList, GreeDashboardMode,                                 
                      [info objectForKey:@"actor_id"], GreeDashboardUserId,
                      nil];
        [[UIViewController greeLastPresentedViewController] presentGreeDashboardWithParameters:parameters animated:YES];
        break;
      }        
      case GreeNotificationSourceMyHighScore:
      {
        parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                      GreeDashboardModeRankingDetails, GreeDashboardMode,
                      [info objectForKey:@"cid"], GreeDashboardLeaderboardId,
                      nil];
        [[UIViewController greeLastPresentedViewController] presentGreeDashboardWithParameters:parameters animated:YES];
        break;
      }
      case GreeNotificationSourceFriendHighScore:
      {
        parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                      GreeDashboardModeRankingDetails, GreeDashboardMode,                                 
                      [info objectForKey:@"actor_id"], GreeDashboardUserId,
                      [info objectForKey:@"cid"], GreeDashboardLeaderboardId,
                      nil];
        [[UIViewController greeLastPresentedViewController] presentGreeDashboardWithParameters:parameters animated:YES];
        break;
      }
      default:
        break;
    }
  } else if([type isEqualToString:@"message"]) {
    UIViewController *viewController = [[[[UIApplication sharedApplication]
      keyWindow] rootViewController] greeLastPresentedViewController];
    [viewController presentGreeNotificationBoardWithType:GreeNotificationBoardLaunchWithMessageDetail
      parameters:info
      delegate:viewController
      animated:YES
      completion:nil];
  } else if([type isEqualToString:@"request"]) {
    UIViewController *viewController = [[[[UIApplication sharedApplication]
      keyWindow] rootViewController] greeLastPresentedViewController];
    [viewController presentGreeNotificationBoardWithType:GreeNotificationBoardLaunchWithRequestDetail
      parameters:info
      delegate:viewController
      animated:YES
      completion:nil];
  }
}

#pragma mark - UIGestureRecognizer delegate method
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  GreeNotificationView *currentView = (GreeNotificationView*) [_notificationContainerView viewWithTag:TAG_FROM_INDEX(0)];

  if ([touch.view isDescendantOfView:currentView.closeButton]) {
    return NO;
  }
  
  return YES;
}

- (void)closeButtonPressed:(id)sender
{
  [_notificationDisplayDurationTimer invalidate];
  _notificationDisplayDurationTimer = nil;
  
  if ([self.notifications count] > 0) {
    [self notificationFinishedDisplaying];
  }
}

@end

@implementation GreePlatform (GreeNotifications)
- (GreeNotificationQueue*)notificationQueue
{
  return (GreeNotificationQueue*)[self rawNotificationQueue];  //rather circular, isn't it?
}
@end


