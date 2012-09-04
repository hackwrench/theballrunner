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

#import "AchievementViewController.h"
#import "GreeAchievement.h"
#import "AchievementCell.h"
#import "GreeUser.h"
#import "GreePlatform.h"
#import "UIColor+ShowCaseAdditions.h"
#import "ActivityView.h"

@interface AchievementViewController()

@property(nonatomic, retain) NSMutableArray* achievementList;
@property(nonatomic, retain) id<GreeEnumerator> enumerator;
@property(nonatomic, retain) UINib *achievementCellLoader;
@property(nonatomic, assign, readwrite) BOOL isLoading;

- (void)handleDataItems:(NSArray*)dataItems error:(NSError*)error;
- (void)loadNextPage;
@end


@implementation AchievementViewController

@synthesize tableView = _tableView;
@synthesize achievementList =  _achievementList;
@synthesize enumerator =  _enumerator;
@synthesize achievementCellLoader =  _achievementCellLoader;
@synthesize isLoading =  _isLoading;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _achievementList = [[NSMutableArray array] retain];
    _enumerator = [[GreeAchievement loadAchievementsWithBlock:nil] retain];
    _achievementCellLoader = [[UINib nibWithNibName:@"AchievementCell" bundle:[NSBundle mainBundle]] retain];
  }
  return self;
}

- (void)dealloc 
{  
  [_tableView release];
  [_achievementList release];
  [_enumerator release];
  [_achievementCellLoader release];
  [super dealloc];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.  
  self.title = NSLocalizedStringWithDefaultValue(@"achievementController.title.label", @"GreeShowCase", [NSBundle mainBundle], @"Achievements", @"achievement controller title");
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
  return self.achievementList.count;
}

- (void)updateLoadMoreCell:(UITableViewCell*)loadMoreCell
{
  if ([self.enumerator canLoadNext]) {
    loadMoreCell.userInteractionEnabled = YES;
    loadMoreCell.textLabel.textColor = [UIColor showcaseDarkGrayColor];
    loadMoreCell.textLabel.text = NSLocalizedStringWithDefaultValue(@"achievementController.loadMoreButton.label", @"GreeShowCase", [NSBundle mainBundle], @"Load  more ...", @"achievement controller load more button label");
  }else{
    loadMoreCell.userInteractionEnabled = NO;
    loadMoreCell.textLabel.textColor = [UIColor lightGrayColor];
    loadMoreCell.textLabel.text = NSLocalizedStringWithDefaultValue(@"achievementController.noMoreButton.label", @"GreeShowCase", [NSBundle mainBundle], @"No more to load", @"achievement controller no more to load button label");;
  }
}

- (void)handleDataItems:(NSArray*)dataItems error:(NSError*)error
{
  //deselect the load more cell.
  [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
  if(error) {
    [[[[UIAlertView alloc] 
       initWithTitle:NSLocalizedStringWithDefaultValue(@"achievementController.alertView.title.text", @"GreeShowCase", [NSBundle mainBundle], @"Error", @"achievement controller alert view title") 
       message:[error localizedDescription] 
       delegate:nil 
       cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"achievementController.alertView.button.text", @"GreeShowCase", [NSBundle mainBundle], @"Ok", @"achievement controller alert view ok button") 
       otherButtonTitles:nil] autorelease] show];
  } 
  if(dataItems.count > 0) {
    int currentIndex = [self rowOfLastCell];
    [self.achievementList addObjectsFromArray:dataItems];  
    
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
  return self.achievementList.count + 1;
}

- (int)achievementIndexForCell:(NSIndexPath*)cellIndexPath
{
  return cellIndexPath.row;
}

- (void)buttonClicked:(id)sender event:(id)event
{
  NSSet *touches = [event allTouches];
  UITouch *touch = [touches anyObject];
  CGPoint currentTouchPosition = [touch locationInView:self.tableView];
  NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:currentTouchPosition];
  if (indexPath != nil) {
    GreeAchievement* achievement = [self.achievementList objectAtIndex:[self achievementIndexForCell:indexPath]];
    if(achievement.isUnlocked) {
      [achievement relockWithBlock:nil];
    } else {
      [achievement setGameCenterResponseBlock:^(NSError *error) {
        NSLog(@"GreeAchievement sent to GameCenter: %@",error ? error : @"Success");
      }];
      [achievement unlockWithBlock:nil];
    }
    
    AchievementCell* cell = (AchievementCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell updateButton];    
    [cell updateImage];
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  //last cell: load more 
  if (indexPath.row == [self rowOfLastCell]) {    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"] autorelease]; 
      cell.textLabel.textAlignment = UITextAlignmentCenter;
      cell.backgroundColor = [UIColor whiteColor];
    }
    [self updateLoadMoreCell:cell];
   return cell;
  }
  
  AchievementCell *cell = (AchievementCell*) [tableView dequeueReusableCellWithIdentifier:@"AchievementCell"];
  if (cell == nil) {
    NSArray *topLevelItems = [self.achievementCellLoader instantiateWithOwner:self options:nil];
    cell = (AchievementCell*)[topLevelItems objectAtIndex:0];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor whiteColor];
  }else{
    //clean up button target
    [cell.changeLockStatusButton removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
  }
  [cell.changeLockStatusButton addTarget:self action:@selector(buttonClicked:event:) forControlEvents:UIControlEventTouchUpInside];
  GreeAchievement* achievement = [self.achievementList objectAtIndex:[self achievementIndexForCell:indexPath]];
  [cell updateWithAchievement:achievement];
  return cell;
}


@end
