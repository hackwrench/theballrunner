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

#import "AlertInputView.h"

@interface AlertInputView ()
@property (nonatomic, retain) UITextField* inputField;
@end

@implementation AlertInputView

@synthesize inputField = _inputField;
@synthesize numbersOnly = _numbersOnly;

#pragma mark - Object lifecycle
- (id)initWithTitle:(NSString*)title 
	message:(NSString*)message
	prepopulatedMessage:(NSString*)prepopulatedMessage
	delegate:(id)delegate 
	cancelButtonTitle:(NSString*)cancelButtonTitle 
	acceptButtonTitle:(NSString*)acceptButtonTitle
{
	message = [NSString stringWithFormat:@"%@ \n \n ", message];
	self = [super initWithTitle:title message:message delegate:delegate cancelButtonTitle:cancelButtonTitle otherButtonTitles:acceptButtonTitle, nil];
	if (self != nil) {
		_inputField = [[UITextField alloc] initWithFrame:CGRectZero];
		[_inputField setText:prepopulatedMessage];
		[_inputField setBorderStyle:UITextBorderStyleRoundedRect];
		[_inputField setDelegate:self];
		[self addSubview:_inputField];
	}
	
	return self;
}

- (void)dealloc
{
  [_inputField release];
	[super dealloc];
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	float lowestLabel = 0.f;
	for (UIView* view in self.subviews) {
		if ([view isKindOfClass:[UILabel class]]) {
			lowestLabel = MAX(CGRectGetMaxY(view.frame), lowestLabel);
    }
	}

	CGRect inputFrame = self.inputField.frame;
	inputFrame.origin = CGPointMake(15.f, lowestLabel - 29.f);
	inputFrame.size = CGSizeMake(258.f, 31.f);
	self.inputField.frame = inputFrame;
}

#pragma mark - Public Interface

- (NSString*)text
{
	return self.inputField.text;
}

- (BOOL)numbersOnly
{
  return _numbersOnly;
}

- (void)setNumbersOnly:(BOOL)numbersOnly
{
  _numbersOnly = numbersOnly;
  self.inputField.keyboardType = numbersOnly ? UIKeyboardTypeNumberPad : UIKeyboardTypeDefault;
}

#pragma mark - UIAlertView
- (void)show
{
	[self.inputField becomeFirstResponder];
	[super show];
}


#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
	BOOL allowed = YES;
	
	if (self.numbersOnly) {
		NSCharacterSet* illegalCharacters = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
		NSRange foundRange = [string rangeOfCharacterFromSet:illegalCharacters];
		allowed = foundRange.location == NSNotFound;
	}

	return allowed;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self dismissWithClickedButtonIndex:1 animated:YES];
    [self.inputField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
  [self.inputField resignFirstResponder];
}

@end
