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

#import "ShareViewController.h"
#import "GreePopup.h"
#import <QuartzCore/QuartzCore.h>
#import "GreePlatform.h"
#import "UIColor+ShowCaseAdditions.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+ShowCaseAdditions.h"
#import "AppDelegate.h"
#import "UIViewController+GreePlatform.h"

@interface ShareViewController()
@end

@implementation ShareViewController
@synthesize screenshotModeSwitch = _screenshotModeSwitch;
@synthesize defaultMessageField = _defaultMessageField;
@synthesize showPopupButton = _showPopupButton;
@synthesize scrollView = _scrollView;

- (void)dealloc
{
  [_defaultMessageField release];
  [_screenshotModeSwitch release];
  [_showPopupButton release];
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
  self.title = NSLocalizedStringWithDefaultValue(@"shareController.title.label", @"GreeShowCase", [NSBundle mainBundle], @"Share", @"share controller title");
  self.navigationController.navigationBar.tintColor = [UIColor showcaseNavigationBarColor];
  
  UIImage* btnImage = [UIImage imageNamed:@"btn_uniform.png"];
  [self.showPopupButton setBackgroundImage:[btnImage showcaseResizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)] forState:UIControlStateNormal];
  self.defaultMessageField.layer.cornerRadius = 8.f;
 [self addTextFieldList:[NSArray arrayWithObject:self.defaultMessageField]];
}

- (void)viewDidUnload
{
  [self setShowPopupButton:nil];
  [self setScrollView:nil];
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(greePopupDidLaunchNotification:) name:GreePopupDidLaunchNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(greePopupDidDismissNotification:) name:GreePopupDidDismissNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [self dismissKeyboard];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
  [super viewWillDisappear:animated];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
  [self dismissKeyboard];
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

- (IBAction)shareButtonClicked:(id)sender {
  [self dismissKeyboard];

  GreeSharePopup* sharePopup = [GreeSharePopup popup];
  sharePopup.text = self.defaultMessageField.text;
  
  if([self.screenshotModeSwitch isOn]) {
    //Take Screenshot  
    UINavigationController* navigator = (UINavigationController*)[[UIApplication sharedApplication] delegate].window.rootViewController;
    UIView* viewForScreenShot = navigator.view;
    
    UIGraphicsBeginImageContext(viewForScreenShot.layer.visibleRect.size);
    [viewForScreenShot.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
        
    sharePopup.attachingImage = image;
  }
    
  sharePopup.willLaunchBlock = ^(GreePopup* aSender) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"share_popup_will_launch_block" object:nil];
    [self disableKeyboardObservation];
  };
  sharePopup.didLaunchBlock = ^(GreePopup* aSender) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"share_popup_did_launch_block" object:nil];
  };
  sharePopup.willDismissBlock = ^(GreePopup* aSender) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"share_popup_will_dismiss_block" object:nil];
  };
  sharePopup.didDismissBlock = ^(GreePopup* aSender) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"share_popup_did_dismiss_block" object:nil];
    [self enableKeyboardObservation];
  };
  sharePopup.cancelBlock = ^(GreePopup* aSender) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"share_popup_cancel_block" object:nil];
  };
  sharePopup.completeBlock = ^(GreePopup* aSender) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"share_popup_complete_block" object:nil];
  };
  [self.navigationController showGreePopup:sharePopup];
}

@end
