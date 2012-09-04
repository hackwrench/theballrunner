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

#import "ActivityView.h"
#import "UIColor+ShowCaseAdditions.h"

@interface ActivityView ()
@property(nonatomic, retain) UIActivityIndicatorView* indicator;
@property(nonatomic, assign) UIView* containerView; //use assign instead of retain to avoid circle retaining
@property(nonatomic, assign) int numOfLoadingRequests;
@end

@implementation ActivityView
@synthesize indicator =  _indicator;
@synthesize containerView =  _containerView;
@synthesize numOfLoadingRequests =  _numOfLoadingRequests;


#pragma mark - Object Lifecycle
- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor= [UIColor colorWithWhite:.8 alpha:.7];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _indicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | 
                                  UIViewAutoresizingFlexibleRightMargin | 
                                  UIViewAutoresizingFlexibleBottomMargin |
                                  UIViewAutoresizingFlexibleTopMargin;
  }
  return self;
}

+ (ActivityView*)activityViewWithContainer:(UIView*)containerView
{
  ActivityView* view = [[ActivityView alloc] initWithFrame:containerView.frame];
  view.containerView = containerView;
  return [view autorelease];
}

- (void)dealloc
{
  [_indicator removeFromSuperview];
  [_indicator release];
  [super dealloc];
}

#pragma mark - Public Interface
- (void)startLoading
{
  if (self.numOfLoadingRequests < 0) {
    self.numOfLoadingRequests = 0;
  }
  if (self.numOfLoadingRequests == 0) {
    self.indicator.center = self.center;
    [self.indicator startAnimating];
    [self addSubview:self.indicator];
    [self.containerView addSubview:self];
  }
  self.numOfLoadingRequests++;
}

- (void)stopLoading
{
  self.numOfLoadingRequests--;
  if (self.numOfLoadingRequests == 0) {
    [self.indicator stopAnimating];
    [self.indicator removeFromSuperview];
    [self removeFromSuperview];
  }else if (self.numOfLoadingRequests < 0) {
    self.numOfLoadingRequests = 0;
  }
}

#pragma mark - UIView Overrides

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, containerView:%p>", NSStringFromClass([self class]), self, self.containerView];
}

#pragma mark - Internal Methods

@end
