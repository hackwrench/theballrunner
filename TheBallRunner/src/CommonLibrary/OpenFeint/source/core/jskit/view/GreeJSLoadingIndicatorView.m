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


#import <QuartzCore/QuartzCore.h>
#import "GreeJSLoadingIndicatorView.h"
#import "UIImage+GreeAdditions.h"

#define kSpinAnimationKey @"spinAnimation"

/*
@interface GreeJSLoadingIndicatorView

@end
*/

@implementation GreeJSLoadingIndicatorView
@synthesize imageView = imageView_;
@synthesize animationDuration = animationDuration_;
@synthesize loadingIndicatorType = loadingIndicatorType_;
#pragma mark - Object Lifecycle

- (id)init
{
  self = [super init];
  if (self)
  {
    animationDuration_ = 0.8f;
    loadingIndicatorType_ = GreeJSLoadingIndicatorTypeDefault;
    self.frame = CGRectMake(0, 0, 32.0f, 32.0f);
    self.autoresizingMask =
    UIViewAutoresizingFlexibleLeftMargin  |
    UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleTopMargin   |
    UIViewAutoresizingFlexibleBottomMargin;
  }
  return self;
}

- (void)dealloc
{
  [imageView_ release];
  imageView_ = nil;
  [super dealloc];
}

- (id)initWithLoadingIndicatorType:(GreeJSLoadingIndicatorType)type
{
  self = [self init];
  if (self)
  {
    loadingIndicatorType_ = type;
    if (self.loadingIndicatorType == GreeJSLoadingIndicatorTypeDefault) {
      self.frame = CGRectMake(0, 0, 32.0f, 32.0f);
    } else if (self.loadingIndicatorType == GreeJSLoadingIndicatorTypePullToRefresh) {
      self.frame = CGRectMake(0, 0, 24.0f, 24.0f);
    }
    [self setupViews];
    [self spin];
  }
  return self;
}

#pragma mark - Internal Methods

- (void)setupViews
{  
  self.imageView = [[[UIImageView alloc] initWithFrame:self.frame] autorelease];
  self.imageView.contentMode = UIViewContentModeScaleAspectFit;
  if (self.loadingIndicatorType == GreeJSLoadingIndicatorTypeDefault) {
    self.imageView.image = [UIImage greeImageNamed:@"gree_loader.png"];    
  } else if (self.loadingIndicatorType == GreeJSLoadingIndicatorTypePullToRefresh)
    self.imageView.image = [UIImage greeImageNamed:@"gree_loader_dark.png"];
  [self addSubview:self.imageView];
}

- (void)spin
{
  CABasicAnimation *spinAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
  spinAnimation.removedOnCompletion = NO;
  spinAnimation.byValue = [NSNumber numberWithFloat:2.0f*M_PI];
  spinAnimation.duration = self.animationDuration;
  spinAnimation.repeatCount = NSIntegerMax;
  [self.imageView.layer addAnimation:spinAnimation forKey:kSpinAnimationKey];
}

@end
