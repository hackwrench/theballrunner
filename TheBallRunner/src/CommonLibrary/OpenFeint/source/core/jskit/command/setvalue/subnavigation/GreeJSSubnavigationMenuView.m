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


#import "GreeJSSubnavigationMenuView.h"
#import "GreeJSSubnavigationIconView.h"
#import "GreeJSSubnavigationIconPersistentCache.h"
#import "UIImage+GreeAdditions.h"
#import "AFNetworking.h"
#import "GreePlatform+Internal.h"
#import "GreeSettings.h"

static NSString* const kButtonNameKey         = @"name";
static NSString* const kButtonIconNormalKey   = @"iconNormal";
static NSString* const kButtonIconSelectedKey = @"iconHighlighted";

@interface GreeJSSubnavigationMenuView ()
+ (NSString*)nibNameByItem:(NSDictionary*)item highlighted:(BOOL)highlight;
- (void)resetIcons;
@end

@implementation GreeJSSubnavigationMenuView
@synthesize delegate    = _delegate;
@synthesize icons = _icons;

#pragma mark -
#pragma mark Object Lifecycle

/** Designated initializer. */
- (id)init
{
  self = [super init];
  if (self) {
    
    self.autoresizingMask =
    UIViewAutoresizingFlexibleHeight | 
    UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleBottomMargin;
    
    // Instantiate UIScrollView.
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.scrollEnabled = YES;
    scrollView.scrollsToTop = NO;
    scrollView.autoresizingMask = self.autoresizingMask;
    scrollView.showsVerticalScrollIndicator = YES;
    scrollView.alwaysBounceHorizontal = YES;
    scrollView.delegate = self;
    scrollView.backgroundColor = [UIColor clearColor];
    // Add and release scroll view.
    [self addSubview:scrollView];
    _scrollView = scrollView;
    
    _queue = [[NSOperationQueue alloc] init];
    _queue.maxConcurrentOperationCount = 2;
    [_queue setSuspended:NO];
    
    // Instantiate icons.
    _icons = [[NSMutableArray array] retain];
  }
  return self;
}

- (void)dealloc {
  [_icons release], _icons = nil;
  [_scrollView release], _scrollView = nil;
  [_queue release], _queue = nil;
  [super dealloc];
}

#pragma mark -
#pragma mark - Internal Methods

- (void)resetIcons
{
  for (UIView* icon in _icons) {
    [icon removeFromSuperview];
  }
  [_icons removeAllObjects];
}

+ (NSString*)nibNameByItem:(NSDictionary*)item highlighted:(BOOL)highlight;
{
  static NSDictionary *iconImages = nil;
  if (iconImages == nil) {
    GreeSettings *settings = [GreePlatform sharedInstance].settings;
    NSString *path = @"/img/subnavi/";
    NSString *port = [settings objectValueForSetting:GreeSettingServerPortSns];
    NSString *app = [[settings objectValueForSetting:GreeSettingServerUrlApps] stringByAppendingString:path];
    NSString *game = [[settings objectValueForSetting:GreeSettingServerUrlGames] stringByAppendingString:path];
    NSString *sns = [settings objectValueForSetting:GreeSettingServerUrlSns];
    if (port)
      sns = [sns stringByAppendingString:[NSString stringWithFormat:@":%@", port]];
    sns = [sns stringByAppendingString:path];
    iconImages = [[NSDictionary dictionaryWithObjectsAndKeys:
                   /*** app_portal ***/
                   @"gree_btn_subnavi_home_default.png",[game stringByAppendingString:@"btn_subnavi_home_default@2x.png"],
                   @"gree_btn_subnavi_home_highlight.png",[game stringByAppendingString:@"btn_subnavi_home_highlight@2x.png"],
                   @"gree_btn_subnavi_new_default.png",[game stringByAppendingString:@"btn_subnavi_new_default@2x.png"],
                   @"gree_btn_subnavi_new_highlight.png",[game stringByAppendingString:@"btn_subnavi_new_highlight@2x.png"],
                   @"gree_btn_subnavi_categories_default.png",[game stringByAppendingString:@"btn_subnavi_categories_default@2x.png"],
                   @"gree_btn_subnavi_categories_highlight.png",[game stringByAppendingString:@"btn_subnavi_categories_highlight@2x.png"],
                   @"gree_btn_subnavi_coins_default.png",[game stringByAppendingString:@"btn_subnavi_coins_default@2x.png"],                                      
                   @"gree_btn_subnavi_coins_highlight.png",[game stringByAppendingString:@"btn_subnavi_coins_highlight@2x.png"],
                   @"gree_btn_subnavi_search_default.png",[game stringByAppendingString:@"btn_subnavi_search_default@2x.png"],                   
                   @"gree_btn_subnavi_search_highlight.png",[game stringByAppendingString:@"btn_subnavi_search_highlight@2x.png"],                   
                   /*** game portal ***/
                   @"gree_btn_subnavi_dashboard_home_default.png",[app stringByAppendingString:@"btn_subnavi_dashboard_home_default@2x.png"],
                   @"gree_btn_subnavi_dashboard_home_highlight.png",[app stringByAppendingString:@"btn_subnavi_dashboard_home_highlight@2x.png"],
                   @"gree_btn_subnavi_ranking_default.png",[app stringByAppendingString:@"btn_subnavi_ranking_default@2x.png"],
                   @"gree_btn_subnavi_ranking_highlight.png",[app stringByAppendingString:@"btn_subnavi_ranking_highlight@2x.png"],
                   @"gree_btn_subnavi_achievements_default.png",[app stringByAppendingString:@"btn_subnavi_achievements_default@2x.png"],
                   @"gree_btn_subnavi_achievements_highlight.png",[app stringByAppendingString:@"btn_subnavi_achievements_highlight@2x.png"],
                   @"gree_btn_subnavi_users_default.png",[app stringByAppendingString:@"btn_subnavi_users_default@2x.png"],
                   @"gree_btn_subnavi_users_highlight.png",[app stringByAppendingString:@"btn_subnavi_users_highlight@2x.png"],                   
                   /*** friend ***/
                   @"gree_btn_subnavi_friends_list_default.png",[sns stringByAppendingString:@"btn_subnavi_friends_list_default.png"],
                   @"gree_btn_subnavi_friends_list_highlight.png",[sns stringByAppendingString:@"btn_subnavi_friends_list_highlight.png"],
                   @"gree_btn_subnavi_requests_default.png",[sns stringByAppendingString:@"btn_subnavi_requests_default.png"],
                   @"gree_btn_subnavi_requests_highlight.png",[sns stringByAppendingString:@"btn_subnavi_requests_highlight.png"],
                   @"gree_btn_subnavi_footprints_default.png",[sns stringByAppendingString:@"btn_subnavi_footprints_default.png"],
                   @"gree_btn_subnavi_footprints_highlight.png",[sns stringByAppendingString:@"btn_subnavi_footprints_highlight.png"],
                   @"gree_btn_subnavi_find_friends_default.png",[sns stringByAppendingString:@"btn_subnavi_find_friends_default.png"],
                   @"gree_btn_subnavi_find_friends_highlight.png",[sns stringByAppendingString:@"btn_subnavi_find_friends_highlight.png"],                   
                   /***  profile ***/
                   @"gree_btn_subnavi_info_default.png",[sns stringByAppendingString:@"btn_subnavi_info_default.png"],
                   @"gree_btn_subnavi_info_highlight.png",[sns stringByAppendingString:@"btn_subnavi_info_highlight.png"],
                   @"gree_btn_subnavi_profile_updates_default.png", [sns stringByAppendingString:@"btn_subnavi_profile_updates_default.png"],
                   @"gree_btn_subnavi_profile_updates_highlight.png", [sns stringByAppendingString:@"btn_subnavi_profile_updates_highlight.png"],
                   @"gree_btn_subnavi_guest_book_default.png",[sns stringByAppendingString:@"btn_subnavi_guest_book_default.png"],                
                   @"gree_btn_subnavi_guest_book_highlight.png",[sns stringByAppendingString:@"btn_subnavi_guest_book_highlight.png"],                   
                   /*** community ***/
                   @"gree_btn_subnavi_community_updates_default.png",[sns stringByAppendingString:@"btn_subnavi_community_updates_default.png"],
                   @"gree_btn_subnavi_community_updates_highlight.png",[sns stringByAppendingString:@"btn_subnavi_community_updates_highlight.png"],
                   @"gree_btn_subnavi_featured_default.png",[sns stringByAppendingString:@"btn_subnavi_featured_default.png"],
                   @"gree_btn_subnavi_featured_highlight.png",[sns stringByAppendingString:@"btn_subnavi_featured_highlight.png"],
                   @"gree_btn_subnavi_search_default.png",[sns stringByAppendingString:@"btn_subnavi_search_default.png"],                                      
                   @"gree_btn_subnavi_search_highlight.png", [sns stringByAppendingString:@"btn_subnavi_search_highlight.png"],                   
                   @"gree_btn_subnavi_categories_default.png",[sns stringByAppendingString:@"btn_subnavi_categories_default.png"],
                   @"gree_btn_subnavi_categories_highlight.png", [sns stringByAppendingString:@"btn_subnavi_categories_highlight.png"],
                   nil] retain];
  }
  NSString *key = (highlight) ? [item objectForKey:kButtonIconSelectedKey] : [item objectForKey:kButtonIconNormalKey];
  return [iconImages objectForKey:key];
}


- (void)downloadImageURL:(NSURL*)url selected:(BOOL)selected forIcon:(GreeJSSubnavigationIconView*)icon
{
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  
  GreeAFHTTPRequestOperation *requestOperation = [[[GreeAFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
  [requestOperation setQueuePriority:(selected ? NSOperationQueuePriorityNormal : NSOperationQueuePriorityHigh)];
  [requestOperation setCompletionBlockWithSuccess:
   ^(GreeAFHTTPRequestOperation *operation, id responseObject) {
     NSData* data = [operation responseData];
     UIImage* image = [UIImage imageWithData:data];
     
     if (image) {
       [[GreeJSSubnavigationIconPersistentCache sharedImageCache]
        cacheImageData:data
        forURL:url
        cacheName:[NSString string]
        ];
     }
     
     if (selected) {
       icon.selectedImage = image;
     } else {
       icon.normalImage = image;
     }
   }
                                          failure:^(GreeAFHTTPRequestOperation *operation, NSError *error) {
                                            NSLog(@"icon download failed %@ %@", url, error);
                                          }
   ];
  [_queue addOperation:requestOperation];
}

#pragma mark -
#pragma mark - Public Interface

- (BOOL)configureSubnavigationMenuWithParams:(NSDictionary*)params
{
  [self resetIcons];
  
  NSInteger index = 0;
  NSDictionary* iconConfigurations = [[params objectForKey:@"subNavigation"] objectForKey:@"subNavigation"];
  for (NSDictionary* item in iconConfigurations) {
    
    // icon key url
    NSURL* normalImageURL      = [NSURL URLWithString:[item objectForKey:kButtonIconNormalKey]];
    NSURL* selectedImageURL    = [NSURL URLWithString:[item objectForKey:kButtonIconSelectedKey]];
    
    // try to get cache image
    GreeJSSubnavigationIconPersistentCache* cache = [GreeJSSubnavigationIconPersistentCache sharedImageCache];
    UIImage *normalImage    = [cache cachedImageForURL:normalImageURL cacheName:[NSString string]];
    UIImage *selectedImage  = [cache cachedImageForURL:selectedImageURL cacheName:[NSString string]];    
    
    // try to get bundle image
    if (normalImage == nil) {
      NSString *bundleIconName = [[self class] nibNameByItem:item highlighted:NO];
      normalImage = [UIImage greeImageNamed:bundleIconName];
    }
    if (selectedImage == nil) {
      NSString *bundleIconName = [[self class] nibNameByItem:item highlighted:YES];
      selectedImage = [UIImage greeImageNamed:bundleIconName];      
    }
    
    GreeJSSubnavigationIconView *icon = [[[GreeJSSubnavigationIconView alloc] initWithNormalImage:normalImage
                                                                                    selectedImage:selectedImage
                                                                                           params:item
                                                                                         delegate:_delegate] autorelease];
    icon.tag = index++;
    
    
    // try to download image
    if (normalImage == nil) {
      [self downloadImageURL:normalImageURL selected:NO forIcon:icon];
    }
    if (selectedImage == nil) {
      [self downloadImageURL:selectedImageURL selected:YES forIcon:icon];
    }
    
    // show temporal image
    if (normalImage == nil) {
      
    }
    if (selectedImage == nil) {
      
    }
    
    [_scrollView addSubview:icon];
    [_icons addObject:icon];
  }
  
  return YES;
}

- (BOOL)visible
{
  return [_icons count] > 0;
}


#pragma mark -
#pragma mark UIView Overrides

- (void)layoutSubviews
{
  
  self.backgroundColor = [UIColor colorWithPatternImage:[UIImage greeImageNamed:@"gree_sub_navi_bg.png"]];
  
  // Parse JSON Data, determine number of buttons.
  NSUInteger numberOfButtons = [_icons count];
  
  // Set scroll view size.
  _scrollView.frame = self.frame;
  float buttonsWidth = numberOfButtons * (kSubnavigationIconImageWidth + kSubnavigationIconMinInnerPadding) + \
  kSubnavigationIconMinInnerPadding;
  float frameWidth = self.frame.size.width;
  float scrollViewWidth = buttonsWidth > frameWidth ? buttonsWidth : frameWidth;
  _scrollView.contentSize = CGSizeMake(scrollViewWidth, self.frame.size.height);
  
  // layout icons
  float iconRectWidth = numberOfButtons < kSubnavigationIconPerPageLimit ?
  frameWidth/numberOfButtons : 
  frameWidth/kSubnavigationIconPerPageLimit;
  
  int iconIndex = 0;
  float lastIconOriginX = 0;
  for (UIView *icon in _icons) {
    float x = floor(iconIndex * iconRectWidth);
    float width = floor((iconIndex + 1) * iconRectWidth) - lastIconOriginX;
    CGRect iconRect = CGRectMake(x,
                                 self.frame.origin.y,
                                 width,
                                 self.frame.size.height);
    icon.frame = iconRect;
    [icon setNeedsLayout];
    
    lastIconOriginX += width;
    iconIndex++;
  }
  [self setNeedsDisplay];
}


@end
