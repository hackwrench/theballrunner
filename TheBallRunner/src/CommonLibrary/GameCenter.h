//
//  GameCenter.h
//  UnderTheSea
//
//  Created by User on 5/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

#define LEADER_BOARD_CATEGORY   @"POPPY_LEADERBOARD_TOPSCORE"

@class GKScore;
@class GKAchievement;
@class GKLeaderboardViewController;
@class GKAchievementViewController;
@class CCMenu;


//==================================================
@protocol GameCenterDelegate <NSObject>

@required
//no support on current device
- (void) noSupport; 

//failed to authenticate current user
- (void) authenticateFailed;

//init successful and ready to work
- (void) onReady;
@end


//==================================================
@interface GameCenter : NSObject<GKAchievementViewControllerDelegate,GKLeaderboardViewControllerDelegate,UIAlertViewDelegate>
{
    BOOL isAuthenticated;
	BOOL gameCenterAvailable;
    
    NSTimer *tmr;
    int tryShowCount;
    
    NSString* playerID;
    int currentScore;
    

    UIViewController *gameCenterViewController;
}

//information of current logged in user
@property (assign,nonatomic) id<GameCenterDelegate> delegate;

-(void) authenticate;
-(CCMenu*) getButton;
-(int) getCurrentScore;
-(void) updateTotalScore;
-(void) commitTotalScore:(int)score;

//atoms
- (void)authenticateLocalPlayer;
- (void)registerForAuthenticationNotification;
- (void)authenticationChanged;
- (BOOL)isAuthenticated;

- (void)reportScore:(int64_t)score forCategory:(NSString*)category;
- (void)reportScore:(GKScore *)scoreReporter;
- (void)saveScoreToDevice:(GKScore *)score;
- (void)retrieveScoresFromDevice;
- (void)showLeaderboard;
- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController;

- (void)reportAchievementIdentifier:(NSString*)identifier percentComplete:(float)percent;
- (void)reportAchievementIdentifier:(GKAchievement *)achievement;
- (void)saveAchievementToDevice:(GKAchievement *)achievement;
- (void)retrieveAchievementsFromDevice;
- (void)showAchievements;
- (void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController;

- (void)close;
@end
