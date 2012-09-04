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


#import "GreeJSInputViewController.h"
#import "GreeJSWebViewController+ModalView.h"
#import <QuartzCore/QuartzCore.h>
#import "GreeJSTakePhotoActionSheet.h"
#import "GreeJSImageConfirmationViewController.h"
#import "GreeJSUIImage+TakePhoto.h"
#import "GreeJSTakePhotoPickerController.h"
#import "GreeJSLoadingIndicatorView.h"
#import "GreePlatform.h"
#import "GreePlatform+Internal.h"
#import "GreeHTTPClient.h"
#import "GreeGlobalization.h"
#import "UIImage+GreeAdditions.h"
#import "UIViewController+GreeAdditions.h"
#import "GreePlatformSettings.h"
#import "GreeSettings.h"
#import "GreeLogger.h"

static CGFloat kRightMargin = 8.0f;
static CGFloat kGreeJSTextInputViewHeight = 100.0f;
static CGFloat kGreeJSTextToolbarHeight = 44.0f;

NSString* const kGreeJSInputSingleLineParam = @"singleline";

@interface GreeJSInputViewController()

@property (nonatomic, retain) NSDictionary* initialParams;
@property (nonatomic, retain) NSSet *previousOrientations;
@property (nonatomic, retain) NSArray *atLeastOneRequiredFields;
@property (nonatomic, retain) NSArray *requiredFields;

- (void)setupTextLimit:(NSDictionary *)params;
- (void)createCallbackParams:(NSDictionary *)params;
- (void)showImagePicker:(UIButton *)sender;
- (void)showImagePickerSelected:(UIButton *)sender;
- (void)showImageTypeSelector:(BOOL)selected withTag:(NSInteger)tag;
- (void)setImage:(UIImage *)image atIndex:(NSInteger)index;
- (void)removeImageAtIndex:(NSInteger)index;
- (void)setPlaceholder:(NSString *)placeholder color:(UIColor *)color;
- (void)showPlaceholder;
- (void)hidePlaceholder;
- (void)onUIKeyboardWillShowNotification:(NSNotification *)notification;
- (void)setupValidation:(NSDictionary*)params;
- (BOOL)validate;
- (NSArray*)parseAtLeastOneRequiredFieldsForParams:(NSDictionary*)params;
- (BOOL)isFieldRequired:(NSString*)fieldName forParams:(NSDictionary*)params;
- (BOOL)validateField:(NSString*)fieldName;
- (BOOL)validateTextField;
- (BOOL)validatePhotoField;

@end


@implementation GreeJSInputViewController
@synthesize initialParams = initialParams_;
@synthesize params = params_;
@synthesize limit = limit_;
@synthesize images = images_;
@synthesize imageView = imageView_;
@synthesize textView = textView_;
@synthesize toolbar = toolbar_;
@synthesize textCounterLabel = textCounterLabel_;
@synthesize textLimitLabel = textLimitLabel_;
@synthesize placeholderLabel = placeholderLabel_;
@synthesize imageTypeSelector = imageTypeSelector_;
@synthesize photoPickerController = photoPickerController_;
@synthesize popoverImagePicker = popoverImagePicker_;
@synthesize beforeViewController = beforeViewController_;
@synthesize loadingIndicator = loadingIndicator_;
@synthesize previousOrientations = previousOrientations_;
@synthesize atLeastOneRequiredFields = atLeastOneRequiredFields_;
@synthesize requiredFields = requiredFields_;


#pragma mark - Object Lifecycle

- (id)initWithParams:(NSDictionary *)params
{
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    initialParams_ = [params copy];
    [self setupTextLimit:initialParams_];
    [self setupValidation:initialParams_];
    [self createCallbackParams:initialParams_];
  }
  return self;
}

- (void)dealloc
{
  [initialParams_ release];
  [params_ release];
  [images_ release];
  [imageView_ release];
  [textView_ release];
  [toolbar_ release];
  [textCounterLabel_ release];
  [textLimitLabel_ release];
  [placeholderLabel_ release];
  [imageTypeSelector_ release];
  [photoPickerController_ release];
  [popoverImagePicker_ release];
  [loadingIndicator_ release];
  [atLeastOneRequiredFields_ release];
  [requiredFields_ release];
  
  params_ = nil;
  images_ = nil;
  imageView_ = nil;
  textView_ = nil;
  toolbar_ = nil;
  textCounterLabel_ = nil;
  textLimitLabel_ = nil;
  placeholderLabel_ = nil;
  imageTypeSelector_ = nil;
  photoPickerController_ = nil;
  popoverImagePicker_ = nil;
  loadingIndicator_ = nil;
  atLeastOneRequiredFields_ = nil;
  requiredFields_ = nil;
  
  [super dealloc];
}

#pragma mark - UIViewController Overrides

- (void)loadView
{
  [super loadView];
  UIView* myView = self.view;
  self.wantsFullScreenLayout = NO;
  myView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  myView.autoresizesSubviews = YES;
  
  [self buildSubViews:self.initialParams];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return YES;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
    
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(onUIKeyboardDidShowNotification:)
                                               name:UIKeyboardDidShowNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(onUIKeyboardWillShowNotification:)
                                               name:UIKeyboardWillShowNotification
                                             object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
  if ([self.textView canBecomeFirstResponder]) {
    [self.textView becomeFirstResponder];
  }
  
  [self updateTextCounter];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - UIImagePickerControllerDelegate Methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  
  UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
  if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
  {
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, NULL);
    [picker greeDismissViewControllerAnimated:YES completion:nil];
    
    [self setImage:image atIndex:self.photoPickerController.tag];
  }
  else
  {
    GreeJSImageConfirmationViewController *controller =
      [[[GreeJSImageConfirmationViewController alloc] init] autorelease];
    controller.delegate = self;
    controller.tag = self.photoPickerController.tag;
    controller.image = image;
    
    [picker pushViewController:controller animated:YES];
  }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
      && picker.sourceType != UIImagePickerControllerSourceTypeCamera)
  {
    [self.popoverImagePicker dismissPopoverAnimated:YES];
  }
  else
  {
    [picker greeDismissViewControllerAnimated:YES completion:nil];
  }
}

- (void)imageDidSelected:(GreeJSImageConfirmationViewController *)controller
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    [self.popoverImagePicker dismissPopoverAnimated:YES];
  } else {
    UIImagePickerController *picker = self.photoPickerController.imagePickerController;
    [picker greeDismissViewControllerAnimated:YES completion:nil];
	}
  
  [self setImage:controller.image atIndex:controller.tag];
}


#pragma mark - UIActionSheetDelegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  GreeJSTakePhotoActionSheet *as = (GreeJSTakePhotoActionSheet *)actionSheet;
  
  self.photoPickerController = [[[GreeJSTakePhotoPickerController alloc] init] autorelease];
  self.photoPickerController.imagePickerController.delegate = self;
  self.photoPickerController.tag = as.tag;
  
  if (buttonIndex == self.imageTypeSelector.cancelButtonIndex) {
    self.imageTypeSelector = nil;
    return;
  }
  
  if (buttonIndex == self.imageTypeSelector.takePhotoButtonIndex) {
    self.photoPickerController.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
  } else if (buttonIndex == self.imageTypeSelector.chooseFromAlbumButtonIndex) {
    self.photoPickerController.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  } else if (buttonIndex == self.imageTypeSelector.removePhotoButtonIndex) {
    [self removeImageAtIndex:as.tag];
    self.imageTypeSelector = nil;
    return;
  } else {
    self.imageTypeSelector = nil;
    return;
  }
  
  self.imageTypeSelector = nil;
  
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
      && self.photoPickerController.imagePickerController.sourceType != UIImagePickerControllerSourceTypeCamera)
  {
    if (!self.popoverImagePicker)
    {
      Class popoverController = NSClassFromString(@"UIPopoverController");
      self.popoverImagePicker =
        [[[popoverController alloc] initWithContentViewController:self.photoPickerController.imagePickerController] autorelease];
    }
    else
    {
      [self.popoverImagePicker setContentViewController:self.photoPickerController.imagePickerController];
    }
    [self.popoverImagePicker presentPopoverFromRect:CGRectMake(self.view.center.x, self.view.center.y, 32, 32)
                                             inView:self.view
                           permittedArrowDirections:0
                                           animated:YES];
  }
  else
  {
    [self.textView resignFirstResponder];
    [self.navigationController greePresentViewController:self.photoPickerController.imagePickerController animated:YES completion:nil];
  }  
}


#pragma mark - UITextViewDelegate Methods

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
  if ([self.params objectForKey:kGreeJSInputSingleLineParam] && [text isEqualToString:@"\n"]) {
    if ([self.beforeViewController respondsToSelector:@selector(greeJSModalRightButtonPressed:)]) {
      [self.beforeViewController performSelector:@selector(greeJSModalRightButtonPressed:)
                                      withObject:self.navigationItem.rightBarButtonItem];
    }
    return NO;
  }
  return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
  if ([self.params objectForKey:kGreeJSInputSingleLineParam] &&
      [self.textView.text rangeOfString:@"\n"].location != NSNotFound) {
    NSRange range = self.textView.selectedRange;
    self.textView.text = [self.textView.text stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    self.textView.selectedRange = range;
  }
  
  [self updateTextCounter];
  
  NSUInteger textLength = self.textView.text.length;
  if (textLength > 0) {
    [self showPlaceholder];
  } else {
    [self hidePlaceholder];
  }
  
  if (textLength > self.limit) {
    self.textCounterLabel.textColor = [UIColor colorWithRed:0xFF / 255.0f
                                                      green:0x44 / 255.0f
                                                       blue:0x44 / 255.0f
                                                      alpha:1.0f];
  } else {
    self.textCounterLabel.textColor = [UIColor colorWithRed:0x88 / 255.0f
                                                      green:0x88 / 255.0f
                                                       blue:0x88 / 255.0f
                                                      alpha:1.0f];
  }
}


#pragma mark - Public Interface

- (NSDictionary *)data
{
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  
  [data setValue:self.textView.text forKey:@"text"];
  if (self.toolbar) {
    for (int i = 0; i < self.images.count; i++) {
      UIImage *image = [self.images objectAtIndex:i];
      if (image && ![image isEqual:[NSNull null]]) {
        [data setValue:[self base64WithImage:image]
                forKey:[NSString stringWithFormat:@"image%d", i]];
      }
    }
  }

  return data;
}

- (NSDictionary *)callbackParams
{
  return self.params;
}

- (void)buildSubViews:(NSDictionary *)params
{
  self.view.backgroundColor = [UIColor colorWithRed:0xEE / 255.0f
                                              green:0xEE / 255.0f
                                               blue:0xEE / 255.0f
                                              alpha:1.0];
  
  [self buildTextViews:params];
  [self configureTextViews:params];
  [self buildToolbarViews:params];
  [self buildIndicatorViews:params];
}

- (void)buildTextViews:(NSDictionary *)params
{
  NSInteger leftMargin = 0;
  NSString *image = [params valueForKey:@"image"];
  if (image) {
    leftMargin = 44.0f;
    self.imageView = [[[UIImageView alloc] initWithFrame:CGRectMake(8.0f, 8.0f, 36, 36)] autorelease];
    self.imageView.backgroundColor = [UIColor whiteColor];
    self.imageView.layer.cornerRadius = 4.0f;
    self.imageView.layer.masksToBounds = YES;
    self.imageView.layer.opaque = NO;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    [[[GreePlatform sharedInstance] httpClient] downloadImageAtUrl:[NSURL URLWithString:image] withBlock:^(UIImage *icon, NSError *error) {
      if (error) {
        return;
      }
      self.imageView.image = icon;
    }];
    [self.view addSubview:self.imageView];
  }
  
  CGRect bounds = self.view.bounds;
  self.textView = [[[UITextView alloc] initWithFrame:CGRectMake(leftMargin,
                                                                0,
                                                                bounds.size.width - leftMargin,
                                                                kGreeJSTextInputViewHeight)] autorelease];
  NSString *value = [params valueForKey:@"value"];
  self.textView.text = [value isKindOfClass:[NSString class]] ? value : @"";
  
  self.textView.editable = YES;
  self.textView.font = [UIFont systemFontOfSize:16.0f];
  self.textView.backgroundColor = [UIColor clearColor];
  self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.textView.delegate = self;
  
  [self.view addSubview:self.textView];
  
  NSString *placeholder = [params valueForKey:@"placeholder"];
  [self setPlaceholder:placeholder color:[UIColor lightGrayColor]];
}

- (void)buildTextCounterViews:(NSDictionary *)params
{
  CGRect bounds = self.view.bounds;
  self.textCounterLabel = [[[UILabel alloc] init] autorelease];
  self.textCounterLabel.font = [UIFont systemFontOfSize:14.0f];
  self.textCounterLabel.backgroundColor = [UIColor clearColor];
  self.textCounterLabel.textColor = [UIColor colorWithRed:0x88 / 255.0f
                                                    green:0x88 / 255.0f
                                                     blue:0x88 / 255.0f
                                                    alpha:1.0];
  
  self.textLimitLabel = [[[UILabel alloc] init] autorelease];
  self.textLimitLabel.font = [UIFont systemFontOfSize:14.0f];
  self.textLimitLabel.backgroundColor = [UIColor clearColor];
  self.textLimitLabel.textColor = [UIColor colorWithRed:0x88 / 255.0f
                                                  green:0x88 / 255.0f
                                                   blue:0x88 / 255.0f
                                                  alpha:1.0];
  
  NSString *limit = [[NSNumber numberWithUnsignedInteger:self.limit] stringValue];
  self.textLimitLabel.text = [NSString stringWithFormat:@"/%@", limit];
  [self.textLimitLabel sizeToFit];
  
  CGFloat topMargin = (self.toolbar.frame.size.height - self.textLimitLabel.frame.size.height) / 2;
  self.textLimitLabel.frame = CGRectMake(bounds.size.width - self.textLimitLabel.frame.size.width - kRightMargin,
                                         topMargin,
                                         self.textLimitLabel.bounds.size.width,
                                         self.textLimitLabel.bounds.size.height);
  self.textLimitLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

  self.textCounterLabel.frame = CGRectMake(self.textLimitLabel.frame.origin.x - self.textCounterLabel.bounds.size.width,
                                           topMargin,
                                           self.textCounterLabel.bounds.size.width,
                                           self.textCounterLabel.bounds.size.height);
  self.textCounterLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
  
  [self.toolbar addSubview:self.textCounterLabel];
  [self.toolbar addSubview:self.textLimitLabel];
}

- (void)buildToolbarViews:(NSDictionary *)params
{
  CGRect bounds = self.view.bounds;
  
  self.toolbar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0,
                                                              kGreeJSTextInputViewHeight,
                                                              bounds.size.width,
                                                              kGreeJSTextToolbarHeight)] autorelease];
  self.toolbar.tintColor = [UIColor colorWithRed:0xe5 / 255.0f
                                           green:0xe5 / 255.0f
                                            blue:0xe5 / 255.0f
                                           alpha:1.0];
  self.toolbar.backgroundColor = [UIColor colorWithRed:0x00 / 255.0f
                                                 green:0x00 / 255.0f
                                                  blue:0x00 / 255.0f
                                                 alpha:1.0f];
  self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
  
  BOOL usePhoto = [[params valueForKey:@"usePhoto"] boolValue];
  if (usePhoto) {
    NSInteger photoCount = [[params valueForKey:@"photoCount"] integerValue];
    photoCount = photoCount >= 1 ? photoCount : 1;
    self.images = [NSMutableArray arrayWithCapacity:photoCount];
    
    NSMutableArray *items = [NSMutableArray array];
    for (int i = 0; i < photoCount; i++) {
      [self.images addObject:[NSNull null]];
      
      UIImage *cameraNormalImage = [UIImage greeImageNamed:@"gree_btn_take_photo_default.png"];
      UIImage *cameraHighlightImage = [UIImage greeImageNamed:@"gree_btn_take_photo_highlight.png"];
      UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
      cameraButton.frame = CGRectMake(0, 0, 32.0f, 32.0f);
      [cameraButton addTarget:self action:@selector(showImagePicker:) forControlEvents:UIControlEventTouchUpInside];
      [cameraButton setBackgroundImage:cameraNormalImage forState:UIControlStateNormal];
      [cameraButton setBackgroundImage:cameraHighlightImage forState:UIControlStateHighlighted];
      
      UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:cameraButton];      
      item.tag = i;
      [items addObject:item];
      [item release];
      
      UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                             target:nil
                                                                             action:nil];
      space.width = 16.0f;
      [items addObject:space];
      [space release];
    }
    self.toolbar.items = items;
    
    for (int i = 0; i < photoCount; i++) {
      NSString *imageValue = [params valueForKey:[NSString stringWithFormat:@"image%d", i]];
      if (imageValue) {
        UIImage *image = [UIImage greeImageWithBase64:imageValue];
        if (image) {
          [self setImage:image atIndex:i];
        }
      }
    }
  }
  
  [self buildTextCounterViews:params];
  [self.view addSubview:self.toolbar];
}

- (void)buildIndicatorViews:(NSDictionary *)params
{
  self.loadingIndicator = [[[GreeJSLoadingIndicatorView alloc]
                            initWithLoadingIndicatorType:GreeJSLoadingIndicatorTypeDefault] autorelease];
}

- (void)updateTextCounter
{
  [self validateEmpty];
  
  UILabel* label = self.textCounterLabel;
  label.text = [[NSNumber numberWithUnsignedInteger:self.textView.text.length] stringValue];
  CGFloat widthDifference = label.frame.size.width;
  [label sizeToFit];
  widthDifference -= label.frame.size.width;
  self.textCounterLabel.frame = CGRectMake(
    label.frame.origin.x + widthDifference, 
    label.frame.origin.y, 
    label.frame.size.width, 
    label.frame.size.height);
}

- (void)validateEmpty
{
  self.navigationItem.rightBarButtonItem.enabled = [self validate];
}

- (BOOL)validate
{
  NSInteger textLength = self.textView.text.length;
  if (textLength > self.limit) {
    return NO;
  }
  
  for (NSString *field in self.requiredFields) {
    if (![self validateField:field]) {
      return NO;
    }
  }
  
  if (self.atLeastOneRequiredFields.count) {
    BOOL atLeastOnePresent = NO;
    for (NSString *field in self.atLeastOneRequiredFields) {
      if ([self validateField:field]) {
        atLeastOnePresent = YES;
      }
    }
    return atLeastOnePresent;
  }
  
  return YES;
}

- (NSString *)base64WithImage:(UIImage *)image
{
  UIImage* resizedImage = [UIImage greeResizeImage:image maxPixel:480 rotation:0];
  return [resizedImage greeBase64EncodedString];
}


#pragma mark Indicator Interface

- (void)showIndicator
{
  self.loadingIndicator.center = self.textView.center;
  if (!self.loadingIndicator.superview)
    [self.view addSubview:self.loadingIndicator];
}

- (void)hideIndicator
{
  [self.loadingIndicator removeFromSuperview];
}


#pragma mark Keyboard Notifications

- (void)onUIKeyboardDidShowNotification:(NSNotification *)notification
{
  CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
  keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
  CGFloat keyboardHeight = keyboardRect.size.height;
  
  CGRect toolbarFrame = self.toolbar.frame;
  CGFloat toolbarY = self.view.bounds.size.height - keyboardHeight - kGreeJSTextToolbarHeight;
  self.toolbar.frame = CGRectMake(toolbarFrame.origin.x,
                                  toolbarY,
                                  toolbarFrame.size.width,
                                  toolbarFrame.size.height);
  
  CGFloat margin = 5.0f;
  self.textView.frame = CGRectMake(self.textView.frame.origin.x,
                                   self.textView.frame.origin.y,
                                   self.textView.frame.size.width,
                                   self.toolbar.frame.origin.y - margin);
  self.toolbar.hidden = NO;
}

- (void)onUIKeyboardWillShowNotification:(NSNotification *)notification
{
  self.toolbar.hidden = YES;
}


#pragma mark - Internal Methods

- (void)configureTextViews:(NSDictionary *)params
{
  if ([params objectForKey:kGreeJSInputSingleLineParam]) {
    self.textView.returnKeyType = UIReturnKeyDone;
  }
}

- (void)setupTextLimit:(NSDictionary *)params
{
  NSUInteger limit = [[params valueForKey:@"limit"] unsignedIntegerValue];
  self.limit = limit > 0 ? limit : 500;
}

- (void)createCallbackParams:(NSDictionary *)params
{
  NSMutableDictionary *p = [[params mutableCopy] autorelease];
  [p removeObjectForKey:@"type"];
  [p removeObjectForKey:@"limit"];
  [p removeObjectForKey:@"title"];
  [p removeObjectForKey:@"button"];
  [p removeObjectForKey:@"placeholder"];
  [p removeObjectForKey:@"image"];
  [p removeObjectForKey:@"value"];
  [p removeObjectForKey:@"usePhoto"];
  [p removeObjectForKey:@"photoCount"];
  [p removeObjectForKey:@"callback"];
  self.params = p;
}


#pragma mark Image Picker Methods

- (void)showImagePicker:(UIButton *)sender
{
  [self showImageTypeSelector:NO withTag:sender.tag];
}

- (void)showImagePickerSelected:(UIButton *)sender
{
  [self showImageTypeSelector:YES withTag:sender.tag];
}

- (void)showImageTypeSelector:(BOOL)selected withTag:(NSInteger)tag
{
  if (self.imageTypeSelector)
  {
    return;
  }
    
  self.imageTypeSelector = [[[GreeJSTakePhotoActionSheet alloc] initWithTitle:nil
                                                                     delegate:self
                                                            cancelButtonTitle:nil
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:nil] autorelease];
  self.imageTypeSelector.tag = tag;
  
  BOOL isCameraAvailable = ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]);    
  if (isCameraAvailable) {
    self.imageTypeSelector.takePhotoButtonIndex =
    [self.imageTypeSelector addButtonWithTitle:GreePlatformString(@"GreeJS.WebViewController.TakePhotoButton.Title", @"Take Photo")];
  }
  self.imageTypeSelector.chooseFromAlbumButtonIndex = 
  [self.imageTypeSelector addButtonWithTitle:GreePlatformString(@"GreeJS.WebViewController.ChooseFromAlbumButton.Title", @"Choose From Album")];    
  
  if (selected) {
    self.imageTypeSelector.removePhotoButtonIndex =
    [self.imageTypeSelector addButtonWithTitle:GreePlatformString(@"GreeJS.WebViewController.RemovePhotoButton.Title", @"Remove Photo")];
  }
  self.imageTypeSelector.cancelButtonIndex =
  [self.imageTypeSelector addButtonWithTitle:GreePlatformString(@"GreeJS.WebViewController.CancelButton.Title", @"Cancel")];
  
  self.imageTypeSelector.actionSheetStyle = UIActionSheetStyleBlackOpaque;
  [self.imageTypeSelector showInView:self.view];
}

- (void)setImage:(UIImage *)image atIndex:(NSInteger)index
{
  [self.images replaceObjectAtIndex:index withObject:image];
  [self validateEmpty];
  
  UIButton *customView = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 32, 32)] autorelease];
  [customView setImage:image forState:UIControlStateNormal];
  [customView addTarget:self action:@selector(showImagePickerSelected:) forControlEvents:UIControlEventTouchUpInside];
  customView.layer.cornerRadius = 8.0f;
  customView.tag = index;
  customView.imageView.contentMode = UIViewContentModeScaleAspectFill;
  UIBarButtonItem *buttonItem = [[[UIBarButtonItem alloc] initWithCustomView:customView] autorelease];
  buttonItem.tag = index;
  
  NSMutableArray *items  = [[self.toolbar.items mutableCopy] autorelease];
  [items replaceObjectAtIndex:(index * 2) withObject:buttonItem];
  self.toolbar.items = items;
}

- (void)removeImageAtIndex:(NSInteger)index
{
  [self.images replaceObjectAtIndex:index withObject:[NSNull null]];
  [self validateEmpty];
  
  UIImage *cameraNormalImage = [UIImage greeImageNamed:@"gree_btn_take_photo_default.png"];
  UIImage *cameraHighlightImage = [UIImage greeImageNamed:@"gree_btn_take_photo_highlight.png"];
  UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
  cameraButton.frame = CGRectMake(0, 0, 32.0f, 32.0f);
  [cameraButton addTarget:self action:@selector(showImagePicker:) forControlEvents:UIControlEventTouchUpInside];
  [cameraButton setBackgroundImage:cameraNormalImage forState:UIControlStateNormal];
  [cameraButton setBackgroundImage:cameraHighlightImage forState:UIControlStateHighlighted];

  UIBarButtonItem *buttonItem = [[[UIBarButtonItem alloc] initWithCustomView:cameraButton] autorelease];
  buttonItem.tag = index;
  
  NSMutableArray *items  = [[self.toolbar.items mutableCopy] autorelease];
  [items replaceObjectAtIndex:(index * 2) withObject:buttonItem];
  self.toolbar.items = items;
}


#pragma mark UITextView Placeholder Methods

- (void)setPlaceholder:(NSString *)placeholder color:(UIColor *)color
{
  self.placeholderLabel = [[[UILabel alloc] initWithFrame:CGRectMake(8.0, 0.0, self.textView.frame.size.width - 20.0, 34.0)] autorelease];
  [self.placeholderLabel setText:placeholder];
  [self.placeholderLabel setBackgroundColor:[UIColor clearColor]];
  [self.placeholderLabel setFont:[self.textView font]];
  [self.placeholderLabel setTextColor:color];
  
  [self.textView addSubview:self.placeholderLabel];
}

- (void)showPlaceholder
{
  [self.placeholderLabel setHidden:YES];
}

- (void)hidePlaceholder
{
  [self.placeholderLabel setHidden:NO]; 
}

#pragma mark Validation

- (void)setupValidation:(NSDictionary*)params
{
  self.atLeastOneRequiredFields = [self parseAtLeastOneRequiredFieldsForParams:params];
  
  NSArray *fields = [NSArray arrayWithObjects:@"title", @"text", @"photo", nil];
  NSMutableArray *requiredFields = [NSMutableArray arrayWithCapacity:fields.count];
  for (NSString *field in fields) {
    if ([self isFieldRequired:field forParams:params]) {
      [requiredFields addObject:field];
    }
  }
  self.requiredFields = requiredFields;
}

- (NSArray*)parseAtLeastOneRequiredFieldsForParams:(NSDictionary*)params
{
  NSString *fieldsString = [params objectForKey:@"required"];
  NSArray *unstrippedFields = [fieldsString componentsSeparatedByString:@","];
  NSMutableArray *fields = [NSMutableArray arrayWithCapacity:unstrippedFields.count];
  
  for (NSString *field in unstrippedFields) {
    [fields addObject:[field stringByReplacingOccurrencesOfString:@" " withString:@""]];
  }
  
  return fields;
}

- (BOOL)isFieldRequired:(NSString*)fieldName forParams:(NSDictionary*)params
{
  return [[params objectForKey:[NSString stringWithFormat:@"%@Required", fieldName]] boolValue];
}

- (BOOL)validateField:(NSString*)fieldName
{
  NSString *selectorName = [NSString stringWithFormat:@"validate%@Field", [fieldName capitalizedString]];
  SEL selector = NSSelectorFromString(selectorName);
  if ([self respondsToSelector:selector]) {
    return (BOOL)[self performSelector:selector];
  } else {
    GreeLog(@"%@ did not declare a validation method for %@ field; assuming field is valid.", [self class], fieldName);
    return YES;
  }
}

- (BOOL)validateTextField
{
  if (self.textView.text.length <= 0) {
    return NO;
  }
  return YES;
}

- (BOOL)validatePhotoField
{
  for (UIImage *image in self.images) {
    if (image && ![image isEqual:[NSNull null]]) {
      return YES;
    }
  }
  return NO;
}


@end
