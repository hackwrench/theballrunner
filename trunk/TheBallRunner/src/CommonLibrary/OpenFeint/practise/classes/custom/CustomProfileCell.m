//
// Copyright 2011 GREE, Inc.
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

#import "CustomProfileCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation CustomProfileCell
@synthesize firstTitleLabel = _firstTitleLabel;
@synthesize secondTitleLabel = _secondTitleLabel;
@synthesize iconImageView = _iconImageView;

@synthesize firstLabelTextColor =  _firstLabelTextColor;
@synthesize secondLabelTextColor =  _secondLabelTextColor;

@synthesize firstLabelFont =  _firstLabelFont;
@synthesize secondLabelFont =  _secondLabelFont;
@synthesize userInfo =  _userInfo;

@synthesize customHeight =  _customHeight;


- (void)dealloc {
  [_firstTitleLabel release];
  [_secondTitleLabel release];
  [_firstLabelTextColor release];
  [_secondLabelTextColor release];
  
  [_iconImageView release];
  [_firstLabelFont release];
  [_secondLabelFont release];
  [_userInfo release];
  [super dealloc];
}

+ (NSString*)cellReusableIdentifier
{
  return @"CustomProfileCell";
}

+ (float)cellHeight
{
  return 67.f;
}

- (void)awakeFromNib
{
  self.iconImageView.layer.masksToBounds = YES;
  self.iconImageView.layer.cornerRadius = 5.0;
}

-(void)layoutSubviews {  
  [super layoutSubviews];
  
  if(self.customHeight > 0.f){
    CGRect frame = self.frame;
    frame.size.height = self.customHeight;
    self.frame = frame;
  }
  
  if (self.firstLabelFont) {
    self.firstTitleLabel.font = self.firstLabelFont;
  }
  if (self.secondLabelFont) {
    self.secondTitleLabel.font = self.secondLabelFont;
  }
  
  if (self.firstLabelTextColor) {
    self.firstTitleLabel.textColor = self.firstLabelTextColor;
  }
  if (self.secondLabelTextColor) {
    self.secondTitleLabel.textColor = self.secondLabelTextColor;
  }
  
}



@end
