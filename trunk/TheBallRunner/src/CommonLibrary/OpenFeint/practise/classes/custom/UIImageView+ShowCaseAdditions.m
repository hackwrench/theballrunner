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

#import "UIImageView+ShowCaseAdditions.h"

@interface UIImage(scale)
- (UIImage*)imageScaledToSize:(CGSize)size;
+ (UIImage*)imageFromColor:(UIColor *)color;
@end

@implementation UIImage(scale)
- (UIImage*)imageScaledToSize:(CGSize)size 
{
  UIGraphicsBeginImageContext(size);
  [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

+ (UIImage*)imageFromColor:(UIColor *)color 
{
  CGRect rect = CGRectMake(0, 0, 1, 1);
  UIGraphicsBeginImageContext(rect.size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, [color CGColor]);
  CGContextFillRect(context, rect);
  UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return img;
}

@end


@implementation UIImageView (ShowCaseAdditions)
#pragma mark private methods
static int INDICATOR_TAG = 13254;
- (UIActivityIndicatorView*)getLoadingIndicator
{
  UIActivityIndicatorView* indicator = (UIActivityIndicatorView*)[self viewWithTag:INDICATOR_TAG];
  if (![indicator isKindOfClass:[UIActivityIndicatorView class]]) {
    indicator = nil;
  }
  return indicator;
}

- (void)showLoadingIndicator:(CGSize)imageSize
{
  UIActivityIndicatorView* indicator = [self getLoadingIndicator];
  if (!indicator) {
    indicator = [[[UIActivityIndicatorView alloc] 
                  initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    indicator.tag = INDICATOR_TAG;
    indicator.center = CGPointMake(floorf(imageSize.width/2.), floorf(imageSize.height/2.));
  }
  [indicator startAnimating];  
  [self addSubview:indicator];
}

- (void)removeLoadingIndicator
{
  UIActivityIndicatorView* indicator = [self getLoadingIndicator];
  [indicator stopAnimating];
  [indicator removeFromSuperview];
}



#pragma mark public methods

- (void)showLoadingImageWithSize:(CGSize)imageSize
{
  UIImage* whitebg = [[UIImage imageFromColor:[UIColor colorWithWhite:0.9 alpha:.8]] imageScaledToSize:imageSize];
  self.image = whitebg;
  [self showLoadingIndicator:imageSize];
}

- (void)showImage:(UIImage*)image withSize:(CGSize)imageSize
{
  if (image == nil) {
    image = [UIImage imageNamed:@"noimage_small.png"];
    self.backgroundColor = [UIColor colorWithWhite:0.9 alpha:.8];
  }else{
    self.backgroundColor = [UIColor clearColor];
  }
  UIImage* imageToShow = [image imageScaledToSize:imageSize];
  self.image = imageToShow;
  [self removeLoadingIndicator];
}

- (void)showNoImageWithSize:(CGSize)imageSize
{
  [self showImage:nil withSize:imageSize];
}

- (BOOL)hasValidImage
{  
  UIActivityIndicatorView* indicator = [self getLoadingIndicator];
  if (indicator != nil) {
    return NO;
  }else{
    return self.image != nil ? YES : NO;
  }
}


@end
