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

#import <UIKit/UIKit.h>
#import "ShowcaseBaseViewController.h"
#import "CustomScrollView.h"

@interface RequestViewController : ShowcaseBaseViewController<UITextFieldDelegate>
@property (retain, nonatomic) IBOutlet UITextField *titleTextField;
@property (retain, nonatomic) IBOutlet UITextField *bodyTextField;
@property (retain, nonatomic) IBOutlet UISegmentedControl *friendListTypeControl;
@property (retain, nonatomic) IBOutlet UITextField *imageUrlTextField;
@property (retain, nonatomic) IBOutlet UIButton *showPopupButton;
@property (retain, nonatomic) IBOutlet CustomScrollView *scrollView;

@property (retain, nonatomic) IBOutlet UITextField *keyOneTextField;
@property (retain, nonatomic) IBOutlet UITextField *valueOneTextField;
@property (retain, nonatomic) IBOutlet UITextField *keyTwoTextField;
@property (retain, nonatomic) IBOutlet UITextField *valueTwoTextField;
@property (retain, nonatomic) IBOutlet UITextField *keyThreeTextField;
@property (retain, nonatomic) IBOutlet UITextField *valueThreeTextField;

- (IBAction)requestButtonClicked:(id)sender;
@end
