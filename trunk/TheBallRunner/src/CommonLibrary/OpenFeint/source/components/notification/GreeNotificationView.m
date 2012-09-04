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

#import "GreeNotificationView.h"
#import "UIImage+GreeAdditions.h"

const static CGFloat messageLabelOriginX = 40.0f;
const static CGFloat messageLabelOriginY = 10.0f;
const static CGFloat messageLabelOriginYTwoLine = 0.0f;

const static CGFloat iconOriginX = 10.0f;
const static CGFloat iconOriginY = 10.0f;
const static CGFloat iconWidth = 22.0f;
const static CGFloat iconHeight = 22.0f;

const static CGFloat logoOverlayOriginX = 4.0f;
const static CGFloat logoOverlayOriginY = 19.0f;
const static CGFloat logoOverlayWidth = 13.0f;
const static CGFloat logoOverlayHeight = 13.0f;

const static CGFloat closeButtonWidth = 20.0f;
const static CGFloat closeButtonHeight = 44.0f;
const static CGFloat closeButtonBuffer = 20.0f;

@implementation GreeNotificationView

@synthesize iconView = _iconView;
@synthesize logoView = _logoView;
@synthesize messageLabel = _messageLabel;
@synthesize closeButton = _closeButton;

@synthesize notification = _notification;

@synthesize showsCloseButton = _showsCloseButton;

- (id)initWithMessage:(NSString*)aMessage icon:(UIImage*)anImage frame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    if (self) {
      UIImage* backImage = [UIImage greeImageNamed:@"notifications_panel.png"];
      UIImageView* background = [[UIImageView alloc] initWithImage:backImage];
      CGRect backFrame = CGRectMake(0, 0, aFrame.size.width, aFrame.size.height);
      background.frame = backFrame;
      background.autoresizingMask = UIViewAutoresizingFlexibleWidth;
      [self addSubview:background];
      [background release];
      
      _messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(
        messageLabelOriginX,
        messageLabelOriginY,
        aFrame.size.width - messageLabelOriginX,
        aFrame.size.height
      )];
        
      _messageLabel.text = aMessage;
      _messageLabel.textColor = [UIColor whiteColor];
      _messageLabel.backgroundColor = [UIColor clearColor];
      _messageLabel.baselineAdjustment = UIBaselineAdjustmentNone;
      _messageLabel.font = [UIFont fontWithName:@"Helvetica" size:12.0f];;
//      _messageLabel.numberOfLines = useTwoLine ? 2 : 1;
      [self addSubview:_messageLabel];

      _iconView = [[UIImageView alloc] initWithImage:anImage];
      _iconView.frame = CGRectMake(iconOriginX, iconOriginY, iconWidth, iconHeight);
      [self addSubview:_iconView];
      
      UIImage *logo = [UIImage greeImageNamed:@"gree_notification_logo.png"];
      
      _logoView = [[UIImageView alloc] initWithImage:logo];
      _logoView.frame = CGRectMake(logoOverlayOriginX, logoOverlayOriginY, logoOverlayWidth, logoOverlayHeight);
      [self addSubview:_logoView];
      
      _showsCloseButton = NO;
      _messageLabel.textColor = [UIColor whiteColor];
      
      [self setAccessibilityLabel:aMessage];
    }
    return self;
}

-(void)dealloc
{
  [_iconView release];
  [_logoView release];
  
  [_messageLabel release];
  [_closeButton release];
  
  [_notification release];
  
  [super dealloc];
}

-(void)setShowsCloseButton:(BOOL)showsCloseButton
{
  if (showsCloseButton && !_closeButton) {
    _closeButton = [[UIButton alloc] initWithFrame:CGRectMake(
      self.bounds.size.width - closeButtonBuffer,
      (self.bounds.size.height / 2.0f) - (closeButtonHeight / 2.0f),
      closeButtonWidth,
      closeButtonHeight
    )];
    
    [_closeButton setImage:[UIImage greeImageNamed:@"gree_notification_close_white.png"] forState:UIControlStateNormal];
    _closeButton.accessibilityLabel = @"Close";
    
    [self addSubview:_closeButton];
        
  } else if (!showsCloseButton) {
    [_closeButton removeFromSuperview];
    [_closeButton release];
    _closeButton = nil;
    
  }
  _showsCloseButton = showsCloseButton;
}

#pragma mark - UIView
- (void)layoutSubviews
{
  UIFont* testingFont = _messageLabel.font;
  CGSize fontWidth = [_messageLabel.text sizeWithFont:testingFont];
  BOOL useTwoLine = fontWidth.width > self.frame.size.width - messageLabelOriginX;  
  CGRect messageFrame = CGRectMake(messageLabelOriginX,
                      useTwoLine ? messageLabelOriginYTwoLine : messageLabelOriginY,
                      self.frame.size.width - messageLabelOriginX,
                      useTwoLine ? self.frame.size.height : self.frame.size.height / 2);
  if(self.showsCloseButton) {    
    messageFrame.size.width -= closeButtonBuffer;
  }
  
  _messageLabel.numberOfLines = useTwoLine ? 2 : 1;
  _messageLabel.frame = messageFrame;
}


#pragma mark - NSObject overrides
- (NSString*)description
{
    return [NSString stringWithFormat:@"<%@:%p, message:%@, frame:%@, showsCloseButton:%@>",
              NSStringFromClass([self class]),
              self,
              self.messageLabel.text,
              NSStringFromCGRect(self.frame),
              self.showsCloseButton ? @"YES" : @"NO"];
}

@end
