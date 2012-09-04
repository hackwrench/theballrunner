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

#import "CustomViewController.h"
#import <QuartzCore/QuartzCore.h> 

@implementation CustomViewController

#pragma mark - View lifecycle
- (void)viewDidLoad
{
  [super viewDidLoad];
  
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  [button setImage:[UIImage imageNamed:@"btn_back.png"] forState:UIControlStateNormal];
  [button sizeToFit];
  [button addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *customBarItem = [[UIBarButtonItem alloc] initWithCustomView:button];
  self.navigationItem.leftBarButtonItem = customBarItem;
  [customBarItem release];
}

- (void)goBack 
{
  [self.navigationController popViewControllerAnimated:YES];
}

@end

