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

#import "CustomSegmentedControl.h"

static const float SEPARATOR_WIDTH = 1.0;

@interface CustomButton : UIButton
@property(nonatomic, retain) NSString* title;
@property(nonatomic, retain) UIImage* normalImage;
@property(nonatomic, retain) UIImage* pressedImage;
@end

@implementation CustomButton
@synthesize title =  _title;
@synthesize normalImage =  _normalImage;
@synthesize pressedImage =  _pressedImage;

+ (CustomButton*)buttonWithTitle:(NSString*)title normalImage:(UIImage*)normalImage pressedImage:(UIImage*)pressedImage
{
  CustomButton* button = [CustomButton buttonWithType:UIButtonTypeCustom];
  button.title = title;
  button.normalImage = normalImage;
  button.pressedImage = pressedImage;
  return button;
}

- (void)dealloc
{
  [_title release];
  [_normalImage release];
  [_pressedImage release];
  [super dealloc];
}
@end



//currently, you have to add buttons after you pass in all custom property values

@interface CustomSegmentedControl()

@property(nonatomic, retain) NSMutableArray* segmentList;
@property(nonatomic, retain) NSMutableArray* separatorList;
- (void)addSeparators;
- (void)buttonClicked:(id)sender;
- (void)updateButtonStyle:(CustomButton*)button isPressed:(BOOL)isPressed;

@end


@implementation CustomSegmentedControl
@synthesize segmentList =  _segmentList;
@synthesize separatorList =  _separatorList;

@synthesize backgroundNormalImage =  _backgroundNormalImage;
@synthesize backgroundPressedImage =  _backgroundPressedImage;

@synthesize backgroundNormalColor =  _backgroundNormalColor;
@synthesize backgroundPressedColor =  _backgroundPressedColor;

@synthesize seperatorImage =  _seperatorImage;
@synthesize titleLeftEdge =  _titleLeftEdge;
@synthesize imageLeftEdge =  _imageLeftEdge;

@synthesize selectedSegmentIndex =  _selectedSegmentIndex;
@synthesize delegate =  _delegate;
@synthesize titleFont =  _titleFont;
@synthesize titlePressedColor =  _titlePressedColor;
@synthesize titleNormalColor =  _titleNormalColor;

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) {
    _segmentList = [[NSMutableArray alloc] init];
    _separatorList = [[NSMutableArray alloc] init];
    _selectedSegmentIndex = 0;    
    
    _seperatorImage = [[UIImage imageNamed:@"gree_segment_separator.png"] retain];      
    _backgroundPressedColor = [[UIColor colorWithRed:139./255.f green:144./255.f blue:147./255.f alpha:1] retain];
    _backgroundNormalColor = [[UIColor colorWithRed:203./255.f green:203./255.f blue:203/255.f alpha:1] retain];
    
    self.autoresizingMask =  UIViewAutoresizingFlexibleWidth;
    self.autoresizesSubviews = YES;
    self.backgroundColor = [UIColor clearColor];
  }
  return self;
}

- (void)dealloc
{
  [_segmentList release];
  [_separatorList release];
  [_backgroundNormalImage release];
  [_backgroundPressedImage release];
  [_backgroundNormalColor release];
  [_backgroundPressedColor release];

  [_seperatorImage release];
  [_titleFont release];
  [_titlePressedColor release];
  [_titleNormalColor release];
  [super dealloc];
}

- (void)layoutButtons
{    
  int numOfSegments = self.segmentList.count;	
  int numOfSeparators = self.separatorList.count;
  
  float buttonWidth = floorf((self.frame.size.width - SEPARATOR_WIDTH * numOfSeparators)/(float)numOfSegments);
  float buttonHeight = self.frame.size.height;
  
	float currentX = 0.0;
  for (int buttonIndex = 0; buttonIndex < numOfSegments; buttonIndex++) {
		CustomButton* button = [self.segmentList objectAtIndex:buttonIndex];
		button.frame = CGRectMake(currentX, 0, buttonWidth, buttonHeight);
    
    CGRect imageFrame = button.imageView.frame;
    button.imageView.frame = CGRectMake(imageFrame.origin.x, imageFrame.origin.y, imageFrame.size.width-30, imageFrame.size.height-30);
    
    //there is no separator view following the last button 
    int separatorIndex = buttonIndex;
    if (separatorIndex <= numOfSeparators - 1) {
      UIImageView* separator = [self.separatorList objectAtIndex:separatorIndex];
      separator.frame = CGRectMake(currentX + buttonWidth, 0, SEPARATOR_WIDTH, self.frame.size.height);
    }
    currentX += (buttonWidth + SEPARATOR_WIDTH);
	}
}

-(void)layoutSubviews{
	[super layoutSubviews];
	[self layoutButtons];
}

- (void)setSelectedSegmentIndex:(int)selectedSegmentIndex
{
  CustomButton* buttonClicked = [self.segmentList objectAtIndex:selectedSegmentIndex];
  [self buttonClicked:buttonClicked];
}

- (void)buttonClicked:(id)sender
{
  int previousSegmentIndex = _selectedSegmentIndex;
  int selectedSegmentIndex = [self.segmentList indexOfObject:sender];  
  _selectedSegmentIndex = selectedSegmentIndex;
  
  CustomButton* previousClickedButton = (CustomButton*)[self.segmentList objectAtIndex:previousSegmentIndex];
  [self updateButtonStyle:previousClickedButton isPressed:NO];

  CustomButton* currentClickedButton = (CustomButton*)sender;
  [self updateButtonStyle:currentClickedButton isPressed:YES];
  
  if (self.delegate && [self.delegate respondsToSelector:@selector(segmentedControlValueChanged:)]) {
    [self.delegate segmentedControlValueChanged:selectedSegmentIndex];
  }
}

- (void)updateButtonStyle:(CustomButton*)button isPressed:(BOOL)isPressed
{
  //if background image is set, then use image, if not, then use color
  if (self.backgroundNormalImage && self.backgroundPressedImage) {
    if (isPressed) {
      [button setBackgroundImage:self.backgroundPressedImage forState:UIControlStateNormal];
      [button setUserInteractionEnabled:NO];
    }else{
      [button setBackgroundImage:self.backgroundNormalImage forState:UIControlStateNormal];
      [button setUserInteractionEnabled:YES];
    }
  }else{
    if (isPressed) {
      [button setBackgroundColor:self.backgroundPressedColor];
      [button setUserInteractionEnabled:NO];
    }else{
      [button setBackgroundColor:self.backgroundNormalColor];
      [button setUserInteractionEnabled:YES];
    }    
  }
  
  //update button title text color
  if (self.titlePressedColor && isPressed) {
    [button setTitleColor:self.titlePressedColor forState:UIControlStateNormal];
  }
  if (self.titleNormalColor && !isPressed) {
    [button setTitleColor:self.titleNormalColor forState:UIControlStateNormal];      
  }
  
  //update button image
  if (button.pressedImage && isPressed) {
    [button setImage:button.pressedImage forState:UIControlStateNormal];
  }
  if (button.normalImage && !isPressed) {
    [button setImage:button.normalImage forState:UIControlStateNormal];
  }
}

- (void)setButtonStyle:(CustomButton*)button
{
  button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  
  [button setTitle:button.title forState:UIControlStateNormal];
  [button setTitleEdgeInsets:UIEdgeInsetsMake(0, self.titleLeftEdge, 0, 0)];
  button.titleLabel.font = self.titleFont;
  
  [button setImage:button.normalImage forState:UIControlStateNormal]; 
  button.adjustsImageWhenHighlighted = NO;
  [button setImageEdgeInsets:UIEdgeInsetsMake(0, self.imageLeftEdge, 0, 0)];
  
  [self updateButtonStyle:button isPressed:NO];
  [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)addSegmentWithTitle:(NSString *)title normalImage:(UIImage*)normalImage pressedImage:(UIImage*)pressedImage 
{
  CustomButton* button = [CustomButton buttonWithTitle:title normalImage:normalImage pressedImage:pressedImage];
  [self setButtonStyle:button];
  [self.segmentList addObject:button];
  [self addSubview:button];
}

- (void)addSeparators
{
  for (int buttonIndex = 0; buttonIndex < self.segmentList.count - 1; buttonIndex++) {
    UIImageView* separatorView = [[UIImageView alloc] initWithImage:self.seperatorImage];
    [self.separatorList addObject:separatorView];
    [self addSubview:separatorView];
    [separatorView release];
	}
}

- (void)addSegmentsWithTitleAndTwoImages:(id)firstObject, ... 
{
  NSString* title = nil;
  UIImage* normalImage = nil;
  UIImage* pressedImage = nil;
  
  va_list argumentList;
  va_start(argumentList, firstObject);
  id currentObject = firstObject;
  while (currentObject != nil) {
    title = (NSString*)currentObject;
    currentObject = va_arg(argumentList, id);
    normalImage = (UIImage*)currentObject;
    currentObject = va_arg(argumentList, id);
    pressedImage = (UIImage*)currentObject;
    [self addSegmentWithTitle:title normalImage:normalImage pressedImage:pressedImage];
    
    currentObject = va_arg(argumentList, id);
  }
  va_end(argumentList);
  
  //by default make the first segment control pressed down
  CustomButton* button = [_segmentList objectAtIndex:_selectedSegmentIndex];
  [self updateButtonStyle:button isPressed:YES];
  //add separator views
  [self addSeparators];
}


@end
