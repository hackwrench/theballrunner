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


@protocol CustomSegmentedControlDelegate <NSObject>
@optional
- (void)segmentedControlValueChanged:(int)selectedSegmentIndex;
@end



@interface CustomSegmentedControl : UIView

@property(nonatomic, retain) UIImage* backgroundNormalImage;
@property(nonatomic, retain) UIImage* backgroundPressedImage;
@property(nonatomic, retain) UIColor* backgroundNormalColor;
@property(nonatomic, retain) UIColor* backgroundPressedColor;

@property(nonatomic, retain) UIImage* seperatorImage;

@property(nonatomic, retain) UIFont* titleFont;
@property(nonatomic, retain) UIColor* titlePressedColor;
@property(nonatomic, retain) UIColor* titleNormalColor;
@property(nonatomic, assign) float titleLeftEdge;
@property(nonatomic, assign) float imageLeftEdge;

@property(nonatomic, assign) id<CustomSegmentedControlDelegate> delegate;
@property(nonatomic, assign) int selectedSegmentIndex;

- (void)addSegmentsWithTitleAndTwoImages:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION;

@end






