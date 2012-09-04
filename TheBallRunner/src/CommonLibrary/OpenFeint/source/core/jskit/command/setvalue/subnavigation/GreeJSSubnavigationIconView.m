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

#import "GreeJSSubnavigationIconView.h"

static float const kLabelTopPadding           = 1.0f;
static float const kLabelLandscapeLeftPadding = 2.0f;
static float const kLabelFontSize             = 12.0f;
static float const kLabelHeight               = 14.0f ;
static float const kImageHeight               = 30.0f;
static float const kImageWidth                = 30.0f;
static float const kImagePortraitTopPadding   = 2.0f;
static NSString* const kLabelFont   = @"Helvetica-Bold";
static NSString* const kLabelKey    = @"label";
static NSString* const kCallbackKey = @"callback";
static NSString* const kIconKey     = @"icon";
static NSString* const kSelectedKey = @"selected";
static int const kSelectedTrueValue = 1;


@implementation GreeJSSubnavigationIconView
@synthesize delegate          = _delegate;
@synthesize labelString       = _labelString;
@synthesize callback          = _callback;
@synthesize callbackParams    = _callbackParams;
@synthesize normalImage       = _normalImage;
@synthesize selectedImage     = _selectedImage;


#pragma mark -
#pragma mark Object Lifecycle

- (id)initWithNormalImage:(UIImage*)normalImage
            selectedImage:(UIImage*)selectedImage
                   params:(NSDictionary*)params 
                 delegate:(NSObject<GreeJSSubnavigationMenuButtonDelegate>*)delegate {
  self = [super init];
  if (self)
  {
    self.delegate = delegate;    
    self.autoresizingMask =
    UIViewAutoresizingFlexibleHeight |
    UIViewAutoresizingFlexibleWidth;
    self.normalImage = normalImage;
    self.selectedImage = selectedImage;
    _iconImageView = [[UIImageView alloc] initWithImage:_normalImage];
    [self addSubview:_iconImageView];
    [_iconImageView release];
    
    // Instantiate label, add as subview.
   _label = [[UILabel alloc] init];
   _label.backgroundColor = [UIColor clearColor];
   _label.text = [params objectForKey:kLabelKey];
   float hex = 255.0f;
   [_label setShadowColor:[UIColor colorWithRed:0x0c/hex
                                          green:0x1e/hex
                                           blue:0x1f/hex
                                          alpha:1.0f]];
   _label.shadowOffset = CGSizeMake(0.0f, -1.0f);
   _label.font = [UIFont fontWithName:kLabelFont size:kLabelFontSize];
   [self addSubview:_label];
   [_label release];
   
    self.callback = [params objectForKey:kCallbackKey];
    [self addTarget:_delegate 
             action:@selector(onSubnavigationMenuButtonIconTap:)
   forControlEvents:UIControlEventTouchUpInside];
    
    self.selected = [[params objectForKey:kSelectedKey] intValue] == kSelectedTrueValue ? YES : NO;
  }
  return self;
}

- (void)dealloc {
  [_iconName release], _iconName = nil;
  [_labelString release], _labelString = nil;
  [_callback release], _callback = nil;
  [_callbackParams release], _callbackParams = nil;
  [_normalImage release], _normalImage = nil;
  [_selectedImage release], _selectedImage = nil;
  [super dealloc];
}

- (void)layoutSubviews
{
  _iconImageView.backgroundColor = [UIColor clearColor];
  _label.backgroundColor = [UIColor clearColor];
  
  CGSize imageSize = CGSizeMake(kSubnavigationIconImageWidth, kSubnavigationIconImageHeight);
  CGRect imageViewRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
  
  UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
  if (UIInterfaceOrientationIsPortrait(orientation)) {
    imageViewRect.origin.x = (self.frame.size.width - imageSize.width)/2;
    
    _iconImageView.frame = CGRectMake((self.frame.size.width - kImageWidth)/2, 
                                      kImagePortraitTopPadding, 
                                      kImageWidth,
                                      kImageHeight);
    
    _label.frame = CGRectMake(0, 
                              imageViewRect.origin.y + kImagePortraitTopPadding + \
                              _iconImageView.bounds.size.height + kLabelTopPadding, 
                              self.bounds.size.width, 
                              kLabelHeight);
    
    _label.textAlignment = UITextAlignmentCenter;
  } else {
    CGSize labelSize = CGSizeMake(self.frame.size.width - kImageWidth - kLabelLandscapeLeftPadding, kLabelHeight);
    CGSize textSize = [_label.text sizeWithFont:[UIFont fontWithName:kLabelFont size:kLabelFontSize]
                              constrainedToSize:labelSize
                                  lineBreakMode:UILineBreakModeTailTruncation];
    imageViewRect.origin.x = (self.frame.size.width - kImageWidth - kLabelLandscapeLeftPadding - textSize.width)/2;
    
    _iconImageView.frame = CGRectMake(imageViewRect.origin.x,
                                      (self.frame.size.height - kImageHeight)/2,
                                      kImageWidth,
                                      kImageHeight);
    
    _label.frame = CGRectMake(imageViewRect.origin.x + kImageWidth + kLabelLandscapeLeftPadding,
                              roundf((self.frame.size.height - kLabelHeight)/2),
                              labelSize.width,
                              labelSize.height);
    _label.textAlignment = UITextAlignmentLeft;
  }
}


#pragma mark - UIButton Overrides

- (void)setSelected:(BOOL)selected
{
  [super setSelected:selected];
  float hex = 255.0f;
  if (selected) {
    _iconImageView.image = _selectedImage;
    _label.textColor = [UIColor colorWithRed:0xff/hex
                                       green:0xff/hex 
                                        blue:0xff/hex 
                                       alpha:1.0f];
    self.backgroundColor = [UIColor colorWithRed:0x22/hex
                                           green:0x22/hex
                                            blue:0x22/hex
                                           alpha:1.0f];
  } else {
    _iconImageView.image = _normalImage;
    _label.textColor = [UIColor colorWithRed:0x8c/hex
                                       green:0x91/hex 
                                        blue:0x94/hex 
                                       alpha:1.0f];
    self.backgroundColor = [UIColor clearColor];
  }
}

- (void)setHighlighted:(BOOL)highlighted
{
  [super setHighlighted:highlighted];
  float hex = 255.0f;
  if (highlighted || self.selected) {
    self.backgroundColor = [UIColor colorWithRed:0x22/hex
                                           green:0x22/hex
                                            blue:0x22/hex
                                           alpha:1.0f];
  } else {
    self.backgroundColor = [UIColor clearColor];
  }
}

#pragma mark -
#pragma mark - Public Interface

- (void)setSelectedImage:(UIImage*)image
{
  if (self.selected == YES) {
    _iconImageView.image = image;
  }
  [_selectedImage release];
  _selectedImage = [image retain];
}

- (void)setNormalImage:(UIImage*)image
{
  if (self.selected == NO) {
    _iconImageView.image = image;
  }
  [_normalImage release];
  _normalImage = [image retain];
}

@end
