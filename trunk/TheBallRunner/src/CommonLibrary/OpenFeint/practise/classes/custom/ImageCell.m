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

#import "ImageCell.h"
#import <QuartzCore/QuartzCore.h>

@interface ImageCell()
@property(nonatomic, assign) float scale;
@property(nonatomic, assign) float height;
@end

@implementation ImageCell
@synthesize scale =  _scale;
@synthesize height = _height;

- (id)initWithScale:(float)scale height:(float)height reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
  if (self) {
    if (scale < 0 || scale > 1) {
      scale = 1.f;
    }
    _scale = scale;
    _height = height;
    self.imageView.layer.masksToBounds = YES;
    self.imageView.layer.cornerRadius = 5.0;
  }
  return self;
}

- (CGSize)imageSize
{
  float height = self.height * self.scale;
  return CGSizeMake(height, height);
}

@end
