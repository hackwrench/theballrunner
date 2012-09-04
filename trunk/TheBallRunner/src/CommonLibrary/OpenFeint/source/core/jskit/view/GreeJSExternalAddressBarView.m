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


#import "GreeJSExternalAddressBarView.h"
#import "UIImage+GreeAdditions.h"
#import "GreePlatform+Internal.h"

static float const kButtonPadding = 5.0f;
static float const kButtonWidth   = 32.0f;
static float const kButtonHeight  = 28.0f;

@interface GreeJSExternalAddressBarView ()
- (void)setupButtons;
- (void)setupTextField;
@end

@implementation GreeJSExternalAddressBarView

@synthesize addressBarText = addressBarText_;
@synthesize delegate = delegate_;

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    UIImage *image = [UIImage greeImageNamed:@"gree_URL_panel.png"];
    UIImage *stretchableImage = [image stretchableImageWithLeftCapWidth:100.0f topCapHeight:12.0f];
    UIImageView *viewView= [[[UIImageView alloc] initWithFrame:self.frame] autorelease];
    viewView.autoresizingMask = 
    UIViewAutoresizingFlexibleWidth | 
    UIViewAutoresizingFlexibleHeight;
    viewView.image = stretchableImage;
    [self addSubview:viewView];
    [self setupButtons];
    [self setupTextField];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  }
  return self;
}

- (void)dealloc
{
  [addressBarText_ release];
  [addressBarLabel_ release];
  [backButton_ release];
  [forwardButton_ release];
  [addressBarButton_ release];
  [addressLoadingIndicator_ release];
  
  delegate_ = nil;
  addressBarText_ = nil;
  addressBarLabel_ = nil;
  backButton_ = nil;
  forwardButton_ = nil;
  addressBarButton_ = nil;
  addressLoadingIndicator_ = nil;
  [super dealloc];
}


#pragma mark - Internal Methods

- (void)setupButtons
{
  UIImage *backImage = [UIImage greeImageNamed:@"gree_btn_eb_back_default.png"];
  UIImage *backImageHighlight = [UIImage greeImageNamed:@"gree_btn_eb_back_highlight.png"];
  backButton_ = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  [backButton_ setImage:backImage forState:UIControlStateNormal];
  [backButton_ setImage:backImageHighlight forState:UIControlStateHighlighted];
  backButton_.frame = CGRectMake(kButtonPadding,
                                (self.frame.size.height - backImage.size.height)/2,
                                backImage.size.width,
                                backImage.size.height);
  backButton_.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
  [backButton_ addTarget:self.delegate
                 action:@selector(onAddressBarViewBackButtonTap:)
       forControlEvents:UIControlEventTouchUpInside];
  backButton_.enabled = NO;
  
  UIImage *forwardImage = [UIImage greeImageNamed:@"gree_btn_eb_forward_default.png"];
  UIImage *forwardImageHighlight = [UIImage greeImageNamed:@"gree_btn_eb_forward_highlight.png"];
  forwardButton_ = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  [forwardButton_ setImage:forwardImage forState:UIControlStateNormal];
  [forwardButton_ setImage:forwardImageHighlight forState:UIControlStateHighlighted];
  forwardButton_.frame = CGRectMake(backButton_.frame.size.width + kButtonPadding,
                                   backButton_.frame.origin.y,
                                   forwardImage.size.width,
                                   forwardImage.size.height);
  forwardButton_.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
  [forwardButton_ addTarget:self.delegate
                    action:@selector(onAddressBarViewForwardButtonTap:)
          forControlEvents:UIControlEventTouchUpInside];
  forwardButton_.enabled = NO;
  
  [self addSubview:backButton_];
  [self addSubview:forwardButton_];
}

- (void)setupTextField
{
  
  CGRect rect = CGRectZero;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    rect = CGRectMake(90, 9, 640, 24);
  } else {
    rect = CGRectMake(90, 9, 190, 24);
  }
  addressBarLabel_ = [[UILabel alloc] initWithFrame:rect];
  addressBarLabel_.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
                                      UIViewAutoresizingFlexibleBottomMargin |
                                      UIViewAutoresizingFlexibleRightMargin |
                                      UIViewAutoresizingFlexibleWidth;
  addressBarLabel_.font = [UIFont fontWithName:@"Helvetica" size:14.0f];
  addressBarLabel_.backgroundColor = [UIColor clearColor];
  addressBarLabel_.textColor = [UIColor grayColor];
  [addressBarLabel_ setLineBreakMode:UILineBreakModeTailTruncation];
  [self addSubview:addressBarLabel_];
  
  CGFloat adjust = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) ? (kButtonWidth / 2) : 0;
  
  CGRect aFrame = addressBarLabel_.frame;
  addressBarButton_ = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  addressBarButton_.frame = CGRectMake(aFrame.origin.x + aFrame.size.width - adjust,
                                       aFrame.origin.y,
                                       kButtonWidth,
                                       kButtonHeight);
  addressBarButton_.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
                                       UIViewAutoresizingFlexibleBottomMargin |
                                       UIViewAutoresizingFlexibleLeftMargin;

  [self addSubview:addressBarButton_];

  CGRect indicatorFrame = CGRectMake(addressBarButton_.frame.origin.x,
                                     addressBarButton_.frame.origin.y,
                                     20,
                                     20);
  addressLoadingIndicator_ = [[UIActivityIndicatorView alloc] initWithFrame:indicatorFrame];
  addressLoadingIndicator_.center = addressBarButton_.center;
  addressLoadingIndicator_.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
  addressLoadingIndicator_.autoresizingMask = UIViewAutoresizingFlexibleTopMargin |
                                              UIViewAutoresizingFlexibleBottomMargin |
                                              UIViewAutoresizingFlexibleLeftMargin;

  [self addSubview:addressLoadingIndicator_];
}

#pragma mark - Public Interface

- (void)setIsLoading:(BOOL)isLoading
{
  isLoading_ = isLoading;

  if (self.isLoading) {
    [addressBarButton_ setImage:nil forState:UIControlStateNormal];
    [addressLoadingIndicator_ startAnimating];
  } else {
    [addressLoadingIndicator_ stopAnimating];
    UIImage *reloadImage = [UIImage greeImageNamed:@"gree_btn_URL_refresh_default.png"];
    [addressBarButton_ setImage:reloadImage forState:UIControlStateNormal];
    [addressBarButton_ addTarget:self.delegate
                          action:@selector(onAddressBarViewReloadButtonTap:)
                forControlEvents:UIControlEventTouchUpInside];
  }
}

- (BOOL)isLoading
{
  return isLoading_;
}

- (void)setBackButtonEnabled:(BOOL)backButtonEnabled
{
  backButtonEnabled_ = backButtonEnabled;
  backButton_.enabled = backButtonEnabled;
}

- (BOOL)backButtonEnabled
{
  return backButtonEnabled_;
}

- (void)setForwardButtonEnabled:(BOOL)forwardButtonEnabled
{
  forwardButtonEnabled_ = forwardButtonEnabled;
  forwardButton_.enabled = forwardButtonEnabled;
}

- (BOOL)forwardButtonEnabled
{
  return forwardButtonEnabled_;
}

- (void)setAddressBarText:(NSString *)addressBarText
{
  if (addressBarText_ == addressBarText)
  {
    return;
  }
  NSString *oldValue = addressBarText_;
  addressBarText_ = [addressBarText copy];
  addressBarLabel_.text = addressBarText_;
  
  [oldValue release];
}

- (NSString*)addressBarText
{
  return addressBarText_;
}

@end
