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

#import "PaymentViewController.h"
#import "GreeWallet.h"
#import "GreePlatform.h"
#import "UIImage+ShowCaseAdditions.h"

@interface PaymentViewController() 
- (NSString*)paymentSuccessResultString:(NSString*)aString;
- (NSString*)paymentFailureResultString:(NSString*)aString error:(NSError*)error;
@end

@implementation PaymentViewController
@synthesize itemIdTextField = _itemIdTextField;
@synthesize nameTextField = _nameTextField;
@synthesize unitPriceTextField = _unitPriceTextField;
@synthesize quantityTextField = _quantityTextField;
@synthesize showPopupButton = _showPopupButton;
@synthesize descriptionTextField = _descriptionTextField;
@synthesize optionalMsgTextField = _optionalMsgTextField;
@synthesize scrollView = _scrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
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
  // Do any additional setup after loading the view from its nib
  self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
  self.title = NSLocalizedStringWithDefaultValue(@"PaymentController.title.label", @"GreeShowCase", [NSBundle mainBundle], @"Payment", @"Payment controller title");
  
  UIImage* btnImage = [UIImage imageNamed:@"btn_uniform.png"];
  [self.showPopupButton setBackgroundImage:[btnImage showcaseResizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)] forState:UIControlStateNormal];
  [self addTextFieldList:[NSArray arrayWithObjects:self.itemIdTextField, self.nameTextField, self.unitPriceTextField, self.quantityTextField, self.descriptionTextField, self.optionalMsgTextField, nil]];
}

- (void)viewDidUnload
{
  [self setItemIdTextField:nil];
  [self setNameTextField:nil];
  [self setUnitPriceTextField:nil];
  [self setQuantityTextField:nil];
  [self setShowPopupButton:nil];
  [self setDescriptionTextField:nil];
  [self setScrollView:nil];
  [self setOptionalMsgTextField:nil];
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *) event 
{
  [self dismissKeyboard];
}

- (void)dealloc 
{
  [_itemIdTextField release];
  [_nameTextField release];
  [_unitPriceTextField release];
  [_quantityTextField release];
  [_showPopupButton release];
  [_descriptionTextField release];
  [_scrollView release];
  [_optionalMsgTextField release];
  [super dealloc];
}

#pragma mark - IBActions

- (IBAction)depositPressed:(id)sender 
{
  [GreeWallet launchDepositPopup];
}

- (IBAction)buyItemPressed:(id)sender 
{
  [self dismissKeyboard];
  NSString* itemId = self.itemIdTextField.text;
  NSString* itemName = self.nameTextField.text;
  NSInteger unitPrice = [self.unitPriceTextField.text intValue];
  NSInteger quantity = [self.quantityTextField.text intValue];
  NSString* description = self.descriptionTextField.text;
  NSString* optionalMsg = self.optionalMsgTextField.text;
  
  if([itemId length] < 1) {
    itemId = @"ex101";   //shouldn't this list be fixed?
  }
  if([itemName length] < 1) {
    itemName = NSLocalizedStringWithDefaultValue(@"paymentviewcontroller.defaultitem.name", @"GreeShowCase", [NSBundle mainBundle], @"Item to buy", @"");
  }
  if(unitPrice < 1) unitPrice = 1;
  if(quantity < 1) quantity = 1;
  if([itemId length] < 1) {
    description = @"";
  }
  GreeWalletPaymentItem* pItem = [GreeWalletPaymentItem paymentItemWithItemId:itemId 
                                                                     itemName:itemName 
                                                                    unitPrice:unitPrice
                                                                     quantity:quantity
                                                                     imageUrl:@"http://images.apple.com/jp/iphone/home/images/bucket_icon_ios.png"
                                                                  description:description];
  
  
	//prepare array
	NSMutableArray* pItems = [NSMutableArray array];
	[pItems addObject:pItem];
  //	[pItems addObject:pItem2];
  NSString* closeButton = NSLocalizedStringWithDefaultValue(@"payment.alertview.closebutton.text", @"GreeShowCase", [NSBundle mainBundle], @"Ok", @"Standard alert close button");
  [GreeWallet paymentWithItems:pItems
                   message:optionalMsg
                   callbackUrl:nil
                  successBlock:^(NSString* paymentId, NSArray* items){
                    NSString* title = NSLocalizedStringWithDefaultValue(@"payment.alertview.success.title", @"GreeShowCase", [NSBundle mainBundle], @"Payment valid", @"Title for payment response when successful");
                    [[[[UIAlertView alloc] initWithTitle:title message:[self paymentSuccessResultString:paymentId] delegate:nil cancelButtonTitle:closeButton otherButtonTitles:nil] autorelease] show];
                  }
                  failureBlock:^(NSString* paymentId, NSArray* items, NSError* error){
                    NSString* title = NSLocalizedStringWithDefaultValue(@"payment.alertview.failure.title", @"GreeShowCase", [NSBundle mainBundle], @"Payment failed", @"Title for payment response when failed");
                    [[[[UIAlertView alloc] initWithTitle:title message:[self paymentFailureResultString:paymentId error:error] delegate:nil cancelButtonTitle:closeButton otherButtonTitles:nil] autorelease] show];
                  }
   ];    
  
}


#pragma mark - Internal methods
- (NSString*)paymentSuccessResultString:(NSString*)aString
{
  NSString* format = NSLocalizedStringWithDefaultValue(@"payment.alertview.success.format", @"GreeShowCase", [NSBundle mainBundle], @"Payment %@ succeeded", @"will be passed a paymentId");
  return [NSString stringWithFormat:format, aString];
}

- (NSString*)paymentFailureResultString:(NSString*)aString error:(NSError*)error;
{
  NSString* format = NSLocalizedStringWithDefaultValue(@"payment.alertview.failure.format", @"GreeShowCase", [NSBundle mainBundle], @"Payment %1$@ failed: %2$@", @"will be passed a paymentId(1) and error message(2)");

  return [NSString stringWithFormat:format, aString, [error localizedDescription]];
}

@end
