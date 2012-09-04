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

#import "GreeRotator.h"
#import "GreePlatform+Internal.h"

@interface GreeRotatorContainerView : UIView
@end

@implementation GreeRotatorContainerView
- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  UIView *view = [super hitTest:point withEvent:event];
  
  if (view == self) {
    return nil;
  }
  
  return view;
}
@end

static UIInterfaceOrientation normalizeInterfaceOrientation(UIInterfaceOrientation viewControllerOrientation, UIInterfaceOrientation platformOrientation) {
  UIInterfaceOrientation returnOrientation;

  switch (viewControllerOrientation) {
    default:
    case UIInterfaceOrientationPortrait:
      returnOrientation = platformOrientation;
      break;
    case UIInterfaceOrientationLandscapeLeft:
      {
        switch(viewControllerOrientation) {
          default:
          case UIInterfaceOrientationPortrait:
            returnOrientation = UIInterfaceOrientationLandscapeLeft;
            break;
          case UIInterfaceOrientationLandscapeLeft:
            returnOrientation = UIInterfaceOrientationPortrait;
            break;
          case UIInterfaceOrientationPortraitUpsideDown:
            returnOrientation = UIInterfaceOrientationLandscapeRight;
            break;
          case UIInterfaceOrientationLandscapeRight:
            returnOrientation = UIInterfaceOrientationPortraitUpsideDown;
            break;
        }
      }
      break;
    case UIInterfaceOrientationPortraitUpsideDown:
      {
        switch(viewControllerOrientation) {
          default:
          case UIInterfaceOrientationPortrait:
            returnOrientation = UIInterfaceOrientationPortraitUpsideDown;
            break;
          case UIInterfaceOrientationLandscapeLeft:
            returnOrientation = UIInterfaceOrientationLandscapeRight;
            break;
          case UIInterfaceOrientationPortraitUpsideDown:
            returnOrientation = UIInterfaceOrientationPortrait;
            break;
          case UIInterfaceOrientationLandscapeRight:
            returnOrientation = UIInterfaceOrientationLandscapeLeft;
            break;
        }
      }
      break;
    case UIInterfaceOrientationLandscapeRight:
      {
        switch(viewControllerOrientation) {
          default:
          case UIInterfaceOrientationPortrait:
            returnOrientation = UIInterfaceOrientationLandscapeRight;
            break;
          case UIInterfaceOrientationLandscapeLeft:
            returnOrientation = UIInterfaceOrientationPortraitUpsideDown;
            break;
          case UIInterfaceOrientationPortraitUpsideDown:
            returnOrientation = UIInterfaceOrientationLandscapeLeft;
            break;
          case UIInterfaceOrientationLandscapeRight:
            returnOrientation = UIInterfaceOrientationPortrait;
            break;
        }
      }
      break;
    }
    
    return returnOrientation;
}

@interface GreeRotator ()
@property (nonatomic, retain) NSMutableDictionary *rotatingViewsDictionary;

- (void)rotateView:(UIView*)view toInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;

+ (CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)interfaceOrientation;
+ (CGRect)boundsForOrientation:(UIInterfaceOrientation)interfaceOrientation rect:(CGRect)rect;
+ (CGPoint)centerForOrientation:(UIInterfaceOrientation)interfaceOrientation bounds:(CGRect)bounds;
@end

@implementation GreeRotator

@synthesize rotatingViewsDictionary = _rotatingViewsDictionary;

#pragma mark - Object Lifecycle

- (id)init
{
  if ((self = [super init])) {
    _rotatingViewsDictionary = [[NSMutableDictionary alloc] initWithCapacity:8];
  }
  
  return self;
}

- (void)dealloc
{
  [_rotatingViewsDictionary release];
  [super dealloc];
}

#pragma mark - Internal Methods

- (void)beginRotatingSubview:(UIView *)subview insideOfView:(UIView *)superview relativeToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  GreeRotatorContainerView *rotatingContainerView = [[GreeRotatorContainerView alloc] initWithFrame:superview.bounds];
  
    
  UIInterfaceOrientation normalizedOrientation = normalizeInterfaceOrientation(
    interfaceOrientation,
    [[GreePlatform sharedInstance] interfaceOrientation]
  );
  
  rotatingContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [superview addSubview:rotatingContainerView];
  [rotatingContainerView addSubview:subview];
  [self rotateView:rotatingContainerView toInterfaceOrientation:normalizedOrientation];
  [self.rotatingViewsDictionary setObject:rotatingContainerView forKey:[NSValue valueWithNonretainedObject:subview]];
    
    //[rotatingContainerView  release];
  
}

- (void)endRotatingSubview:(UIView *)subview {
  [subview removeFromSuperview];
  [self.rotatingViewsDictionary removeObjectForKey:[NSValue valueWithNonretainedObject:subview]];
}

- (void)rotateViewsToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation animated:(BOOL)animated duration:(NSTimeInterval)duration {
  void (^animations)(void) = ^{
    for (id key in self.rotatingViewsDictionary) {
      UIView *rotatingView = (UIView*)[self.rotatingViewsDictionary objectForKey:key];
      [self rotateView:rotatingView toInterfaceOrientation:interfaceOrientation];
    }
  };
  
  if (animated) {
    [UIView animateWithDuration:duration animations:animations];
  } else {
    animations();
  }
}

- (void)rotateView:(UIView*)view toInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{   
  view.transform = [[self class] transformForOrientation:interfaceOrientation];
  view.bounds = [[self class] boundsForOrientation:interfaceOrientation rect:view.superview.bounds];
  view.center = [[self class] centerForOrientation:interfaceOrientation bounds:view.bounds];
  
  if (CGRectEqualToRect([view.superview convertRect:view.superview.bounds toView:nil], [[UIScreen mainScreen] bounds]) &&
    !(CGRectEqualToRect([view.superview convertRect:view.superview.bounds toView:nil], [[UIScreen mainScreen] applicationFrame]))) {
    view.frame = [view.superview convertRect:[[UIScreen mainScreen] applicationFrame] fromView:nil];
  }
}

+ (CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)interfaceOrientation {
  CGAffineTransform transform = CGAffineTransformIdentity;
  
  switch (interfaceOrientation) {
    case UIInterfaceOrientationLandscapeLeft:
      transform = CGAffineTransformMakeRotation(3*M_PI_2);
      break;
    case UIInterfaceOrientationLandscapeRight:
      transform = CGAffineTransformMakeRotation(M_PI_2);
      break;
    case UIInterfaceOrientationPortraitUpsideDown:
      transform = CGAffineTransformMakeRotation(M_PI);
    case UIInterfaceOrientationPortrait:
    default:
        break;
  }
  
  return transform;
}

+ (CGRect)boundsForOrientation:(UIInterfaceOrientation)interfaceOrientation rect:(CGRect)rect {
  CGRect bounds;

  switch (interfaceOrientation) {
    case UIInterfaceOrientationLandscapeLeft:
    case UIInterfaceOrientationLandscapeRight:
      bounds = CGRectMake(0.0f, 0.0f, rect.size.height, rect.size.width);
      break;
    case UIInterfaceOrientationPortraitUpsideDown:
    case UIInterfaceOrientationPortrait:
    default:
      bounds = CGRectMake(0.0f, 0.0f, rect.size.width, rect.size.height);
      break;
  }
  
  return bounds;
}

+ (CGPoint)centerForOrientation:(UIInterfaceOrientation)interfaceOrientation bounds:(CGRect)bounds {
  CGPoint center;

  switch (interfaceOrientation) {
    case UIInterfaceOrientationLandscapeLeft:
    case UIInterfaceOrientationLandscapeRight:
      center = CGPointMake(CGRectGetMidY(bounds), CGRectGetMidX(bounds));
      break;
    case UIInterfaceOrientationPortraitUpsideDown:
    case UIInterfaceOrientationPortrait:
    default:
      center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
      break;
  }
  
  return center;
}

@end
