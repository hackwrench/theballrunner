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

#import "ShowcaseBaseViewController.h"
#import "GreePlatform.h"

@interface UIView (GreeFirstResponder)
- (CGRect)greeFirstResponderFrame;
@end

@interface ShowcaseBaseViewController()

@property(nonatomic, retain) NSArray* textFieldList; 
@property(nonatomic, retain) NSNotification* kbNotification; 
- (void)adjustKeyboard:(CGRect)firstResponderFrame;

@end

@implementation ShowcaseBaseViewController
@synthesize textFieldList =  _textFieldList;
@synthesize kbNotification =  _kbNotification;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    [self enableKeyboardObservation];
  }
  return self;
}

- (void)dealloc {
  [self disableKeyboardObservation];
  [_kbNotification release];
  
  [_textFieldList release];
  [super dealloc];
}

- (void)addTextFieldList:(NSArray*)textFieldList
{
  NSMutableArray* tempList = [[NSMutableArray alloc] initWithCapacity:textFieldList.count];
  for (int index = 0; index < textFieldList.count; index++) {
    id textInput = [textFieldList objectAtIndex:index];
    if (![textInput isKindOfClass:[UITextView class]] && ![textInput isKindOfClass:[UITextField class]]) {
      continue;
    }
    if ([textInput isKindOfClass:[UITextView class]]) {
      UITextView* view = (UITextView*)textInput;
      view.delegate = self;
      [tempList addObject:view];
    }else if([textInput isKindOfClass:[UITextField class]]){
      UITextField* field = (UITextField*)textInput;
      field.delegate = self;
      [tempList addObject:field];
    }
  }
  self.textFieldList = tempList;
  [tempList release];
}


- (BOOL)isLastField:(id)textField
{
  int index = [self.textFieldList indexOfObject:textField];
  return index == self.textFieldList.count - 1 ? YES : NO;
}

- (void)adjustKeyboard:(CGRect)firstResponderFrame
{
  CGRect keyboardEndFrame = [self.view 
                             convertRect:[[[self.kbNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue]
                             fromView:self.view.window];
  
  CGFloat animationDuration = [[[self.kbNotification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, animationDuration * 0.5 * NSEC_PER_SEC);
  
  if (CGRectIntersectsRect(firstResponderFrame, keyboardEndFrame)) {
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
      CGFloat finalYPosition = (keyboardEndFrame.origin.y / 2.0f) - (firstResponderFrame.size.height / 2.0f);
      CGFloat distanceToTravel = MAX(finalYPosition - firstResponderFrame.origin.y, -keyboardEndFrame.size.height);
      [UIView animateWithDuration:animationDuration
              animations:^{self.view.transform = CGAffineTransformMakeTranslation(0.0f, distanceToTravel);}];
    });
  }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
  if(self.textFieldList.count > 1 && ![self isLastField:textField]) { //have more than 1 textfields, and this is not the last one
    textField.returnKeyType = UIReturnKeyNext;
  }else{
    textField.returnKeyType = UIReturnKeyDone;
  }
  //if keyboard already appeared, then we need to re-adjust 
  if (self.kbNotification) { 
    [self adjustKeyboard:textField.frame];
  }
  return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;            
{
  if (![self isLastField:textField]) {
    int nextFieldIndex = [self.textFieldList indexOfObject:textField] + 1;
    UITextField* nextField = [self.textFieldList objectAtIndex:nextFieldIndex];
    [nextField becomeFirstResponder];
  }else{
    [textField resignFirstResponder];
  }
  return YES;
}


- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
  textView.returnKeyType = UIReturnKeyDefault;
  //if keyboard already appeared, then we need to re-adjust 
  if (self.kbNotification) { 
    [self adjustKeyboard:textView.frame];
  }
  return YES;
}


- (void)dismissKeyboard
{
  for (id field in self.textFieldList) {
    if ([field isFirstResponder] && [field respondsToSelector:@selector(resignFirstResponder)]) {
      [field resignFirstResponder];
    }
  }
}

#pragma mark - Public Interface
- (void)enableKeyboardObservation {
  __block ShowcaseBaseViewController *thisViewController = self;
  _keyboardShowObserver = [[NSNotificationCenter defaultCenter]
    addObserverForName:UIKeyboardWillShowNotification
    object:nil
    queue:[NSOperationQueue mainQueue]
    usingBlock:^(NSNotification* notification) {
      thisViewController.kbNotification = notification;
      [thisViewController adjustKeyboard:[thisViewController.view greeFirstResponderFrame]];
    }];
       
  [_keyboardShowObserver retain];
        
  _keyboardHideObserver = [[NSNotificationCenter defaultCenter]
    addObserverForName:UIKeyboardWillHideNotification
    object:nil
    queue:[NSOperationQueue mainQueue]
    usingBlock:^(NSNotification* notification) {
      thisViewController.kbNotification = nil;
        
      CGFloat animationDuration = [[[notification userInfo]
        objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
                
      [UIView animateWithDuration:animationDuration
        animations:^{
          thisViewController.view.transform = CGAffineTransformIdentity;
      }];
    }];
      
  [_keyboardHideObserver retain];
}

- (void)disableKeyboardObservation {
  [[NSNotificationCenter defaultCenter] removeObserver:_keyboardShowObserver];
  [[NSNotificationCenter defaultCenter] removeObserver:_keyboardHideObserver];
  
  [_keyboardShowObserver release];
  [_keyboardHideObserver release];
}

#pragma mark - UIViewController
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{
  [self dismissKeyboard];
}


@end
