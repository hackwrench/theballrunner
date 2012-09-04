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

#import "InviteViewController.h"
#import "UIColor+ShowCaseAdditions.h"
#import "GreePopup.h"
#import "GreePlatform.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+ShowCaseAdditions.h"
#import "UIViewController+GreePlatform.h"
#import "AppDelegate.h"
#import "CustomScrollView.h"

@interface InviteViewController()
@end

@implementation InviteViewController
@synthesize inviteMessageField = _inviteMessageField;
@synthesize showInviteButton = _showInviteButton;
@synthesize scrollView = _scrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)dealloc
{
  [_inviteMessageField release];
  [_showInviteButton release];
  [_scrollView release];
  [super dealloc];
}

- (void)didReceiveMemoryWarning
{
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);

  self.title = NSLocalizedStringWithDefaultValue(@"inviteController.title.label", @"GreeShowCase", [NSBundle mainBundle], @"Invites", @"invite controller title");
  self.inviteMessageField.layer.cornerRadius = 8.f;
  
  UIImage* btnImage = [UIImage imageNamed:@"btn_uniform.png"];
  [self.showInviteButton setBackgroundImage:[btnImage showcaseResizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)] forState:UIControlStateNormal];
  
  self.navigationController.navigationBar.tintColor = [UIColor showcaseNavigationBarColor];
  [self addTextFieldList:[NSArray arrayWithObjects:self.inviteMessageField, nil]];
}

- (void)viewDidUnload
{
  [self setShowInviteButton:nil];
  [self setScrollView:nil];
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *) event 
{
  [self dismissKeyboard];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(greePopupDidLaunchNotification:) name:GreePopupDidLaunchNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(greePopupDidDismissNotification:) name:GreePopupDidDismissNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return YES;
}

-(void)greePopupDidLaunchNotification:(NSNotification *)aNotification
{
	NSLog(@"%s", __FUNCTION__);
}

-(void)greePopupDidDismissNotification:(NSNotification *)aNotification
{
	NSLog(@"%s", __FUNCTION__);
}

- (IBAction)inviteButtonClicked:(id)sender {
  NSString* message = [_inviteMessageField text];
  [self dismissKeyboard];
  
  GreeInvitePopup* invitePopup = [GreeInvitePopup popup];
  NSString* aBodyString = message;
  
  if (0 < [aBodyString length]) {
    invitePopup.message = aBodyString;
  }
  
  invitePopup.willLaunchBlock = ^(GreePopup* aSender) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"invite_popup_will_launch_block" object:nil];
    [self disableKeyboardObservation];
  };
  invitePopup.didLaunchBlock = ^(GreePopup* aSender) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"invite_popup_did_launch_block" object:nil];
  };
  invitePopup.willDismissBlock = ^(GreePopup* aSender) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"invite_popup_will_dismiss_block" object:nil];
  };
  invitePopup.didDismissBlock = ^(GreePopup* aSender) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"invite_popup_did_dismiss_block" object:nil];
    [self enableKeyboardObservation];
  };
  invitePopup.cancelBlock = ^(GreePopup* aSender) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"invite_popup_cancel_block" object:nil];
  };
  invitePopup.completeBlock = ^(GreePopup* aSender) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"invite_popup_complete_block" object:nil];
    NSLog(@"%s thePopup.results:%@", __FUNCTION__, [aSender results]);
  };
  [self.navigationController showGreePopup:invitePopup];
}


@end
