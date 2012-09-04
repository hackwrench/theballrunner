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

#import "LeaderboardViewController.h"
#import "GreeLeaderboard.h"
#import "GreeUser.h"
#import "CustomProfileCell.h"
#import "ScoreViewController.h"
#import "UIColor+ShowCaseAdditions.h"
#import "GreePlatform.h"
#import "ImageCell.h"
#import "UIImageView+ShowCaseAdditions.h"
#import "ActivityView.h"


@interface LeaderboardCell : ImageCell
@property(nonatomic, retain, readwrite) GreeLeaderboard* leaderboard;
@end

@implementation LeaderboardCell
@synthesize leaderboard = _leaderboard;

- (id)initWithScale:(float)scale height:(float)height reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithScale:scale height:height reuseIdentifier:reuseIdentifier];
  if (self) {
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
  return self;
}

- (void)dealloc
{
  [_leaderboard release];
  [super dealloc];
}

- (void)updateWithLeaderboard:(GreeLeaderboard *)leaderboard
{
  if (self.leaderboard) {
    //clean up reused cell's old request and image
    [self.leaderboard cancelIconLoad];
  }
  
  [self.imageView showLoadingImageWithSize:[self imageSize]];
  [self setNeedsLayout];
  
  self.leaderboard = leaderboard;
  self.textLabel.text = self.leaderboard.name;

  [self.leaderboard loadIconWithBlock:^(UIImage *image, NSError *error) {
    [self.imageView showImage:image withSize:[self imageSize]];
    [self setNeedsLayout];
  }];
}

@end



@interface LeaderboardViewController()

@property(nonatomic, retain) NSMutableArray* leaderboardList;
@property(nonatomic, retain) id<GreeEnumerator> enumerator;
@property(nonatomic, retain) UINib *profileCellLoader;
@property(nonatomic, retain) UINib *leaderboardCellLoader;
@property(nonatomic, assign, readwrite) BOOL isLoading;

- (void)handleDataItems:(NSArray*)dataItems error:(NSError*)error;
- (void)loadNextPage;
@end


@implementation LeaderboardViewController

@synthesize tableView = _tableView;
@synthesize leaderboardList =  _leaderboardList;
@synthesize enumerator =  _enumerator;
@synthesize profileCellLoader = _profileCellLoader;
@synthesize leaderboardCellLoader =  _leaderboardCellLoader;
@synthesize isLoading =  _isLoading;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _leaderboardList = [[NSMutableArray array] retain];
    _enumerator = [[GreeLeaderboard loadLeaderboardsWithBlock:nil] retain];
  }
  return self;
}

- (void)dealloc 
{
  [_tableView release];
  [_leaderboardList release];
  [_enumerator release];
  [_profileCellLoader release];
  [_leaderboardCellLoader release];
  [super dealloc];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.  
  self.title = NSLocalizedStringWithDefaultValue(@"leaderboardController.title.label", @"GreeShowCase", [NSBundle mainBundle], @"Leaderboards", @"leaderboard controller title");
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

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
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
    dispatch_async(dispatch_get_main_queue(), ^{
      [self handleDataItems:items error:error];      
      [loadingView stopLoading];
    });
  }];
}

- (int)rowOfLastCell
{
  return self.leaderboardList.count;
}

- (void)updateLoadMoreCell:(UITableViewCell*)loadMoreCell
{
 if ([self.enumerator canLoadNext]) {
    loadMoreCell.userInteractionEnabled = YES;
    loadMoreCell.textLabel.textColor = [UIColor showcaseDarkGrayColor];
    loadMoreCell.textLabel.text = NSLocalizedStringWithDefaultValue(@"leaderboardController.loadMoreButton.label", @"GreeShowCase", [NSBundle mainBundle], @"Load  more ...", @"leaderboard controller load more button label");
  }else{
    loadMoreCell.userInteractionEnabled = NO;
    loadMoreCell.textLabel.textColor = [UIColor lightGrayColor];
    loadMoreCell.textLabel.text = NSLocalizedStringWithDefaultValue(@"leaderboardController.noMoreButton.label", @"GreeShowCase", [NSBundle mainBundle], @"No more to load", @"leaderboard controller no more to load button label");;
  }
}

- (void)handleDataItems:(NSArray*)dataItems error:(NSError*)error
{
  //deselect the load more cell.
  [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
  if(error) {
    [[[[UIAlertView alloc] 
       initWithTitle:NSLocalizedStringWithDefaultValue(@"leaderboardController.alertView.title.text", @"GreeShowCase", [NSBundle mainBundle], @"Error", @"leaderboard controller alert view title") 
       message:[error localizedDescription] 
       delegate:nil 
       cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"leaderboardController.alertView.button.text", @"GreeShowCase", [NSBundle mainBundle], @"Ok", @"leaderboard controller alert view ok button") 
       otherButtonTitles:nil] autorelease] show];
  } 
  if(dataItems.count > 0) {
    int currentIndex = [self rowOfLastCell];
    [self.leaderboardList addObjectsFromArray:dataItems];  
    
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
  }else{
    GreeLeaderboard* leaderboard = [self.leaderboardList objectAtIndex:indexPath.row];
    ScoreViewController* scoreController = [[ScoreViewController alloc] initWithLeaderboard:leaderboard];
    [self.navigationController pushViewController:scoreController animated:YES];
    [scoreController release];
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return self.leaderboardList.count + 1;
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
  
  LeaderboardCell* cell = [tableView dequeueReusableCellWithIdentifier:@"LeaderboardCell"];
  if (cell == nil) {
    cell = [[[LeaderboardCell alloc] initWithScale:.8  height:[self tableView:self.tableView heightForRowAtIndexPath:indexPath] reuseIdentifier:@"LeaderboardCell"] autorelease]; 
    cell.backgroundColor = [UIColor whiteColor];
    cell.textLabel.textColor = [UIColor showcaseDarkGrayColor];
  }
  GreeLeaderboard* leaderboard = [self.leaderboardList objectAtIndex:indexPath.row];
  [cell updateWithLeaderboard:leaderboard];
  return cell;
}


@end
