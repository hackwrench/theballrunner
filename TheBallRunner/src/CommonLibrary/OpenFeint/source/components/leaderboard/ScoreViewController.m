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

#import "ScoreViewController.h"
#import "GreeLeaderboard.h"
#import "GreeUser.h"
#import "CustomProfileCell.h"
#import "GreeLeaderboard.h"
#import "GreeScore.h"
#import "GreePlatform.h"
#import "UIColor+ShowCaseAdditions.h"
#import "AlertInputView.h"
#import "CustomSegmentedControl.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+ShowCaseAdditions.h"
#import "ActivityView.h"

typedef enum{
  PeopleFriends,
  PeopleAll
} PeopleControlType;

typedef enum{
  tableSectionData,
  tableSectionLoadMore
} tableSection;

@interface ScoreViewController()
@property(nonatomic, retain) GreeLeaderboard* leaderboard;
@property(nonatomic, retain) GreeScore* myScore;
@property(nonatomic, retain) NSMutableArray* scoreList;

@property(nonatomic, assign) GreePeopleScope currentPeopleScope;
@property(nonatomic, assign) GreeScoreTimePeriod currentTimePeriod;

@property(nonatomic, retain) id<GreeEnumerator> enumerator;
@property(nonatomic, retain) UINib *profileCellLoader;
@property(nonatomic, assign, readwrite) BOOL isLoading;
@property(nonatomic, retain) ActivityView* activityView;

- (int)rowOfNextAvailableCell;
- (void)loadMyScore:(GreeScoreTimePeriod)timePeriod;
- (void)loadMyProfile;

- (void)loadNextPage:(BOOL)needsReload;
@end


@implementation ScoreViewController
@synthesize leaderboard = _leaderboard;
@synthesize myScore = _myScore;
@synthesize scoreList =  _scoreList;
@synthesize currentPeopleScope = _currentPeopleScope;
@synthesize currentTimePeriod =  _currentTimePeriod;
@synthesize enumerator =  _enumerator;
@synthesize tableView = _tableView;
@synthesize peopleSegment = _peopleSegment;
@synthesize localUserScoreView = _localUserScoreView;
@synthesize localUserImageView = _localUserImageView;
@synthesize localUserRankLabel = _localUserRankLabel;
@synthesize localUserScoreLabel = _localUserScoreLabel;
@synthesize profileCellLoader = _profileCellLoader;
@synthesize isLoading =  _isLoading;
@synthesize activityView =  _activityView;

#pragma mark Object-LifeCycle
- (id)initWithLeaderboard:(GreeLeaderboard*)leaderboard
{
  self = [super initWithNibName:nil bundle:nil];
  if (self != nil) {
    _leaderboard = [leaderboard retain];
    _scoreList = [[NSMutableArray array] retain];
    _profileCellLoader = [[UINib nibWithNibName:@"CustomProfileCell" bundle:[NSBundle mainBundle]] retain];
  }
  return self;
}

- (void)dealloc 
{
  [_leaderboard release];
  [_scoreList release];
  [_enumerator release];
  [_myScore release];
  
  [_tableView release];
  [_profileCellLoader release];
  [_peopleSegment release];
  [_localUserScoreView release];
  [_localUserImageView release];
  [_localUserRankLabel release];
  [_localUserScoreLabel release];
  [_activityView release];
  [super dealloc];
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.  
  if (!self.activityView) {
    self.activityView = [ActivityView activityViewWithContainer:self.view];
  }
  
  self.title = NSLocalizedStringWithDefaultValue(@"ScoreViewController.title.label", @"GreeShowCase", [NSBundle mainBundle], @"Score", @"ScoreViewController controller title");
  self.navigationController.navigationBar.tintColor = [UIColor showcaseNavigationBarColor];
  
  self.localUserScoreView.backgroundColor = [UIColor whiteColor];
  self.localUserScoreView.layer.cornerRadius = 10;
  self.localUserImageView.layer.cornerRadius = 5.;
  self.localUserScoreView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.localUserRankLabel.textColor = [UIColor showcaseDarkGrayColor];
  self.localUserScoreLabel.textColor = [UIColor showcaseDarkGrayColor];

  self.peopleSegment.titlePressedColor = [UIColor whiteColor];
  self.peopleSegment.titleNormalColor = [UIColor colorWithRed:139./255.f green:144./255.f blue:147./255.f alpha:1];
  self.peopleSegment.titleFont = [UIFont fontWithName:@"Helvetica-Bold" size:13];
  self.peopleSegment.titleLeftEdge = 6.f;
  self.peopleSegment.imageLeftEdge = -6.f;
  [self.peopleSegment addSegmentsWithTitleAndTwoImages:
   @"Friends",[UIImage imageNamed:@"icn_friends_grey.png"],[UIImage imageNamed:@"icn_friends_lightgrey.png"],
   @"Everyone", [UIImage imageNamed:@"icn_everyone_grey.png"],[UIImage imageNamed:@"icn_everyone_lightgrey.png"],nil];
  self.peopleSegment.delegate = self;
  
  self.currentPeopleScope = GreePeopleScopeFriends;
  self.currentTimePeriod = GreeScoreTimePeriodDaily;
  self.enumerator = [GreeScore scoreEnumeratorForLeaderboard:self.leaderboard.identifier 
                                               timePeriod:self.currentTimePeriod 
                                              peopleScope:self.currentPeopleScope];    
  [self loadMyScore:self.currentTimePeriod];
  [self loadMyProfile];
  [self loadNextPage:NO];
}

- (void)viewDidUnload
{
  [self setTableView:nil];
  [self setPeopleSegment:nil];
  [self setLocalUserScoreView:nil];
  [self setLocalUserImageView:nil];
  [self setLocalUserRankLabel:nil];
  [self setLocalUserScoreLabel:nil];
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return YES;
}

#pragma mark private methods
- (void)updateLocalUserView
{
  NSString* rankFormat = NSLocalizedStringWithDefaultValue(@"ScoreViewController.selfRankLabel.format", @"GreeShowCase", [NSBundle mainBundle], @"%@ #%lld", @"format for current user's rank label");  
  if (self.myScore != nil) {
    self.localUserRankLabel.text = [NSString stringWithFormat:rankFormat, [GreePlatform sharedInstance].localUser.nickname,self.myScore.rank];
    self.localUserScoreLabel.text = [self.myScore formattedScoreWithLeaderboard:self.leaderboard];
  } else {
    rankFormat = NSLocalizedStringWithDefaultValue(@"ScoreViewController.nonRankLabel.format", @"GreeShowCase", [NSBundle mainBundle], @"%@ #N/A", @"format for n/a rank label");
    NSString* scoreFormat = NSLocalizedStringWithDefaultValue(@"ScoreViewController.nonScoreLabel.format", @"GreeShowCase", [NSBundle mainBundle], @"N/A", @"format for n/a score label");
    self.localUserRankLabel.text = [NSString stringWithFormat:rankFormat, [GreePlatform sharedInstance].localUser.nickname];
    self.localUserScoreLabel.text = scoreFormat;
  }
}

- (void)loadMyProfile
{
  [self.localUserImageView showLoadingImageWithSize:self.localUserImageView.frame.size];

  GreeUser* localUser = [GreePlatform sharedInstance].localUser;
  __block ScoreViewController* mySelf = self;
  [localUser loadThumbnailWithSize:GreeUserThumbnailSizeStandard block:^(UIImage* icon, NSError* error) {
    [mySelf.localUserImageView showImage:icon withSize:mySelf.localUserImageView.frame.size];
  }];
}

- (void)loadMyScore:(GreeScoreTimePeriod)timePeriod
{
  [self.activityView startLoading];
  [GreeScore loadMyScoreForLeaderboard:self.leaderboard.identifier 
             timePeriod:timePeriod 
             block:^(GreeScore *score, NSError *error) {
               if (!error) {
                 self.myScore = score;
                 [self updateLocalUserView];
               }
               [self.activityView stopLoading];
             }]; 
}

- (void)updateLoadMoreCell:(UITableViewCell*)loadMoreCell
{
  if ([self.enumerator canLoadNext]) {
    loadMoreCell.userInteractionEnabled = YES;
    loadMoreCell.textLabel.textColor = [UIColor showcaseDarkGrayColor];
    loadMoreCell.textLabel.text = NSLocalizedStringWithDefaultValue(@"ScoreViewController.loadMoreButton.label", @"GreeShowCase", [NSBundle mainBundle], @"Load  more ...", @"score controller load more button label");
  }else{
    loadMoreCell.userInteractionEnabled = NO;
    loadMoreCell.textLabel.textColor = [UIColor lightGrayColor];
    loadMoreCell.textLabel.text = NSLocalizedStringWithDefaultValue(@"ScoreViewController.noMoreButton.label", @"GreeShowCase", [NSBundle mainBundle], @"No more to load", @"score controller no more to load button label");;
  }
}
 
- (void)loadNextPage:(BOOL)needsReload
{
  if (needsReload) {
    self.isLoading = NO;
  }
  if (self.isLoading) {
    return;
  }
  self.isLoading = YES;
  [self.activityView startLoading];
  
  [self.enumerator loadNext:^(NSArray* items, NSError* error) {
    self.isLoading = NO;
    if(error) {
      [[[[UIAlertView alloc] 
         initWithTitle:NSLocalizedStringWithDefaultValue(@"ScoreViewController.alertView.title.text", @"GreeShowCase", [NSBundle mainBundle], @"Error", @"ScoreViewController view title") 
         message:[error localizedDescription] 
         delegate:nil 
         cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ScoreViewController.alertView.button.text", @"GreeShowCase", [NSBundle mainBundle], @"Ok", @"ScoreViewController alert view ok button") 
         otherButtonTitles:nil] autorelease] show];
    }
    int currentIndex = [self rowOfNextAvailableCell];
    if (needsReload) {
      self.scoreList = [NSMutableArray arrayWithArray:items];
      [self.tableView reloadData];
    }else{
      [self.scoreList addObjectsFromArray:items];
      if (items.count > 0) {
        NSMutableArray* paths = [NSMutableArray array];
        for (int index = currentIndex; index < [self rowOfNextAvailableCell]; index++) {
          [paths addObject:[NSIndexPath indexPathForRow:index inSection:tableSectionData]];
        }
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];    
      }
      UITableViewCell* loadMoreCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:tableSectionLoadMore]];
      [self updateLoadMoreCell:loadMoreCell];
    }
    //deselect the load more cell.
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
    [self.activityView stopLoading];
  }];
}

- (int)rowOfNextAvailableCell
{
  return self.scoreList.count;
}

#pragma mark UITableViewDelegate
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{  
  return [CustomProfileCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == tableSectionLoadMore) {
    [self loadNextPage:NO];
  }
}

- (void)segmentedControlValueChanged:(int)selectedSegmentIndex;
{  
  PeopleControlType peopleScope = selectedSegmentIndex;
  if (peopleScope == PeopleFriends) {
    self.currentPeopleScope = GreePeopleScopeFriends;
  }else{
    self.currentPeopleScope = GreePeopleScopeAll;
  }
  self.enumerator = [GreeScore scoreEnumeratorForLeaderboard:self.leaderboard.identifier 
                                                   timePeriod:self.currentTimePeriod 
                                                  peopleScope:self.currentPeopleScope];    
  [self loadNextPage:YES];
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  if (section == tableSectionData) {
    return self.scoreList.count;
  }else{
    return 1;
  }
}

- (IBAction)setNewScoreAction:(id)sender {  
  NSString* title = NSLocalizedStringWithDefaultValue(@"ScoreViewController.submitAlertView.title.label", @"GreeShowCase", [NSBundle mainBundle], @"Submit New Score", @"score controller submit score alert view title");
  NSString* message = NSLocalizedStringWithDefaultValue(@"ScoreViewController.submitAlertView.message.label", @"GreeShowCase", [NSBundle mainBundle], @"Enter a number", @"score controller submit score alert view message");
  NSString* cancelButtonTitle = NSLocalizedStringWithDefaultValue(@"ScoreViewController.submitAlertView.cancelButton.label", @"GreeShowCase", [NSBundle mainBundle], @"Cancel", @"score controller submit score cancel button title");
  NSString* okButtonTitle = NSLocalizedStringWithDefaultValue(@"ScoreViewController.submitAlertView.okButton.label", @"GreeShowCase", [NSBundle mainBundle], @"OK", @"score controller submit score alert view ok button title");
  
  AlertInputView* submitView = [[AlertInputView alloc] initWithTitle:title message:message prepopulatedMessage:nil delegate:self cancelButtonTitle:cancelButtonTitle acceptButtonTitle:okButtonTitle];
  submitView.numbersOnly = YES;
  [submitView show];
  [submitView release];  
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == 0) { //cancel
    return;
  }
  AlertInputView* alertInputView = (AlertInputView*)alertView;
  
  int64_t newScore = [alertInputView.text longLongValue];
  if (newScore > 0) {
    GreeScore* score = [[GreeScore alloc] initWithLeaderboard:self.leaderboard.identifier score:newScore];
    [score submitWithBlock:^{
      [self loadMyScore:self.currentTimePeriod];
      [self loadMyProfile];
      self.enumerator = [GreeScore scoreEnumeratorForLeaderboard:self.leaderboard.identifier
        timePeriod:self.currentTimePeriod 
        peopleScope:self.currentPeopleScope];    
      [self loadNextPage:YES];
    }];
    [score release];
    
    [[[[UIAlertView alloc] 
       initWithTitle:nil 
       message:NSLocalizedStringWithDefaultValue(@"ScoreViewController.successAlertView.title", @"GreeShowCase", [NSBundle mainBundle], @"Your Score Submitted!", @"score controller submit score success alert view title") 
       delegate:nil 
       cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"ScoreViewController.successAlertView.button", @"GreeShowCase", [NSBundle mainBundle], @"OK", @"score controller submit score success alert view button") 
       otherButtonTitles:nil] autorelease] show];
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{ 
  //the second section only has one load more cell
  if (indexPath.section == tableSectionLoadMore) { 
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"LoadMoreCell"];
    if (cell == nil || [cell isKindOfClass:[CustomProfileCell class]]) {
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LoadMoreCell"] autorelease];
      cell.textLabel.textAlignment = UITextAlignmentCenter;
      cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];
    }
    [self updateLoadMoreCell:cell];
    return cell;
  }
  
  CustomProfileCell *cell = (CustomProfileCell*) [tableView dequeueReusableCellWithIdentifier:[CustomProfileCell cellReusableIdentifier]];
  if (cell == nil || ![cell isKindOfClass:[CustomProfileCell class]]) {
    NSArray *topLevelItems = [self.profileCellLoader instantiateWithOwner:self options:nil];
    cell = (CustomProfileCell*)[topLevelItems objectAtIndex:0];
  }else{
    GreeUser* user = cell.userInfo;
    if (user) {
      [user cancelThumbnailLoad];
      cell.userInfo = nil;
    }
  }

  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.customHeight = [self tableView:tableView heightForRowAtIndexPath:indexPath];
  cell.firstLabelFont = [UIFont systemFontOfSize:17];
  cell.secondLabelFont = [UIFont fontWithName:@"Helvetica" size:15];
  cell.firstLabelTextColor = [UIColor showcaseDarkGrayColor];
  cell.secondLabelTextColor = [UIColor showcaseDarkGrayColor];
  
  GreeScore* score = [self.scoreList objectAtIndex:indexPath.row];
  NSString* rankFormat = NSLocalizedStringWithDefaultValue(@"ScoreViewController.rankLabel.format", @"GreeShowCase", [NSBundle mainBundle], @"#%1$lld %2$@", @"fields:1=ranking number;2=player name");
  cell.firstTitleLabel.text = [NSString stringWithFormat:rankFormat, score.rank, score.user.nickname];      
  cell.secondTitleLabel.text = [score formattedScoreWithLeaderboard:self.leaderboard];
  cell.userInfo = score.user;
  
  GreeUser* currentUser = cell.userInfo;
  [cell.iconImageView showLoadingImageWithSize:cell.iconImageView.frame.size];
  [cell setNeedsLayout];

  [currentUser loadThumbnailWithSize:GreeUserThumbnailSizeStandard block:^(UIImage* icon, NSError* error) {
    [cell.iconImageView showImage:icon withSize:cell.iconImageView.frame.size];
    [cell setNeedsLayout];
  }];
  return cell;
}

#pragma mark IBAction
- (IBAction)timeSectionValueChanged:(id)sender {
  UISegmentedControl* timePeriodControl = (UISegmentedControl*)sender;
  GreeScoreTimePeriod timePeriod = (GreeScoreTimePeriod)timePeriodControl.selectedSegmentIndex;
  self.currentTimePeriod = timePeriod;
  //update my score
  [self loadMyScore:timePeriod];
    
  //update other's score
  self.enumerator = [GreeScore scoreEnumeratorForLeaderboard:self.leaderboard.identifier
                                                   timePeriod:timePeriod 
                                                  peopleScope:self.currentPeopleScope];    
  [self loadNextPage:YES];
}

@end
