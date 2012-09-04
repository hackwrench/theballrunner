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

#import "UIView+GreeAdditions.h"
#import "UIWebView+GreeAdditions.h"
#import "GreePlatform+Internal.h"
#import "GreeRotator.h"

@interface UIView (GreeAdditionsPrivate)
- (UIWebView*)greeWebviewSuperviewOrNil;
@end

@implementation UIView (GreeAdditions)
- (CGRect)greeFirstResponderFrame
{
  if ([self isFirstResponder]) {
    UIWebView *webview = [self greeWebviewSuperviewOrNil];

    if (webview != nil) {
      return [webview greeActiveElementFrame];
    }
    
    return self.bounds;    
  }

  for (UIView *view in self.subviews) {
    CGRect firstResponderFrame = [view greeFirstResponderFrame];

    if (!CGRectIsEmpty(firstResponderFrame)) {
      return [self convertRect:firstResponderFrame fromView:view];
    }
  }

  return CGRectZero;
}

- (UIWebView*)greeWebviewSuperviewOrNil
{
  UIWebView *webview = nil;
  UIView *currentView = self;
  
  while ([currentView superview] != nil) {
    if ([currentView isKindOfClass:[UIWebView class]]) {
      webview = (UIWebView*)currentView;
      break;
    } else {
      currentView = [currentView superview];
    }
  }
  
  return webview;
}

- (void)greeAddRotatingSubview:(UIView *)subview relativeToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  GreeRotator *rotator = [[GreePlatform sharedInstance] rotator];
  [rotator beginRotatingSubview:subview insideOfView:self relativeToInterfaceOrientation:interfaceOrientation];
}

- (void)greeRemoveRotatingSubviewFromSuperview {
  GreeRotator *rotator = [[GreePlatform sharedInstance] rotator];
  [rotator endRotatingSubview:self];
}
@end
