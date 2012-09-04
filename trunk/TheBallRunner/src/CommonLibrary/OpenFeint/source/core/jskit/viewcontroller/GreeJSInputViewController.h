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

@class GreeJSWebViewController, GreeJSTakePhotoActionSheet, GreeJSTakePhotoPickerController, GreeJSLoadingIndicatorView;
@interface GreeJSInputViewController : UIViewController
  <UITextViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
@protected
  NSDictionary *params_;
  NSUInteger limit_;
  NSMutableArray *images_;
  
  NSArray *atLeastOneRequiredFields_;
  NSArray *requiredFields_;
  
  UIImageView *imageView_;
  UITextView *textView_;
  UIToolbar *toolbar_;
  UILabel *textCounterLabel_;
  UILabel *textLimitLabel_;
  UILabel *placeholderLabel_;

  GreeJSTakePhotoActionSheet *imageTypeSelector_;
  GreeJSTakePhotoPickerController *photoPickerController_;
  id popoverImagePicker_;

  GreeJSWebViewController *beforeViewController_;
}
@property(nonatomic, assign) GreeJSWebViewController *beforeViewController;
@property(nonatomic, retain) UITextView *textView;
@property(nonatomic, retain) UIToolbar *toolbar;
@property(nonatomic, retain) NSDictionary *params;
@property(nonatomic, retain) NSMutableArray *images;
@property(nonatomic, assign) NSUInteger limit;
@property(nonatomic, retain) UIImageView *imageView;
@property(nonatomic, retain) UILabel *textCounterLabel;
@property(nonatomic, retain) UILabel *textLimitLabel;
@property(nonatomic, retain) UILabel *placeholderLabel;
@property(nonatomic, retain) GreeJSTakePhotoActionSheet *imageTypeSelector;
@property(nonatomic, retain) GreeJSTakePhotoPickerController *photoPickerController;
@property(nonatomic, retain) id popoverImagePicker;
@property(nonatomic, retain) GreeJSLoadingIndicatorView *loadingIndicator;

- (id)initWithParams:(NSDictionary *)params;
- (NSDictionary *)data;
- (NSDictionary *)callbackParams;
- (void)buildSubViews:(NSDictionary *)params;
- (void)buildTextViews:(NSDictionary *)params;
- (void)configureTextViews:(NSDictionary *)params;
- (void)buildTextCounterViews:(NSDictionary *)params;
- (void)buildToolbarViews:(NSDictionary *)params;
- (void)buildIndicatorViews:(NSDictionary *)params;
- (void)updateTextCounter;
- (void)validateEmpty;
- (NSString *)base64WithImage:(UIImage *)image;
- (void)showIndicator;
- (void)hideIndicator;
- (void)onUIKeyboardDidShowNotification:(NSNotification *)notification;

@end
