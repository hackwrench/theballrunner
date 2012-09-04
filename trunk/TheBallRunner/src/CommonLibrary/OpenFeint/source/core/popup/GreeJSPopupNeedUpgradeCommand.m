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


#import "GreeAuthorization.h"
#import "GreeJSPopupNeedUpgradeCommand.h"
#import "GreePopup.h"
#import "GreePopupView.h"
#import "UIViewController+GreeAdditions.h"
#import "UIViewController+GreePlatform.h"


#define kGreeJSPopupNeedUpgradeCommand @"callback"


@interface GreeJSPopupNeedUpgradeCommand ()
@property (nonatomic, assign) BOOL haveBeenDismissed;
@property BOOL isValid;
- (void)succeeded:(NSDictionary*)parameters;
- (void)failed:(NSDictionary*)parameters;
- (void)greePopupDidDismissNotification:(NSNotification*)aNotification;
- (void)needUpgradeCallback:(NSDictionary*)parameters;
@end


@implementation GreeJSPopupNeedUpgradeCommand
@synthesize haveBeenDismissed = _haveBeenDismissed;
@synthesize isValid = _isValid;


#pragma mark - Object Lifecycle

- (id)init
{
  self = [super init];
  if (self) {
    _haveBeenDismissed = NO;
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(greePopupDidDismissNotification:)
     name:GreePopupDidDismissNotification
     object:nil];
  }
  
  return self;
}

- (void)dealloc {
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  _isValid = NO;
  
  [super dealloc];
}


#pragma mark - GreeJSCommand Overrides

+ (NSString*)name
{
  return @"need_upgrade";
}

- (void)execute:(NSDictionary*)params
{
  __block id selfRef = self;
  _isValid = YES;

  [[GreeAuthorization sharedInstance]
   upgradeWithParams:params
   successBlock:^{
     if (_isValid) {
      //Without delaytime, get request is sent instead of post when reloading post request.
      [selfRef performSelector:@selector(succeeded:) withObject:params afterDelay:0.5f];
     }
   }
   failureBlock:^{
    if (_isValid) {
      [selfRef performSelector:@selector(failed:) withObject:params afterDelay:0.f];
    }
   }];
}


#pragma mark - NSObject Overrides

- (NSString*)description
{  
  return [NSString stringWithFormat:@"<%@:%p retain:%d>",
          NSStringFromClass([self class]), self, self.retainCount];
}


#pragma mark - Internal Methods

- (void)succeeded:(NSDictionary*)parameters
{
  if ([parameters objectForKey:kGreeJSPopupNeedUpgradeCommand]) {
    NSMutableDictionary* results = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [results setObject:@"success" forKey:@"result"];
    [self needUpgradeCallback:results];
  } else {
    [[self.environment webviewForCommand:self] reload];
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self name:GreePopupDidDismissNotification object:nil];
  [self callback];
}

- (void)failed:(NSDictionary*)parameters
{
  if ([parameters objectForKey:kGreeJSPopupNeedUpgradeCommand]) {
    NSMutableDictionary* results = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [results setObject:@"fail" forKey:@"result"];
    [self needUpgradeCallback:results];
  } else {
    UIViewController* aViewController = [self.environment viewControllerForCommand:self];
    if ([aViewController isKindOfClass:[GreePopup class]]) {
      GreePopup* aPopup = (GreePopup*)self.environment;
      if (!self.haveBeenDismissed &&
          [aPopup.popupView.delegate respondsToSelector:@selector(popupViewDidCancel)]) {
        [aPopup.popupView.delegate popupViewDidCancel];
      }
    } else if ([aViewController isKindOfClass:NSClassFromString(@"GreeNotificationBoardViewController")]) {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [[UIViewController greeLastPresentedViewController] greeDismissViewControllerAnimated:YES completion:nil];
      });
    } else {
      // no thing for dashboard
    }
  }

  [[NSNotificationCenter defaultCenter] removeObserver:self name:GreePopupDidDismissNotification object:nil];
  [self callback];
}

- (void)greePopupDidDismissNotification:(NSNotification*)aNotification
{
  id aSender = [aNotification.userInfo objectForKey:@"sender"];
  if (aSender == self.environment) {
    self.haveBeenDismissed = YES;
  }
}

- (void)needUpgradeCallback:(NSDictionary*)parameters
{
  [[self.environment handler] callback:[parameters objectForKey:kGreeJSPopupNeedUpgradeCommand] params:parameters];
}
@end
