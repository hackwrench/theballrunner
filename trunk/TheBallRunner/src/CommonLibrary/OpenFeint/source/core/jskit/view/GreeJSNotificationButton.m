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

#import "GreeJSNotificationButton.h"
#import "UIImage+GreeAdditions.h"
#import "GreeBadgeValues.h"

#define kGreeNotificationButtonTitleLabelFont @"Helvetica-Bold"
#define kGreeNotificationButtonTitleLabelFontSize 12.0f
#define HEXCOLOR(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 \
green:((c>>8)&0xFF)/255.0 \
blue:(c&0xFF)/255.0 \
alpha:1.0];

@implementation GreeJSNotificationButton

@synthesize number = number_;

#pragma mark - Internal Methods

- (void)updateButtonState
{
  UIImage *normalImage            = nil;
  UIImage *highlightedImage       = nil;
  NSString *numberStr             = nil;
  UIColor *normalShadowColor      = nil;
  UIColor *highlightedShadowColor = nil;
  
  if (number_ > 0) {
    normalImage = [UIImage greeImageNamed:@"gree_btn_notifications_red_default.png"];
    highlightedImage = [UIImage greeImageNamed:@"gree_btn_notifications_red_highlight.png"];
    if (number_ > 99) {
      numberStr = @"99+";
    }
    else {
        numberStr = [NSString stringWithFormat:@"%d", number_];
    }    
    normalShadowColor = HEXCOLOR(0x006491);
    highlightedShadowColor = HEXCOLOR(0xAA0000);
  }
  else {
    normalImage = [UIImage greeImageNamed:@"gree_btn_notifications_default.png"];
    highlightedImage = [UIImage greeImageNamed:@"gree_btn_notifications_highlight.png"];
    numberStr = @"";
  }
  [self setBackgroundImage:normalImage forState:UIControlStateNormal];
  [self setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
  [self setTitle:numberStr forState:UIControlStateNormal];
  [self setTitleShadowColor:normalShadowColor forState:UIControlStateNormal];
  [self setTitleShadowColor:highlightedShadowColor forState:UIControlStateHighlighted];
}

- (void)updateBadgeValue:(id)sender
{
  NSNotification *notification = (NSNotification*)sender;
  GreeBadgeValues *value = (GreeBadgeValues*)notification.object;
  self.number = value.socialNetworkingServiceBadgeCount+value.applicationBadgeCount;
}

#pragma mark - Object Lifecycle

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
      [self setNumber:0];
      self.titleLabel.font = [UIFont fontWithName:kGreeNotificationButtonTitleLabelFont size:kGreeNotificationButtonTitleLabelFontSize];
      
      UIColor *titleColor = HEXCOLOR(0xF7F8F9);
      [self setTitleColor:titleColor forState:UIControlStateNormal];
      
      self.layer.shadowOpacity = 0.5;
      self.layer.shadowRadius = 1;
      self.layer.shadowOffset = CGSizeMake(2.0f, 2.0f);
      self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.layer.bounds].CGPath;
      
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(updateBadgeValue:)
                                                   name:GreeBadgeValuesDidUpdateNotification
                                                 object:nil];
    }
    return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:GreeBadgeValuesDidUpdateNotification
                                                object:nil];
  [super dealloc];
}

#pragma mark - accessor

- (void)setNumber:(NSUInteger)number {
  number_ = number;
  [self updateButtonState];
}

@end
