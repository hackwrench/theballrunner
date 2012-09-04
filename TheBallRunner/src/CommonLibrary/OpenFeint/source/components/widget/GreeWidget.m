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

#import "GreePlatform.h"
#import "GreePlatform+Internal.h"
#import "GreeWidget+Internal.h"
#import "GreeWidgetItem.h"
#import "UIImage+GreeAdditions.h"
#import "GreeBadgeValues.h"
#import "GreePopup.h"
#import "GreeLogger.h"
#import <QuartzCore/QuartzCore.h>
#import "GreeWidgetControlItem.h"
#import "GreeSettings.h"
#import "UIViewController+GreePlatform.h"

#define RGBA(r,g,b,a) ((r)/255.0f),((g)/255.0f),((b)/255.0f),(a)

static const CGFloat GreeWidgetBarItemFirstItemMarginLeft = 0;
static const CGFloat GreeWidgetBarItemLastItemMarginRight = 5;
static const CGFloat GreeWidgetBarItemSpace = 10; //distance between two neighboring items
static CGFloat COLLAPSED_WIDTH;

static NSString* NSStringFromGreeWidgetPosition(GreeWidgetPosition position)
{
  switch (position) {
    case GreeWidgetPositionTopLeft:
      return @"GreeWidgetPositionTopLeft";
    case GreeWidgetPositionBottomLeft:
      return @"GreeWidgetPositionBottomLeft";
    case GreeWidgetPositionMiddleLeft:
      return @"GreeWidgetPositionMiddleLeft";
    case GreeWidgetPositionTopRight:
      return @"GreeWidgetPositionTopRight";
    case GreeWidgetPositionBottomRight:
      return @"GreeWidgetPositionBottomRight";
    case GreeWidgetPositionMiddleRight:
      return @"GreeWidgetPositionMiddleRight";      
    default:
      return @"Invalid Position";
  }
}


@interface GreeWidget() 
@property (nonatomic, retain, readwrite) NSMutableArray* items;
@property (nonatomic, retain) id notificationHandler;

- (CGFloat)barBoundsWidth:(BOOL)collapsed;
- (CGRect)barBounds:(BOOL)collapsed;
- (void)updateScreenshotButtonVisibility;
- (void)loadBarItems;
- (CGFloat)screenBoundsHeight;
- (CGFloat)screenBoundsWidth;
- (int)totalBadgeCount;

@end

@implementation GreeWidget
@synthesize items = _items;
@synthesize position = _position;

@synthesize dashboardItem = _dashboardItem;
@synthesize userMessageItem = _userMessageItem;
@synthesize gameMessageItem = _gameMessageItem;
@synthesize screenshotItem = _screenshotItem;
@synthesize controlItem =  _controlItem;

@synthesize isCollapsed =  _isCollapsed;
@synthesize expandable =  _expandable;

@synthesize notificationHandler = _notificationHandler;
@synthesize dataSource = _dataSource;
@synthesize hostViewController = _hostViewController;

#pragma mark - Object Lifecycle

- (id)initWithPosition:(GreeWidgetPosition)position expandable:(BOOL)expandable {
  self = [super initWithFrame:[self barBounds:NO]];
  if (self != nil) {
    _position = position;
    _expandable = expandable;
        
    __block GreeWidget *thisWidget = self;
    _notificationHandler = [[NSNotificationCenter defaultCenter]
      addObserverForName:GreeBadgeValuesDidUpdateNotification
      object:nil queue:[NSOperationQueue mainQueue]
      usingBlock:^(NSNotification* notification) {
        GreeBadgeValues* values = (GreeBadgeValues*)notification.object;
        [thisWidget updateBadgesWithValue:values];
    }];
    [_notificationHandler retain];
    
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = YES;    
  }
  
  return self;
}

- (id)initWithSettings:(GreeSettings*)settings
{
  //default position is bottom left
  GreeWidgetPosition position = GreeWidgetPositionBottomLeft;
  if ([settings settingHasValue:GreeSettingWidgetPosition]) {
    position = (GreeWidgetPosition)[settings integerValueForSetting:GreeSettingWidgetPosition];
  }
  //default is not expandable
  BOOL expandable = NO;
  if ([settings settingHasValue:GreeSettingWidgetExpandable]) {
    expandable = [settings boolValueForSetting:GreeSettingWidgetExpandable];
  }

  return [self initWithPosition:position expandable:expandable];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:_notificationHandler];
  [_notificationHandler release];
  
  _dataSource = nil;
  [_dashboardItem release];
  [_userMessageItem release];
  [_gameMessageItem release];
  [_screenshotItem release];
  _controlItem.delegate = nil;
  [_controlItem release];
  [super dealloc];
}

#pragma mark - UIView Overrides
- (void)drawRect:(CGRect)rect
{
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSaveGState(context);
  CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
  CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
  float strokeColorComponents[] = {1,0,0,1};
  
  CGContextSetStrokeColorSpace(context, space);
  CGContextSetStrokeColor(context, strokeColorComponents);
  CGContextMoveToPoint(context,CGRectGetMinX(rect), CGRectGetMaxY( rect ));
  CGContextAddLineToPoint( context, CGRectGetMinX( rect ), CGRectGetMinY( rect ) );
  CGContextAddLineToPoint( context, CGRectGetMaxX( rect ), CGRectGetMinY( rect ) );
  CGContextAddLineToPoint( context, CGRectGetMaxX( rect ), CGRectGetMaxY( rect ));
  CGContextClip(context);
  
  
  CGFloat gradientColorComponents[] = {
    RGBA(110, 110, 110, 0.7f),
    RGBA(67, 67, 67, 0.8f)
  };
  
  CGPoint startPoint = rect.origin;
  CGPoint endPoint = startPoint;
  endPoint.y += rect.size.height;
  CGGradientRef gradient = CGGradientCreateWithColorComponents( space, gradientColorComponents, NULL, (sizeof(gradientColorComponents) / (sizeof(CGFloat) * 4)));
  CGContextDrawLinearGradient(context, gradient,
                              startPoint, endPoint,0);
  
  
  CGGradientRelease(gradient);
  CGColorSpaceRelease(space);
  CGContextRestoreGState(context);
}

#pragma mark layout widget items
- (void)reverseLayout
{
  CGFloat barWidth = self.bounds.size.width;
  CGFloat offsetX = barWidth - GreeWidgetBarItemFirstItemMarginLeft;
  
  //tempItems is to create a temporary array of items in the order of dashboard item, game item, user item, and camera item
  //so that even if widget's position is on right, game item stays on the left of user item, so that game item and user item's
  //layout will always be the same with pop up notification board's tabs "game" and "sns"
  NSMutableArray* tempItems = [NSMutableArray arrayWithArray:self.items];
  int userItemIndex = [tempItems indexOfObject:self.userMessageItem];
  int gameItemIndex = [tempItems indexOfObject:self.gameMessageItem];
  [tempItems exchangeObjectAtIndex:userItemIndex withObjectAtIndex:gameItemIndex];
  
  for (int index=0; index < tempItems.count; index++) {
    UIButton<GreeWidgetDataSourceOfItem>* item = [tempItems objectAtIndex:index];
    CGFloat itemWidth = [item widthNeeded];
    CGFloat itemHeight = GreeWidgetBarDimentionHeight;
    
    if (index == 0) { //first item on right
      offsetX -= [item widthNeeded];
      item.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    }else if (index == tempItems.count -1) { //last item on left
      offsetX = GreeWidgetBarItemLastItemMarginRight;
      item.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    }else {
      offsetX -= ([item widthNeeded] + GreeWidgetBarItemSpace);
      item.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    }    
    item.frame = CGRectMake(offsetX, 0, itemWidth, itemHeight);
  }
}

- (void)inorderLayout
{
  float offsetX = GreeWidgetBarItemFirstItemMarginLeft;
  for (int index=0; index < self.items.count; index++) {
    UIButton<GreeWidgetDataSourceOfItem>* item = [self.items objectAtIndex:index];
    CGFloat itemWidth = [item widthNeeded];
    CGFloat itemHeight = GreeWidgetBarDimentionHeight;
    
    CGRect rect;
    if (index < self.items.count - 1) {//not the last item
      item.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
      rect = CGRectMake(offsetX, 0, itemWidth, itemHeight);
    } else {//last item on the bar
      item.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
      rect = CGRectMake(self.bounds.size.width - itemWidth - GreeWidgetBarItemLastItemMarginRight, 0, itemWidth, itemHeight);
    }
    item.frame = rect;
    offsetX += ([item widthNeeded] + GreeWidgetBarItemSpace);
  }
}

- (void)layoutSubviews
{
  if (!GreeWidgetPositionIsOnRight(self.position)) {
    [self inorderLayout];
  }else{
    [self reverseLayout];
  }
}

- (void)didMoveToSuperview {
  if (self.superview) {
    [self refreshBadgeCount];
    [self relocateBar];
  }
}

#pragma mark - Internal Methods
#pragma mark bounds and transform computing
- (CGFloat)barBoundsWidth:(BOOL)collapsed
{  
  CGFloat barWidth;
  if (collapsed) {
    barWidth = COLLAPSED_WIDTH; 
  } else {
    barWidth = [self screenBoundsWidth];
  }
  return barWidth;
}

- (CGRect)barBounds:(BOOL)collapsed
{
  return CGRectMake(0, 0, [self barBoundsWidth:collapsed], GreeWidgetBarDimentionHeight);
}

- (CGPoint)barCenter
{
  CGFloat x = 0, y = 0;
  
  if (GreeWidgetPositionIsOnLeft(self.position)) {
    x = [self barBoundsWidth:self.isCollapsed]/2.;
    self.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
  }else{
    x = [self screenBoundsWidth] - [self barBoundsWidth:self.isCollapsed]/2.;
    self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
  }
  
  if (GreeWidgetPositionIsOnTop(self.position)) {
    y = GreeWidgetBarDimentionHeight/2.;
    
    if (self.isCollapsed) {
      self.autoresizingMask = self.autoresizingMask | UIViewAutoresizingFlexibleBottomMargin;
    } else {
      self.autoresizingMask = self.autoresizingMask | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    }
  }else if(GreeWidgetPositionIsOnMiddle(self.position)){
    y = [self screenBoundsHeight]/2.;
    
    if (self.isCollapsed) {
      self.autoresizingMask = self.autoresizingMask | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
    } else {
      self.autoresizingMask = self.autoresizingMask | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    }
    
  }else{
    y = [self screenBoundsHeight] - GreeWidgetBarDimentionHeight/2.;
    
    if (self.isCollapsed) {
      self.autoresizingMask = self.autoresizingMask | UIViewAutoresizingFlexibleTopMargin;
    } else {
      self.autoresizingMask = self.autoresizingMask | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    }
  }
  
  return CGPointMake(x, y);
}

- (CGFloat)screenBoundsWidth
{
  return self.superview.bounds.size.width;
}

- (CGFloat)screenBoundsHeight
{
  return self.superview.bounds.size.height;
}

- (CGAffineTransform)transformForCurrentOrientation
{
  CGAffineTransform rotateTrans = CGAffineTransformRotate(CGAffineTransformIdentity, 0);   
  CGPoint destinationCenter = [self barCenter];
  CGFloat tx = destinationCenter.x - self.center.x;
  CGFloat ty = destinationCenter.y - self.center.y;
  return CGAffineTransformMake(rotateTrans.a, rotateTrans.b, rotateTrans.c, rotateTrans.d, tx, ty);
}

#pragma mark badge number update
- (BOOL)hasNotifications
{
  return [self totalBadgeCount] > 0 ? YES : NO;
}

- (int)totalBadgeCount
{
  int count = 0;
  for (GreeWidgetItem* item in self.items) {
    //control item does not have badge count
    if ([item isKindOfClass:[GreeWidgetItem class]]) {
      count += [item badgeCount];
    }
  }
  return count;
}

- (NSString*)titleForTotalBadge
{
  NSString* title = [NSString stringWithFormat:@"%d", [self totalBadgeCount]];
  if ([self totalBadgeCount] > GreeWidgetBadgeDefaultMaxCount) {
    title = [NSString stringWithFormat:@"%d+", GreeWidgetBadgeDefaultMaxCount];
  }
  return title;
}

- (void)updateBadgesWithValue:(GreeBadgeValues*)badgeValues
{
  [_userMessageItem setBadgeCount:badgeValues.socialNetworkingServiceBadgeCount];
  [_gameMessageItem setBadgeCount:badgeValues.applicationBadgeCount];
  [self.controlItem updateNotificationLabel];
}

- (id)refreshBadgeCount
{
  [[GreePlatform sharedInstance] updateBadgeValuesWithBlock:nil];
  return self;
}

#pragma mark items set up
- (void)setItems:(NSMutableArray*)items
{
  for (UIButton* item in _items) {
    [item removeFromSuperview];
  }
  [_items release];
  
  _items = [items retain];
  for (UIButton* item in _items) {
    [self addSubview:item];
  }
  
  [self setNeedsLayout];
}

- (void)createControlItem
{
  GreeWidgetControlItem* controlItem = [GreeWidgetControlItem 
                                        itemWithLeftImage:[UIImage greeImageNamed:@"gree_btn_left_arrow_default.png"] 
                                        rightImage:[UIImage greeImageNamed:@"gree_btn_right_arrow_default.png"] 
                                        leftNotificationImage:[UIImage greeImageNamed:@"gree_btn_notifications_bubble_default.png"] 
                                        rightNotificationImage:[UIImage greeImageNamed:@"gree_btn_notifications_bubble_default.png"]  
                                        delegate:self];
  self.controlItem = controlItem;
  [self.controlItem updatePosition:self.position];
}

- (void)loadBarItems
{
  __block UIViewController *hostViewController = self.hostViewController;

  self.dashboardItem = [GreeWidgetItem
    itemWithImage:[UIImage greeImageNamed:@"gree_btn_dashboard_default.png"]
    callbackBlock:^{
      [hostViewController presentGreeDashboardWithParameters:nil animated:YES];
  }],
  self.userMessageItem = [GreeWidgetItem 
    itemWithImage:[UIImage greeImageNamed:@"gree_btn_user_message_default.png"]
    activeImage:[UIImage greeImageNamed:@"gree_btn_user_message_active_default.png"]
    callbackBlock:^{      
      [hostViewController presentGreeNotificationBoardWithType:GreeNotificationBoardTypeSNS animated:YES];
  }];
  self.gameMessageItem = [GreeWidgetItem 
    itemWithImage:[UIImage greeImageNamed:@"gree_btn_game_message_default.png"]
    activeImage:[UIImage greeImageNamed:@"gree_btn_game_message_active_default.png"]
    callbackBlock:^{
      [hostViewController presentGreeNotificationBoardWithType:GreeNotificationBoardTypeGame animated:YES];
  }];
  
  __block GreeWidget* mySelf = self;
  self.screenshotItem = [GreeWidgetItem
    itemWithImage:[UIImage greeImageNamed:@"gree_btn_camera_default.png"]
    callbackBlock:^{
      __block GreePopup* popup = [GreeSharePopup popup];
      
      if (mySelf.dataSource && [mySelf.dataSource respondsToSelector:@selector(screenshotImageForWidget:)]) {
        ((GreeSharePopup*)popup).attachingImage = [mySelf.dataSource screenshotImageForWidget:mySelf];
      }
      
      [hostViewController showGreePopup:popup];
    }];
  
  self.dashboardItem.showsTouchWhenHighlighted = YES;
  [self updateScreenshotButtonVisibility];
  
  NSMutableArray* items = [NSMutableArray arrayWithObjects:
                           _dashboardItem,
                           _gameMessageItem,
                           _userMessageItem,
                           _screenshotItem,
                           nil
                           ];
  if (self.expandable) {    
    [self createControlItem];
    [items addObject:self.controlItem];
  }
  self.items = items;
}

#pragma mark expand and collapse bar
static CGFloat COLLAPSED_WIDTH  = 66.0;
- (void)expand
{
  self.isCollapsed = NO;

  __block GreeWidget* mySelf = self;
  [UIView 
   animateWithDuration:0.4 
   animations:^{
     [mySelf relocateBar];
     for (int index = 1; index < mySelf.items.count - 1; index++) {
       [[mySelf.items objectAtIndex:index] setAlpha:1];
     }
   }
   completion:nil];
}

- (void)collapse
{
  self.isCollapsed = YES;

  __block GreeWidget* mySelf = self;
  [UIView 
   animateWithDuration:0.4 
   animations:^{
     [mySelf relocateBar];
     for (int index = 1; index < mySelf.items.count - 1; index++) { 
       [[mySelf.items objectAtIndex:index] setAlpha:0];
     }
   }
   completion:nil];
}

- (void)updateScreenshotButtonVisibility
{
  if (self.dataSource && [self.dataSource respondsToSelector:@selector(screenshotImageForWidget:)]) {
     _screenshotItem.hidden = NO;
  }else{
    _screenshotItem.hidden = YES;    
  }
}

- (void)relocateBar
{
  self.bounds = [self barBounds:self.isCollapsed];
  self.transform = [self transformForCurrentOrientation];
  [self setNeedsLayout];
}

- (void)setHostViewController:(UIViewController *)hostViewController
{
  if (_hostViewController == hostViewController) {
    return;
  }
  _hostViewController = hostViewController;
  //widget items cannot be loaded until hostViewController is set up.
  [self loadBarItems];
}

#pragma mark - Public Interface
- (void)setDataSource:(id<GreeWidgetDataSource>)dataSource
{
  _dataSource = dataSource;
  [self updateScreenshotButtonVisibility];
}

- (void)updateWiget
{
  //non-expandable widget only supports two positions: bottom left and top left
  //if developer pass in a invalid position for non-expandable widget,
  //then we will change position to top left if developer set position to top right,
  //and change position to bottom left if developer set position to middle left, middle right or bottom right
  if (!self.expandable && self.position != GreeWidgetPositionTopLeft && self.position != GreeWidgetPositionBottomLeft) {
    GreeWidgetPosition validPosition;
    if (GreeWidgetPositionIsOnTop(self.position)) {
      validPosition = GreeWidgetPositionTopLeft;
    }else {
      validPosition = GreeWidgetPositionBottomLeft;
    }
    //Do NOT use setter, otherwise it will cause a circle
    _position = validPosition;
  }
  [self.controlItem updatePosition:self.position];
  [self relocateBar];
}

- (void)setPosition:(GreeWidgetPosition)position
{
  if (_position == position) {
    return;
  }  
  _position = position;
  [self updateWiget];
}

- (void)setExpandable:(BOOL)expandable
{
  if ((_expandable && expandable) || (!_expandable && !expandable)) {
    return;
  }
  _expandable = expandable;
  
  //clean up status and view if widget is collapsed currently
  if (self.isCollapsed) {
    for (int index = 1; index < self.items.count - 1; index++) {
      [[self.items objectAtIndex:index] setAlpha:1];
    }
    self.isCollapsed = NO;
    self.controlItem.collapsed = NO;
  }

  if (_expandable) {
    if (self.controlItem == nil) {
      [self createControlItem];
    }
    [self.items addObject:self.controlItem];
    [self addSubview:self.controlItem];
  }else {
    [self.items removeObjectIdenticalTo:self.controlItem];
    [self.controlItem removeFromSuperview];
  }
  [self updateWiget];
}

- (NSString*)description
{
  return [NSString stringWithFormat:@"<%@:%p, position:%@, visible:%@, expandable:%@>",
          NSStringFromClass([self class]), 
          self,
          NSStringFromGreeWidgetPosition(self.position),
          self.superview ? @"YES":@"NO",
          self.expandable ? @"YES":@"NO"];
}

@end
