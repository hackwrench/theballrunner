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

#import "GreeMenuNavController.h"
#import "UIImage+GreeAdditions.h"
#import "GreePlatform+Internal.h"

#import <CoreGraphics/CGColor.h>
#import <QuartzCore/CALayer.h>
#import <UIKit/UIPanGestureRecognizer.h>
#import <math.h>

#define OPEN_MENU_OFFSET 270
#define OPEN_MENU_ANIMATION_DURATION 0.23
#define OPEN_MENU_SHADOW_OFFSET_X -3
#define OPEN_MENU_SHADOW_OFFSET_Y 0
#define OPEN_MENU_SHADOW_OPACITY 0.6f

NSString* const GreeDashboardWillShowUniversalMenuNotification = @"GreeDashboardWillShowUniversalMenuNotification";
NSString* const GreeDashboardDidShowUniversalMenuNotification = @"GreeDashboardDidShowUniversalMenuNotification";
NSString* const GreeDashboardWillHideUniversalMenuNotification = @"GreeDashboardWillHideUniversalMenuNotification";
NSString* const GreeDashboardDidHideUniversalMenuNotification = @"GreeDashboardDidHideUniversalMenuNotification";

@interface GreeMenuNavController ()
@property (nonatomic, retain)UIPanGestureRecognizer *panGesture;
@property (nonatomic, retain)UITapGestureRecognizer *singleTapGesture;
- (void)updateMenuViewAnimated:(BOOL)animated notifyDelegate:(BOOL)notify;
- (void)insertRevealButton:(UINavigationItem*)item;
- (void)revealButtonPushed;
@end

@implementation GreeMenuNavController

#pragma mark - Object Lifecycle
@synthesize rootViewController = _rootViewController;
@synthesize menuViewController = _menuViewController;
@synthesize revealButton = _revealButton;
@synthesize delegate = _delegate;
@synthesize isRevealed = _isRevealed;
@synthesize panGesture = _panGesture;
@synthesize singleTapGesture = _singleTapGesture;
@synthesize allowPanGesture = _allowPanGesture;
@synthesize allowSingleTapGesture = _allowSingleTapGesture;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
{
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    _isRevealed = NO;
    _revealButton = nil;
    _rootViewController = nil;
    _menuViewController = nil;
    _delegate = nil;
    _panGesture = nil;
    _allowPanGesture = YES;
    _allowSingleTapGesture = YES;
  }
  
  return self;
}

- (id)initWithRootViewController:(UINavigationController*)rootViewController leftViewController:(UINavigationController*)leftViewController
{
  if ((self = [self initWithNibName:nil bundle:nil])) {
    _rootViewController = [rootViewController retain];
    _menuViewController = [leftViewController retain];
  }
  
  return self;
}

- (void)dealloc
{
  [_rootViewController release];
  [_menuViewController release];
  [_revealButton release];
  [_panGesture release];
  [_singleTapGesture release];
  _delegate = nil;
  [super dealloc];
}

- (void)loadView
{
  [super loadView];
  [_rootViewController loadView];
  [_menuViewController loadView];
  
  UIImage *buttonImageDefault = [UIImage greeImageNamed:@"gree_btn_um_default.png"];
  UIImage *buttonImageHighlighted = [UIImage greeImageNamed:@"gree_btn_um_highlight.png"];
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.exclusiveTouch = YES;
  button.frame = CGRectMake(0, 0, buttonImageDefault.size.width, buttonImageDefault.size.height);
  [button setBackgroundImage:buttonImageDefault forState:UIControlStateNormal];
  [button setBackgroundImage:buttonImageHighlighted forState:UIControlStateHighlighted];
  [button addTarget:self action:@selector(revealButtonPushed) forControlEvents:UIControlEventTouchUpInside];
  _revealButton = [[UIBarButtonItem alloc] initWithCustomView:button];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [_rootViewController viewDidLoad];
  [_menuViewController viewDidLoad];
  
  assert(_rootViewController && _menuViewController);
  [self.view addSubview:_rootViewController.view];
  _rootViewController.view.frame = self.view.bounds;

  [self.view insertSubview:_menuViewController.view belowSubview:_rootViewController.view];
  _menuViewController.view.frame = CGRectMake(0, 0, OPEN_MENU_OFFSET, self.view.bounds.size.height);
  
  self.view.autoresizesSubviews = YES;
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _rootViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _menuViewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
  
  CALayer* rootLayer = _rootViewController.view.layer;
  rootLayer.shadowOffset = CGSizeMake(OPEN_MENU_SHADOW_OFFSET_X, OPEN_MENU_SHADOW_OFFSET_Y);
  rootLayer.shadowOpacity = OPEN_MENU_SHADOW_OPACITY;
  rootLayer.shadowPath = [UIBezierPath bezierPathWithRect:_rootViewController.view.bounds].CGPath;
  
  _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGesture:)];
  _panGesture.delegate = self;
  _panGesture.enabled = _allowPanGesture;
  [_rootViewController.view addGestureRecognizer:_panGesture];
  
  _singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTapGesture:)];
  _singleTapGesture.delegate = self;
  _singleTapGesture.enabled = _allowSingleTapGesture;
  _singleTapGesture.numberOfTapsRequired = 1;
  _singleTapGesture.numberOfTouchesRequired = 1;
  [_rootViewController.topViewController.view addGestureRecognizer:_singleTapGesture];
  
  self.view.backgroundColor = [UIColor darkGrayColor];
  [self.view setNeedsLayout];
}

#pragma mark - Public Interface

#pragma mark - UIViewController Overrides

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p>", NSStringFromClass([self class]), self];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [_rootViewController viewWillAppear:animated];
  [_menuViewController viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [_rootViewController viewDidAppear:animated];
  [_menuViewController viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [_rootViewController viewWillDisappear:animated];
  [_menuViewController viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [_rootViewController viewDidDisappear:animated];
  [_menuViewController viewDidDisappear:animated];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [_rootViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [_menuViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  [_rootViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  [_menuViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [_rootViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [_menuViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  [_rootViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
  [_menuViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];

  return [GreePlatform sharedInstance].interfaceOrientation == toInterfaceOrientation;
}

#pragma mark - Internal Methods

- (void)insertRevealButton:(UINavigationItem*)item
{
  if ([UINavigationBar respondsToSelector:@selector(appearance)]) {
    NSArray *items = item.leftBarButtonItems;
    if (![items containsObject:_revealButton]) {
      if (!items.count > 0) {
        NSMutableArray *buttonArray = [NSMutableArray arrayWithObject:_revealButton];
        [buttonArray addObjectsFromArray:items];
        [item setLeftBarButtonItems:buttonArray animated:NO];
      }
    }
    item.leftItemsSupplementBackButton = NO;
  } else {
    UIBarButtonItem *leftButtonItem = item.leftBarButtonItem;
    if (nil == leftButtonItem ){
      item.leftBarButtonItem = _revealButton;
    } else if (leftButtonItem != _revealButton) {
      if (leftButtonItem.customView != nil) {
        UIView *backButton = leftButtonItem.customView;
        UIImage *buttonImageDefault = [UIImage greeImageNamed:@"gree_btn_um_default.png"];
        UIImage *buttonImageHighlighted = [UIImage greeImageNamed:@"gree_btn_um_highlight.png"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect revealButtonFrame = CGRectMake(0, 0, buttonImageDefault.size.width, buttonImageDefault.size.height);
        button.frame = revealButtonFrame;
        [button setBackgroundImage:buttonImageDefault forState:UIControlStateNormal];
        [button setBackgroundImage:buttonImageHighlighted forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(revealButtonPushed) forControlEvents:UIControlEventTouchUpInside];
        
        CGRect backButtonBounds = backButton.bounds;
        UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, revealButtonFrame.size.width + backButtonBounds.size.width, revealButtonFrame.size.height)];
        [customView addSubview:button];
        [customView addSubview:backButton];
        backButton.frame = CGRectMake(revealButtonFrame.size.width, 0, backButtonBounds.size.width, backButtonBounds.size.height);
        item.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:[customView autorelease]] autorelease];
      }
    }
  }
}

- (void)updateMenuViewAnimated:(BOOL)animated notifyDelegate:(BOOL)notify
{
  __block UIView *slidingView = _rootViewController.view;
  __block GreeMenuNavController *myself = self;
  __block CGAffineTransform slidingViewTransform = CGAffineTransformIdentity;
  __block SEL delegateSelector = nil;
  __block NSString *notificationName = nil;
  
  void (^transformationBlock)(void) = ^{
    slidingView.transform = slidingViewTransform;
  };
  
  void (^completionBlock)(BOOL) = ^(BOOL finished){
    if (myself.delegate && [myself.delegate respondsToSelector:delegateSelector]) {
      [myself.delegate performSelector:delegateSelector withObject:myself withObject:myself.menuViewController];
    }
    
    [[NSNotificationCenter defaultCenter]
      postNotificationName:notificationName
      object:myself.rootViewController];
  };
  
  if (_isRevealed) {
    if (notify && _delegate && [_delegate respondsToSelector:@selector(menuController:willShowViewController:)]) {
      [_delegate menuController:self willShowViewController:_menuViewController];
      [[NSNotificationCenter defaultCenter]
        postNotificationName:GreeDashboardWillShowUniversalMenuNotification
        object:_rootViewController];
    }
    [_menuViewController.view setHidden:NO];
    slidingViewTransform = CGAffineTransformMakeTranslation(OPEN_MENU_OFFSET, 0);
    delegateSelector = @selector(menuController:didShowViewController:);
    notificationName = GreeDashboardDidShowUniversalMenuNotification;
  } else {
    if (notify && _delegate && [_delegate respondsToSelector:@selector(menuController:willHideViewController:)]) {
      [_delegate menuController:self willHideViewController:_menuViewController];
      [[NSNotificationCenter defaultCenter]
        postNotificationName:GreeDashboardWillHideUniversalMenuNotification
        object:_rootViewController];
    }
    slidingViewTransform = CGAffineTransformIdentity;
    delegateSelector = @selector(menuController:didHideViewController:);
    notificationName = GreeDashboardDidHideUniversalMenuNotification;
  }
  
  if (animated) {
    [UIView animateWithDuration:OPEN_MENU_ANIMATION_DURATION
                     animations:transformationBlock
                     completion:notify?completionBlock:nil];
  } else {
    transformationBlock();
    if (notify) completionBlock(YES);
  }
}

- (void)revealButtonPushed
{
  [self setIsRevealed:!_isRevealed];
}

- (void)setIsRevealed:(BOOL)isRevealed
{
  if (_isRevealed == isRevealed) return;
  
  _isRevealed = isRevealed;
  [self updateMenuViewAnimated:YES notifyDelegate:YES];
}

#pragma mark - UINavigationBar Delegate Methods

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPushItem:(UINavigationItem *)item
{
  if (_rootViewController.navigationBar == navigationBar) [self insertRevealButton:item];
  return YES;
}

#pragma mark - UINavigationController Delegate Methods

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  if (_rootViewController == navigationController && navigationController.viewControllers.count <= 1) {
    [self insertRevealButton:viewController.navigationItem];
  }
}

#pragma mark - UIGestureRecognizer methods

- (void)setAllowPanGesture:(BOOL)allowPanGesture
{
  _allowPanGesture = allowPanGesture;
  _panGesture.enabled = _allowPanGesture;
}

- (void)setAllowSingleTapGesture:(BOOL)allowSingleTapGesture
{
  _allowSingleTapGesture = allowSingleTapGesture;
  _singleTapGesture.enabled = _allowSingleTapGesture;
}

- (void)onPanGesture:(UIPanGestureRecognizer*)gesture
{
  if (!_isRevealed) {
    return;
  }
  
  CGPoint translation = [gesture translationInView:self.view];
  
  CGFloat offset = translation.x + (_isRevealed?OPEN_MENU_OFFSET:0);
  // If we go to the edge only translate by a fraction of the amount past the edge
  if (offset > OPEN_MENU_OFFSET) offset = OPEN_MENU_OFFSET + pow(log2(offset - OPEN_MENU_OFFSET), 2);
  // Should not translate past the origin
  if (offset < 0) offset = 0;
  
  switch (gesture.state) {
    case UIGestureRecognizerStateBegan:
    case UIGestureRecognizerStateChanged: {
        _rootViewController.view.transform = CGAffineTransformMakeTranslation(offset, 0);
      }
      break;
    case UIGestureRecognizerStateCancelled:
    case UIGestureRecognizerStateFailed:
    case UIGestureRecognizerStateEnded: {
      CGPoint velocity = [gesture velocityInView:self.view];
      BOOL shouldBeRevealed = ((offset + velocity.x) > (OPEN_MENU_OFFSET / 2))?YES:NO;
      if (shouldBeRevealed != _isRevealed)
        [self setIsRevealed:shouldBeRevealed];
      else
        [self updateMenuViewAnimated:YES notifyDelegate:NO];
      }
    case UIGestureRecognizerStatePossible:
    default:
      break;
  }
}

- (void)onSingleTapGesture:(UITapGestureRecognizer*)gesture
{
  if (!_isRevealed) {
    return;
  }
  [self setIsRevealed:NO];  
}

#pragma mark - UIGestureRecognizer Delegate Methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
  if(_isRevealed) {
    return YES;
  }
  else {
    return NO;
  }
}

@end
