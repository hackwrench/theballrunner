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

#import "RequestViewController.h"
#import "GreePopup.h"
#import "UIColor+ShowCaseAdditions.h"
#import "GreePlatform.h"
#import "UIImage+ShowCaseAdditions.h"
#import "UIViewController+GreePlatform.h"
#import "AppDelegate.h"

@interface RequestViewController()
- (NSString*)friendListTypeStringFromControl;
@end


@implementation RequestViewController
@synthesize titleTextField = _titleTextField;
@synthesize bodyTextField = _bodyTextField;
@synthesize friendListTypeControl = _friendListTypeControl;
@synthesize imageUrlTextField = _imageUrlTextField;
@synthesize showPopupButton = _showPopupButton;
@synthesize scrollView = _scrollView;
@synthesize keyOneTextField = _keyOneTextField;
@synthesize valueOneTextField = _valueOneTextField;
@synthesize keyTwoTextField = _keyTwoTextField;
@synthesize valueTwoTextField = _valueTwoTextField;
@synthesize keyThreeTextField = _keyThreeTextField;
@synthesize valueThreeTextField = _valueThreeTextField;

- (void)dealloc
{
  [_bodyTextField release];
  [_friendListTypeControl release];
  [_titleTextField release];
  [_showPopupButton release];
  [_imageUrlTextField release];
  [_scrollView release];
  [_keyOneTextField release];
  [_valueOneTextField release];
  [_keyTwoTextField release];
  [_valueTwoTextField release];
  [_keyThreeTextField release];
  [_valueThreeTextField release];
  [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, 750);
  self.title = NSLocalizedStringWithDefaultValue(@"RequestController.title.label", @"GreeShowCase", [NSBundle mainBundle], @"Requests", @"Requests controller title");
  self.navigationController.navigationBar.tintColor = [UIColor showcaseNavigationBarColor];
  
  UIImage* btnImage = [UIImage imageNamed:@"btn_uniform.png"];
  [self.showPopupButton setBackgroundImage:[btnImage showcaseResizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)] forState:UIControlStateNormal];

  [self addTextFieldList:[NSArray arrayWithObjects:self.titleTextField, self.bodyTextField, self.imageUrlTextField, 
                          self.keyOneTextField, self.valueOneTextField, 
                          self.keyTwoTextField, self.valueTwoTextField, 
                          self.keyThreeTextField, self.valueThreeTextField,
                          nil]];  
}

- (void)viewDidUnload
{
  [self setTitleTextField:nil];
  [self setShowPopupButton:nil];
  [self setImageUrlTextField:nil];
  [self setScrollView:nil];
  [self setKeyOneTextField:nil];
  [self setValueOneTextField:nil];
  [self setKeyTwoTextField:nil];
  [self setValueTwoTextField:nil];
  [self setKeyThreeTextField:nil];
  [self setValueThreeTextField:nil];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *) event 
{
  [self dismissKeyboard];
}

-(void)greePopupDidLaunchNotification:(NSNotification *)aNotification
{
	NSLog(@"%s", __FUNCTION__);
}

-(void)greePopupDidDismissNotification:(NSNotification *)aNotification
{
	NSLog(@"%s", __FUNCTION__);
}

- (IBAction)requestButtonClicked:(id)sender {
  [self dismissKeyboard];
  NSString* title = self.titleTextField.text;
  NSString* body = self.bodyTextField.text;
  NSString* type = [self friendListTypeStringFromControl];
  NSString* image_url = self.imageUrlTextField.text;
  
  NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              title, GreeRequestServicePopupTitle, 
                              body, GreeRequestServicePopupBody,
                              type, GreeRequestServicePopupListType,
                              nil];
    
  if(image_url) {
    [parameters setValue:image_url forKey:GreeRequestServicePopupImageURL];
  }
  
  NSMutableArray* attrsArray = [NSMutableArray array];
  if (self.keyOneTextField.text.length) {
    [attrsArray addObject:[NSString stringWithFormat:@"\"%@\":\"%@\"", self.keyOneTextField.text, self.valueOneTextField.text]];
  }
  if (self.keyTwoTextField.text.length) {
    [attrsArray addObject:[NSString stringWithFormat:@"\"%@\":\"%@\"", self.keyTwoTextField.text, self.valueTwoTextField.text]];
  }
  if (self.keyThreeTextField.text.length) {
    [attrsArray addObject:[NSString stringWithFormat:@"\"%@\":\"%@\"", self.keyThreeTextField.text, self.valueThreeTextField.text]];
  }
  NSMutableString* attrsString = [NSMutableString string];
  for (NSString* attr in attrsArray) {
      if (!attrsString.length) {
        [attrsString appendFormat:@"[{%@", attr];
      } else {
        [attrsString appendFormat:@",%@", attr];
      }
  }
  if (attrsString.length) {
    [attrsString appendFormat:@"}]"];
    [parameters setValue:attrsString forKey:GreeRequestServicePopupAttributes];
  }
    
  GreeRequestServicePopup* requestPopup = [GreeRequestServicePopup popup];
  requestPopup.parameters = parameters;
  requestPopup.willLaunchBlock = ^(GreePopup* aSender) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"request_service_popup_will_launch_block" object:nil];
  };
  requestPopup.didLaunchBlock = ^(GreePopup* aSender) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"request_service_popup_did_launch_block" object:nil];
  };
  requestPopup.willDismissBlock = ^(GreePopup* aSender) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"request_service_popup_will_dismiss_block" object:nil];
  };
  requestPopup.didDismissBlock = ^(GreePopup* aSender) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"request_service_popup_did_dismiss_block" object:nil];
  };
  requestPopup.cancelBlock = ^(GreePopup* aSender) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"request_service_popup_cancel_block" object:nil];
  };
  requestPopup.completeBlock = ^(GreePopup* aSender) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"request_service_popup_complete_block" object:nil];
  };
  [self.navigationController showGreePopup:requestPopup];
}

#pragma mark - UISegmentedControl
- (NSString*)friendListTypeStringFromControl
{
  static dispatch_once_t onceToken;
  static NSArray *friendListTypeStrings;
  
  dispatch_once(&onceToken, ^{
    friendListTypeStrings = [[NSArray arrayWithObjects:
                        GreeRequestServicePopupListTypeJoined,
                        GreeRequestServicePopupListTypeAll,
                        nil] retain];
  });
  
  return [friendListTypeStrings objectAtIndex:self.friendListTypeControl.selectedSegmentIndex];
}

@end
