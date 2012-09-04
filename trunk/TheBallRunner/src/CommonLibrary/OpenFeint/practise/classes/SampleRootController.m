//
// Copyright 2011 GREE, Inc.
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

#import "SampleRootController.h"
#import "GreePlatform.h"
#import "GreeUser.h"
#import "CustomProfileCell.h"
#import "AchievementViewController.h"
#import "LeaderboardViewController.h"
#import "FriendViewController.h"
#import "InviteViewController.h"
#import "GreePlatform.h"
#import "RequestViewController.h"
#import "ShareViewController.h"
#import "UIColor+ShowCaseAdditions.h"
#import "PaymentViewController.h"
#import "GreeNotificationQueue.h"
#import "UIImageView+ShowCaseAdditions.h"
#import "AppDelegate.h"
#import "UpgradeViewController.h"

@interface CellData : NSObject
@property(nonatomic, retain) NSString* title;
@property(nonatomic, retain) NSString* controllerName;
@property(nonatomic, retain) NSString* nibName;
@property(nonatomic, retain) UIImage* image;
- (id)initWithTitle:(NSString*)title controllerName:(NSString*)controllerName nibName:(NSString*)nibName image:(UIImage*)image;
@end

@implementation CellData

@synthesize title = _title;
@synthesize controllerName = _controllerName;
@synthesize nibName = _nibName;
@synthesize image =  _image;

- (id)initWithTitle:(NSString*)title controllerName:(NSString*)controllerName nibName:(NSString*)nibName image:(UIImage*)image
{
  if ((self = [super init])) {
    _title = [title retain];
    _controllerName = [controllerName retain];
    _nibName = [nibName retain];
    _image = [image retain];
  }
  return self;
}

- (void)dealloc
{
  [_title release];
  [_controllerName release];
  [_nibName release];
  [_image release];
  [super dealloc];
}
@end



@interface SampleRootController()

@property(nonatomic, retain) NSMutableArray* featureList;
@property(nonatomic, retain) UINib *cellLoader;

- (void)loadUser;
- (void)loadCellData;

@end

@implementation SampleRootController
@synthesize tableView = _tableView;
@synthesize featureList = _featureList;
@synthesize cellLoader = _cellLoader;

#pragma mark Object LifeCycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _cellLoader = [[UINib nibWithNibName:@"CustomProfileCell" bundle:[NSBundle mainBundle]] retain];
    _featureList = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc
{
  [_featureList release];
  [_cellLoader release];
  [_tableView release];
  [super dealloc];
}

#pragma mark internal methods
- (void)addCellWithTitle:(NSString*)title controllerName:(NSString*)controllerName nibName:(NSString*)nibName image:(UIImage*)image
{
  CellData* newData = [[CellData alloc] initWithTitle:title controllerName:controllerName nibName:nibName image:image];
  [self.featureList addObject:newData];
  [newData release];
}

- (void)loadCellData
{
  [self.featureList removeAllObjects];
  if([GreePlatform sharedInstance].localUser) {
    NSString* invite = NSLocalizedStringWithDefaultValue(@"rootController.inviteCell.label", @"GreeShowCase", [NSBundle mainBundle], @"Invites", @"invite cell title");
    NSString* requests = NSLocalizedStringWithDefaultValue(@"rootController.requestCell.label", @"GreeShowCase", [NSBundle mainBundle], @"Requests", @"requests cell title");
    NSString* sharing = NSLocalizedStringWithDefaultValue(@"rootController.shareCell.label", @"GreeShowCase", [NSBundle mainBundle], @"Sharing", @"sharing cell title");
    NSString* friends = NSLocalizedStringWithDefaultValue(@"rootController.friendCell.label", @"GreeShowCase", [NSBundle mainBundle], @"Friends", @"friends cell title");
    NSString* achievements = NSLocalizedStringWithDefaultValue(@"rootController.achievementCell.label", @"GreeShowCase", [NSBundle mainBundle], @"Achievements", @"achievements cell title");
    NSString* leaderboards = NSLocalizedStringWithDefaultValue(@"rootController.leaderboardCell.label", @"GreeShowCase", [NSBundle mainBundle], @"Leaderboards", @"leaderboards cell title");
    NSString* payment = NSLocalizedStringWithDefaultValue(@"rootController.paymentCell.label", @"GreeShowCase", [NSBundle mainBundle], @"Payment", @"payment cell title");
    NSString* upgrade = NSLocalizedStringWithDefaultValue(@"rootController.upgradeCell.label", @"GreeShowCase", [NSBundle mainBundle], @"Upgrade", @"upgrade cell title");
    
    [self addCellWithTitle:invite controllerName:NSStringFromClass([InviteViewController class]) nibName:nil image:[UIImage imageNamed:@"icn_root_invites.png"]];
    [self addCellWithTitle:requests controllerName:NSStringFromClass([RequestViewController class]) nibName:nil image:[UIImage imageNamed:@"icn_root_requests.png"]];
    [self addCellWithTitle:sharing controllerName:NSStringFromClass([ShareViewController class]) nibName:nil image:[UIImage imageNamed:@"icn_root_sharing.png"]];
    [self addCellWithTitle:friends controllerName:NSStringFromClass([FriendViewController class]) nibName:nil image:[UIImage imageNamed:@"icn_root_friends.png"]];
    [self addCellWithTitle:achievements controllerName:NSStringFromClass([AchievementViewController class]) nibName:nil image:[UIImage imageNamed:@"icn_root_achievements.png"]];
    [self addCellWithTitle:leaderboards controllerName:NSStringFromClass([LeaderboardViewController class]) nibName:nil image:[UIImage imageNamed:@"icn_root_leaderboards.png"]];
    [self addCellWithTitle:payment controllerName:NSStringFromClass([PaymentViewController class]) nibName:nil image:[UIImage imageNamed:@"icn_root_payments.png"]];
    [self addCellWithTitle:upgrade controllerName:NSStringFromClass([UpgradeViewController class]) nibName:nil image:[UIImage imageNamed:@"icn_root_upgrade.png"]];
  }
  [self.tableView reloadData];
}

- (void)updateCustomProfileCell:(CustomProfileCell*)cell
{
  NSString* nameDefault = NSLocalizedStringWithDefaultValue(@"rootController.customcell.name.default.title", @"GreeShowCase", [NSBundle mainBundle], @"User ???", @"Marked as unknown name");
  NSString* userinfoDefault = NSLocalizedStringWithDefaultValue(@"rootController.customcell.userinfofield.default.title", @"GreeShowCase", [NSBundle mainBundle], @"???", @"Marked as unknown userinfo");
  
  NSString* name = nameDefault;
  NSString* userinfo = userinfoDefault;
  GreeUser* localuser = [GreePlatform sharedInstance].localUser;
  if (localuser != nil) {
    name = localuser.nickname;
    NSString* userInfoFormat = NSLocalizedStringWithDefaultValue(@"rootController.customcell.userinfofield.format", @"GreeShowCase", [NSBundle mainBundle], @"user id: %1$@, grade: %2$d", @"fields:1=user id;2=user grade");
    userinfo = [NSString stringWithFormat:userInfoFormat, localuser.userId, localuser.userGrade];
  }
  cell.firstTitleLabel.text = name;
  cell.secondTitleLabel.text = userinfo;
}

- (void)updateProfileImage:(CustomProfileCell*)cell
{
  GreeUser* user = [GreePlatform sharedInstance].localUser;
  if(user) {
    [user loadThumbnailWithSize:GreeUserThumbnailSizeStandard block:^(UIImage* icon, NSError* error) {
      if (error) {
        [[[[UIAlertView alloc] 
           initWithTitle:NSLocalizedStringWithDefaultValue(@"rootController.alertView.title.text", @"GreeShowCase", [NSBundle mainBundle], @"Error", @"alert view title")
           message:[error localizedDescription] 
           delegate:nil 
           cancelButtonTitle:NSLocalizedStringWithDefaultValue(@"rootController.alertView.button.text", @"GreeShowCase", [NSBundle mainBundle], @"Ok", @"alert view ok button")
           otherButtonTitles:nil] autorelease] show];
      }
      [cell.iconImageView showImage:icon withSize:cell.iconImageView.frame.size];
    }];
  } else {
    [cell.iconImageView showNoImageWithSize:cell.iconImageView.frame.size];
  }
}

- (void)loadUser
{
  CustomProfileCell* cell = (CustomProfileCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
  [self loadCellData];
  [self updateCustomProfileCell:cell];
  [self updateProfileImage:cell];
}

- (void)logOutButtonClicked:(id)sender
{
  if([GreePlatform sharedInstance].localUser) {
    [GreePlatform revokeAuthorization];
  } else {
    [GreePlatform authorize];
  }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  self.title = NSLocalizedStringWithDefaultValue(@"rootController.title.label", @"GreeShowCase", [NSBundle mainBundle], @"Sample App", @"root controller title");
  self.navigationController.navigationBar.tintColor = [UIColor showcaseNavigationBarColor];
  [self loadCellData];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
}

- (void)viewDidUnload
{
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
  [self setTableView:nil];
  [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return YES;
}

#pragma mark UITableViewDelegate
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.row == 0) {
    return [CustomProfileCell cellHeight];
  }else{
    return 44.0f;
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString* controllerName = [(CellData*)[self.featureList objectAtIndex:(indexPath.row-1)] controllerName];
  UIViewController* controller = [[[NSClassFromString(controllerName) alloc] initWithNibName:nil bundle:nil] autorelease];
  [self.navigationController pushViewController:controller animated:YES];
}


-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
  return 50.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
  UIView* footerView = nil;
  CGFloat footerHeight = [self tableView:tableView heightForFooterInSection:0];
  CGFloat footerWidth = tableView.frame.size.width;
  footerView = [[[UIView alloc]initWithFrame:CGRectMake(0, 0, footerWidth,footerHeight)] autorelease];
  footerView.backgroundColor = [UIColor clearColor];
  
  UIButton *button=[UIButton buttonWithType:UIButtonTypeRoundedRect];
  button.frame=CGRectMake(0, 0, footerWidth - 20.f, footerHeight - 10.f);
  button.center = CGPointMake(floorf(footerView.center.x), floorf(footerView.center.y));
  NSString* logout = NSLocalizedStringWithDefaultValue(@"ScoreViewController.logoutButton.title", @"GreeShowCase", [NSBundle mainBundle], @"Log Out", @"Showcase root controller log out button title"); 
  NSString* login = NSLocalizedStringWithDefaultValue(@"ScoreViewController.loginButton.title", @"GreeShowCase", [NSBundle mainBundle], @"Log In", @"Showcase root controller log in button title"); 
  BOOL hasUser = [GreePlatform sharedInstance].localUser != nil;
  [button setTitle:hasUser?logout:login forState:UIControlStateNormal];
  [button addTarget:self action:@selector(logOutButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
  button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [footerView addSubview:button];
  return  footerView;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return self.featureList.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  //first profile cell
  if (indexPath.row == 0) {    
    CustomProfileCell *cell = (CustomProfileCell*) [tableView dequeueReusableCellWithIdentifier:[CustomProfileCell cellReusableIdentifier]];
    if (cell == nil) {
      NSArray *topLevelItems = [self.cellLoader instantiateWithOwner:self options:nil];
      cell = (CustomProfileCell*)[topLevelItems objectAtIndex:0];
    }
    if (![cell.iconImageView hasValidImage]) {
      [cell.iconImageView showLoadingImageWithSize:cell.iconImageView.frame.size];
    }
    cell.userInteractionEnabled = NO;
    cell.customHeight = [self tableView:tableView heightForRowAtIndexPath:indexPath];
    [self updateCustomProfileCell:cell];
    [self updateProfileImage:cell];
    return cell;
  }
  
  //other normal cells
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"] autorelease];
  }
  cell.textLabel.textColor = [UIColor showcaseDarkGrayColor];
  cell.backgroundColor = [UIColor whiteColor];;
  CellData* data = [self.featureList objectAtIndex:(indexPath.row-1)];
  cell.textLabel.text = data.title;
  cell.imageView.image = data.image;
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  return cell;
}

@end
