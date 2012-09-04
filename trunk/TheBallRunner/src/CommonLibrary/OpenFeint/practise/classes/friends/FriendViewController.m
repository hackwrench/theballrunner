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

#import "FriendViewController.h"
#import "GreeUser.h"
#import "CustomProfileCell.h"
#import "ScoreViewController.h"
#import "GreePlatform.h"
#import "UIColor+ShowCaseAdditions.h"
#import "ImageCell.h"
#import "UIImageView+ShowCaseAdditions.h"
#import "ActivityView.h"

@interface FriendCell : ImageCell
@property(nonatomic, retain, readwrite) GreeUser* user;
@end

@implementation FriendCell
@synthesize user = _user;

- (void)dealloc
{
  [_user release];
  [super dealloc];
}

- (void)updateWithUser:(GreeUser *)user
{
  if (self.user) {
    [self.user cancelThumbnailLoad];
  }
  self.user = user;
  self.textLabel.text = self.user.nickname;
  
  [self.imageView showLoadingImageWithSize:[self imageSize]];
  [self setNeedsLayout];
  [self.user loadThumbnailWithSize:GreeUserThumbnailSizeStandard block:^(UIImage *icon, NSError *error) {
    [self.imageView showImage:icon withSize:[self imageSize]];
    [self setNeedsLayout];
  }];
}
@end


@interface FriendViewController()

@property(nonatomic, retain) NSMutableArray* friendList;
@property(nonatomic, retain) id<GreeEnumerator> enumerator;
@property(nonatomic, assign, readwrite) BOOL isLoading;

- (void)handleDataItems:(NSArray*)dataItems error:(NSError*)error;
- (void)loadNextPage;
@end


@implementation FriendViewController

@synthesize tableView = _tableView;
@synthesize friendList =  _friendList;
@synthesize enumerator =  _enumerator;
@synthesize isLoading =  _isLoading;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _friendList = [[NSMutableArray alloc] init];
    _enumerator = [[[[GreePlatform sharedInstance] localUser] loadFriendsWithBlock:nil] retain];
  }
  return self;
}

- (void)dealloc 
{
  [_tableView release];
  [_friendList release];
  [_enumerator release];
  [super dealloc];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  NSString* temp = NSLocalizedStringWithDefaultValue(@"friendController.title.label", @"GreeShowCase", [NSBundle mainBundle], @"Friends", @"friend controller title");
  self.title = temp;
  
  self.navigationController.navigationBar.tintColor = [UIColor showcaseNavigationBarColor];
  [self loadNextPage];
}

- (void)viewDidUnload
{
  [self setTableView:nil];
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return YES;
}

#pragma mark private methods
- (void)loadNextPage
{
  if (self.isLoading) {
    return;
  }
  self.isLoading = YES;
  
  ActivityView* loadingView = [ActivityView activityViewWithContainer:self.view];
  [loadingView startLoading];
  [self.enumerator loadNext:^(NSArray* items, NSError* error) {
    self.isLoading = NO;
    [self handleDataItems:items error:error];
    [loadingView stopLoading];
  }];
}

- (int)rowOfLastCell
{
  return self.friendList.count;
}

- (void)updateLoadMoreCell:(UITableViewCell*)loadMoreCell
{
  if ([self.enumerator canLoadNext]) {
    loadMoreCell.userInteractionEnabled = YES;
    loadMoreCell.textLabel.textColor = [UIColor showcaseDarkGrayColor];
    loadMoreCell.textLabel.text = NSLocalizedStringWithDefaultValue(@"friendController.loadMoreButton.label", @"GreeShowCase", [NSBundle mainBundle], @"Load  more ...", @"friend controller load more button label");
  }else{
    loadMoreCell.userInteractionEnabled = NO;
    loadMoreCell.textLabel.textColor = [UIColor lightGrayColor];
    loadMoreCell.textLabel.text = NSLocalizedStringWithDefaultValue(@"friendController.noMoreButton.label", @"GreeShowCase", [NSBundle mainBundle], @"No more to load", @"friend controller no more to load button label");;
  }
}

- (void)handleDataItems:(NSArray*)dataItems error:(NSError*)error
{
  //deselect the load more cell.
  [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
  if(error) {
    [[[[UIAlertView alloc] 
       initWithTitle:NSLocalizedStringWithDefaultValue(@"friendController.alertView.title.text", @"GreeShowCase", [NSBundle mainBundle], @"Error", @"friend controller alert view title") 
       message:[error localizedDescription] 
       delegate:nil 
       cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"friendController.alertView.button.text", @"GreeShowCase", [NSBundle mainBundle], @"Ok", @"friend controller alert view ok button") 
       otherButtonTitles:nil] autorelease] show];
  } 
  if(dataItems.count > 0) {
    int currentIndex = [self rowOfLastCell];
    [self.friendList addObjectsFromArray:dataItems];  
    
    NSMutableArray* paths = [NSMutableArray array];
    for (int index = currentIndex; index < [self rowOfLastCell]; index++) {
      [paths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
    }
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
  }
  UITableViewCell* loadMoreCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self rowOfLastCell] inSection:0]];
  [self updateLoadMoreCell:loadMoreCell];
}


#pragma mark UITableViewDelegate
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{  
  return 60.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.row == [self rowOfLastCell]) {
    [self loadNextPage];
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return self.friendList.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{  
  //last cell: load more 
  if (indexPath.row == [self rowOfLastCell]) {    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"LoadMoreCell"];
    if (cell == nil) {
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LoadMoreCell"] autorelease]; 
      cell.textLabel.textAlignment = UITextAlignmentCenter;
      cell.backgroundColor = [UIColor whiteColor];
    }
    [self updateLoadMoreCell:cell];
    return cell;
  }
  
  FriendCell* cell = [tableView dequeueReusableCellWithIdentifier:@"FriendCell"];
  if (cell == nil) {
    cell = [[[FriendCell alloc] initWithScale:.8 height:[self tableView:self.tableView heightForRowAtIndexPath:indexPath] reuseIdentifier:@"FriendCell"] autorelease]; 
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.textColor = [UIColor showcaseDarkGrayColor];
  }
  GreeUser* user = [self.friendList objectAtIndex:indexPath.row];
  [cell updateWithUser:user];
  return cell;
}

@end
