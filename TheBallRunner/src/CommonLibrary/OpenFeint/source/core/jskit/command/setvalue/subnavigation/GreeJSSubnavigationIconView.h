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


#import <UIKit/UIKit.h>

static float const kSubnavigationIconImageWidth       = 50.0f;
static float const kSubnavigationIconImageHeight      = 40.0f;

@class GreeJSSubnavigationIconView;

@protocol GreeJSSubnavigationMenuButtonDelegate
- (void)onSubnavigationMenuButtonIconTap:(GreeJSSubnavigationIconView*)button;
@end

@interface GreeJSSubnavigationIconView : UIButton
{
  UILabel     *_label;
  UIImageView *_iconImageView;
  NSString    *_iconName;
  
  UIImage     *_normalImage;
  UIImage     *_selectedImage;
}

@property (nonatomic, assign) NSObject<GreeJSSubnavigationMenuButtonDelegate> *delegate;
@property (nonatomic, retain) NSString *callback;
@property (nonatomic, retain) NSDictionary *callbackParams;
@property (nonatomic, retain) NSString *labelString;
@property (nonatomic, readwrite, retain) UIImage *normalImage;
@property (nonatomic, readwrite, retain) UIImage *selectedImage;

- (id)initWithNormalImage:(UIImage*)normalImage
         selectedImage:(UIImage*)selectedImage
                params:(NSDictionary*)params 
              delegate:(NSObject<GreeJSSubnavigationMenuButtonDelegate>*)delegate;

@end
