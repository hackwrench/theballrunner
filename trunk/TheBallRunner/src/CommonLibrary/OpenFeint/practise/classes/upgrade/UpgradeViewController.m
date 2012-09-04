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

#import "UpgradeViewController.h"
#import "GreeUser.h"
#import "GreePlatform.h"
#import "UIColor+ShowCaseAdditions.h"
#import "GreeNSNotification.h"

@interface UpgradeViewController ()
- (void)refresh;
@property (nonatomic, retain) UIColor* defaultButtonColor;
@end

@implementation UpgradeViewController

#pragma mark - Object Lifecycle
@synthesize upgrade2Button = _upgrade2Button;
@synthesize upgrade3Button = _upgrade3Button;
@synthesize currentGradeLabel = _currentGradeLabel;
@synthesize scrollView = _scrollView;
@synthesize defaultButtonColor = _defaultButtonColor;

- (void)dealloc
{
  [_upgrade2Button release];
  [_upgrade3Button release];
  [_currentGradeLabel release];
  [_defaultButtonColor release];
  [_scrollView release];
  [super dealloc];
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
  self.defaultButtonColor = self.upgrade2Button.titleLabel.textColor;
  self.title = NSLocalizedStringWithDefaultValue(@"upgradeController.title.label", @"GreeShowCase", [NSBundle mainBundle], @"Upgrade", @"upgrade controller title");
  self.navigationController.navigationBar.tintColor = [UIColor showcaseNavigationBarColor];
  [self refresh];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  [self refresh];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return YES;
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(refresh)
                                               name:GreeNSNotificationKeyDidUpdateLocalUserNotification
                                             object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                  name:GreeNSNotificationKeyDidUpdateLocalUserNotification
                                                object:nil];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *) event 
{
  [self dismissKeyboard];
}

#pragma mark - Public Interface

#pragma mark - ShowcaseBaseViewController Overrides

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([self class]), self];
}

#pragma mark - Internal Methods

- (void)refresh
{
  GreeUserGrade currentGrade = [GreePlatform sharedInstance].localUser.userGrade;
  
  NSString* currentLabel = NSLocalizedStringWithDefaultValue(@"upgradeController.currentGrade.label", @"GreeShowCase", [NSBundle mainBundle], @"Current Grade:%d", @"(%d) will be replaced with a number");
  self.currentGradeLabel.text = [NSString stringWithFormat:currentLabel, currentGrade];
  
  BOOL button2Enabled = (currentGrade == GreeUserGradeLite);
  self.upgrade2Button.enabled = button2Enabled;
  self.upgrade2Button.titleLabel.textColor = button2Enabled ? self.defaultButtonColor : [UIColor colorWithWhite:0.7f alpha:1.0f];

  BOOL button3Enabled = (currentGrade == GreeUserGradeLimited || currentGrade == GreeUserGradeLite);
  self.upgrade3Button.enabled = button3Enabled;
  self.upgrade3Button.titleLabel.textColor = button3Enabled ? self.defaultButtonColor : [UIColor colorWithWhite:0.7f alpha:1.0f];
}

- (void)viewDidUnload {
  [self setUpgrade2Button:nil];
  [self setUpgrade3Button:nil];
    
  [self setCurrentGradeLabel:nil];
  [self setScrollView:nil];
  [super viewDidUnload];
}

- (IBAction)upgrade2:(id)sender 
{
  [GreePlatform upgradeWithParams:[NSDictionary dictionaryWithObject:@"2" forKey:@"target_grade"] 
  successBlock:^{
    NSLog(@"%s upgrade2 results:successed", __FUNCTION__);
  }
  failureBlock:^{
  }];
}

- (IBAction)upgrade3:(id)sender 
{
  [GreePlatform upgradeWithParams:[NSDictionary dictionaryWithObject:@"3" forKey:@"target_grade"]
  successBlock:^{
    NSLog(@"%s upgrade3 results:successed", __FUNCTION__);
  }
  failureBlock:^{
  }];
}

@end
