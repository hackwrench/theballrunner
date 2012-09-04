//
//  GameCenter.m
//  UnderTheSea
//
//  Created by User on 5/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "UIAlertView+Block.h"
#import "GameCenter.h"
#import "Categories.h"
#import "MainGame.h"
#import "AppDelegate.h"

@implementation GameCenter
static NSMutableArray *controllers_=nil;
static NSMutableArray *views_=nil;

@synthesize delegate;

-(id) init
{
    self=[super init];
    gameCenterViewController=nil;
    
    if (controllers_==nil) controllers_=[[NSMutableArray alloc] init];
    if (views_==nil) views_=[[NSMutableArray alloc] init];
    
    return self;
}
//--------------------------------------------------
- (void) authenticate
{
    //delegate=_delegate;
    [self authenticateLocalPlayer];
}

//--------------------------------------------------
-(CCMenu*) getButton
{
    __block GameCenter* __self=self;
    __block BOOL __isAuthenticated=isAuthenticated;   
    
    CCMenuItemImage *bt=[CCMenuItemImage itemFromNormalImage:GAMECENTER_IMG selectedImage:nil block:^(id sender){
        tryShowCount=0;
        if (!__isAuthenticated) [__self authenticate];
        
        __self->tmr=[NSTimer scheduledTimerWithTimeInterval:0.2 target:__self selector:@selector(showLeaderboard) userInfo:nil repeats:YES];
        [__self->tmr fire];    
    }];
    
    CCMenu *mn=[CCMenu menuWithItems:bt, nil];
    return mn;
}



//--------------------------------------------------
-(int) getCurrentScore
{
    return currentScore;
}

-(void) updateTotalScore
{
    if(!isAuthenticated) return;
    
    GKLeaderboard *query = [[GKLeaderboard alloc] initWithPlayerIDs:[NSArray arrayWithObject:playerID]];
    [query autorelease];
    
    if (query != nil)
    {        
        [query loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error) {
            
            // handle the error.
            if (error != nil)
            {
                NSLog(@"[GameCenter/updateTotalScore]Error : %@",error.description);
            }
                
            if (scores != nil)
            {
                // process the score information.
                GKScore *gkScore= [scores objectAtIndex:0] ;
                currentScore=gkScore.value;
                NSLog(@"[GameCenter/updateTotalScore]Current score : %d",currentScore);
            } 
            else currentScore=0;
        }];        
    }
    
}

//--------------------------------------------------
-(void) commitTotalScore:(int)score
{
    if(!isAuthenticated) return;
    if (currentScore>=score) return;
    
    GKScore *scoreReporter = [[[GKScore alloc] initWithCategory:LEADER_BOARD_CATEGORY] autorelease];
    [scoreReporter setCategory:LEADER_BOARD_CATEGORY]; 
	if(scoreReporter){
		scoreReporter.value = score;	
		
		[scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {	
			if (error != nil){
				// handle the reporting error
				NSLog(@"[GameCenter/commitTotalScore]Error : %@",error.description);
			} 
            else
            {
                [self updateTotalScore];
                //currentScore=score;
				//NSLog(@"[GameCenter/commitTotalScore]Current score : %d",score);                
            }
		}];	
	}
    
}


//atoms
//--------------------------------------------------
BOOL isGameCenterAvailable()
{
    // Check for presence of GKLocalPlayer API.	
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));	
	
    // The device must be running running iOS 4.1 or later.	
    NSString *reqSysVer = @"4.1";	
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];	
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);	
	
    return (gcClass && osVersionSupported);
}


//--------------------------------------------------------
// Static functions/variables
//--------------------------------------------------------

static NSString *getGameCenterSavePath()
{
    NSString *documentsDirectory = [NSHomeDirectory() 
                                    stringByAppendingPathComponent:@"Documents"];
    NSString *pth=[documentsDirectory 
                   stringByAppendingPathComponent:@"GameCenterSave.txt"];
    
    
    return pth;
}

static NSString *scoresArchiveKey = @"Scores";

static NSString *achievementsArchiveKey = @"Achievements";

//--------------------------------------------------------
// Authentication
//--------------------------------------------------------

- (void)authenticateLocalPlayer {
    __block id<GameCenterDelegate> __delegate=delegate;
    __block int __tryShowCount=tryShowCount;
    
	isAuthenticated = NO; // assume the player isn't authenticated
	gameCenterAvailable = isGameCenterAvailable();
	
	if(!gameCenterAvailable){
        [delegate noSupport];
		return;
	}
		
    [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:^(NSError *error) {		
		if (error == nil){            
            
			// Insert code here to handle a successful authentication.
			isAuthenticated = YES;
			[self registerForAuthenticationNotification];
			
			// report any unreported scores or achievements
			//[self retrieveScoresFromDevice];
			//[self retrieveAchievementsFromDevice];
			
            playerID=[GKLocalPlayer localPlayer].playerID;
            
            //get current highscore for this player
            [self updateTotalScore];
            
            [delegate onReady];
			            
            // let the scripts know
			//Con::executef(2,"gameCenterAuthenticationChanged","1");
		}else{
            
			//Con::executef(2,"gameCenterAuthenticationChanged","0");            
            UIAlertView *v=[UIAlertView alertViewWithOK:@"GameCenter" :@"Cannot enable GameCenter ! Please try to signin by GameCenter app" onOK:^{
                [__delegate authenticateFailed];
                __tryShowCount=100;
                return ;
            }];
            [v show];
		}
	}];
}

- (void)registerForAuthenticationNotification
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self selector:@selector(authenticationChanged) name:GKPlayerAuthenticationDidChangeNotificationName object:nil];
}

- (void)authenticationChanged
{
    __block id<GameCenterDelegate> __delegate=delegate;
    __block int __tryShowCount=tryShowCount;
    
	isAuthenticated = NO; // assume the player isn't authenticated
	gameCenterAvailable = isGameCenterAvailable();
	
	if(!gameCenterAvailable){
		return;
	}
	
    if ([GKLocalPlayer localPlayer].isAuthenticated){		
        // Insert code here to handle a successful authentication.
		isAuthenticated = YES;
		
		// report any unreported scores or achievements
		//[self retrieveScoresFromDevice];
		//[self retrieveAchievementsFromDevice];
		
        playerID=[GKLocalPlayer localPlayer].playerID;
        
        //get current highscore for this player
        [self updateTotalScore];
        
        [delegate onReady];
        
		// let the scripts know
		//Con::executef(2,"gameCenterAuthenticationChanged","1");
	}else{
		//Con::executef(2,"gameCenterAuthenticationChanged","0");
        UIAlertView *v=[UIAlertView alertViewWithOK:@"GameCenter" :@"Cannot enable GameCenter" onOK:^{
            [__delegate authenticateFailed];
            __tryShowCount=100;
            return ;
        }];
        [v show];
	}
}

- (BOOL)isAuthenticated
{
	return gameCenterAvailable && isAuthenticated;
}

//--------------------------------------------------------
// Leaderboard
//--------------------------------------------------------

- (void)reportScore:(int64_t)score forCategory:(NSString*)category
{
	if(!gameCenterAvailable) return;
    if (!isAuthenticated) return;
	
    GKScore *scoreReporter = [[[GKScore alloc] initWithCategory:category] autorelease];
	if(scoreReporter){
		scoreReporter.value = score;	
		
		[scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {	
			if (error != nil){
				// handle the reporting error
				[self saveScoreToDevice:scoreReporter];
			}
		}];	
	}
}

- (void)reportScore:(GKScore *)scoreReporter
{
	if(!gameCenterAvailable)
		return;
	
	if(scoreReporter){
		[scoreReporter reportScoreWithCompletionHandler:^(NSError *error) {	
			if (error != nil){
				// handle the reporting error
				[self saveScoreToDevice:scoreReporter];
			}
		}];	
	}
}

- (void)saveScoreToDevice:(GKScore *)score
{
	NSString *savePath = getGameCenterSavePath();
	
	// If scores already exist, append the new score.
	NSMutableArray *scores = [[[NSMutableArray alloc] init] autorelease];
	NSMutableDictionary *dict;
	if([[NSFileManager defaultManager] fileExistsAtPath:savePath]){
		dict = [[[NSMutableDictionary alloc] initWithContentsOfFile:savePath] autorelease];
		
		NSData *data = [dict objectForKey:scoresArchiveKey];
		if(data) {
			NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
			scores = [unarchiver decodeObjectForKey:scoresArchiveKey];
			[unarchiver finishDecoding];
			[unarchiver release];
			[dict removeObjectForKey:scoresArchiveKey]; // remove it so we can add it back again later
		}
	}else{
		dict = [[[NSMutableDictionary alloc] init] autorelease];
	}
	
	[scores addObject:score];
	
	// The score has been added, now save the file again
	NSMutableData *data = [NSMutableData data];	
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeObject:scores forKey:scoresArchiveKey];
	[archiver finishEncoding];
	[dict setObject:data forKey:scoresArchiveKey];
	[dict writeToFile:savePath atomically:YES];
	[archiver release];
}

- (void)retrieveScoresFromDevice
{
	NSString *savePath = getGameCenterSavePath();
	
	// If there are no files saved, return
	if(![[NSFileManager defaultManager] fileExistsAtPath:savePath]){
		return;
	}
	
	// First get the data
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:savePath];
	NSData *data = [dict objectForKey:scoresArchiveKey];
	
	// A file exists, but it isn't for the scores key so return
	if(!data){
		return;
	}
	
	NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
	NSArray *scores = [unarchiver decodeObjectForKey:scoresArchiveKey];
	[unarchiver finishDecoding];
	[unarchiver release];
	
	// remove the scores key and save the dictionary back again
	[dict removeObjectForKey:scoresArchiveKey];
	[dict writeToFile:savePath atomically:YES];
	
	
	// Since the scores key was removed, we can go ahead and report the scores again
	for(GKScore *score in scores){
		[self reportScore:score];
	}
}

- (void)showLeaderboard
{
    UIView *glView=[[CCDirector sharedDirector] openGLView];
    
    tryShowCount++;
    if (tryShowCount>20) {
        [tmr invalidate];
        tryShowCount=0;
        
        UIAlertView *alert=[UIAlertView alertViewWithOK:@"GameCenter" :@"Cannot open Leaderboard now,please try again later" onOK:nil];
        [alert show];
        
        [glView setExclusiveTouch:NO];        
        glView.alpha=1.0;
    }
    else 
    {
        if (glView.alpha!=0.7){
            [glView setExclusiveTouch:YES];
            glView.alpha=0.7;
        }
    }

    if(!isAuthenticated) return;
    
    [glView setExclusiveTouch:NO];
    glView.alpha=1.0;
    [tmr invalidate];
    tryShowCount=0;
    
    //disable
    //glView.alpha=0.7;
    //[glView setExclusiveTouch:YES];
    
    if (gameCenterViewController==nil) gameCenterViewController = [[UIViewController alloc] init];
    
    GKLeaderboardViewController *leaderboardController= [[GKLeaderboardViewController alloc] init];
    [leaderboardController autorelease];
        
    if (leaderboardController==nil) {
        UIAlertView *alert=[UIAlertView alertViewWithOK:@"GameCenter" :@"Cannot open Leaderboard now,please try again later" onOK:nil];
        [alert show];
        [glView setExclusiveTouch:NO];
        glView.alpha=1.0;
    }
    
    [glView addSubview:gameCenterViewController.view];
    
    leaderboardController.timeScope=GKLeaderboardTimeScopeAllTime;
    leaderboardController.category=LEADER_BOARD_CATEGORY;        
    leaderboardController.leaderboardDelegate = self;

    
    __block UIView * __glView=glView;
    __block GKLeaderboardViewController *__leaderboardController=leaderboardController;
    
    [gameCenterViewController presentViewController: leaderboardController animated: NO completion:^{
        __leaderboardController.view.transform=CGAffineTransformMakeRotation( CC_DEGREES_TO_RADIANS( 0.0f ) ); 
        __leaderboardController.view.center=ccp(240,160);
        __leaderboardController.view.alpha=1;
        
        /*
        [NSTimer timerWithInterval:0.05 andBlock:^(NSTimer* _tmr){
            if (__leaderboardController.view.alpha<1)
            {
                __leaderboardController.view.alpha+=0.1;
                
            } else
            {
                [_tmr invalidate];
                //enable
                [__glView setExclusiveTouch:NO];
                __glView.alpha=1.0;
            }
        }];
         //*/
    }];
        
    
}

- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
    [gameCenterViewController dismissViewControllerAnimated:YES completion:^(void){
    }];
    [gameCenterViewController.view.superview removeFromSuperview];
}



//--------------------------------------------------------
// Achievements
//--------------------------------------------------------

- (void)reportAchievementIdentifier:(NSString*)identifier percentComplete:(float)percent
{
	if(!gameCenterAvailable)
		return;
	
    GKAchievement *achievement = [[[GKAchievement alloc] initWithIdentifier: identifier] autorelease];	
    if (achievement){		
		achievement.percentComplete = percent;		
		[achievement reportAchievementWithCompletionHandler:^(NSError *error){
			if (error != nil){
				[self saveAchievementToDevice:achievement];
			}		 
		}];
    }
}

- (void)reportAchievementIdentifier:(GKAchievement *)achievement
{	
	if(!gameCenterAvailable)
		return;
	
    if (achievement){		
		[achievement reportAchievementWithCompletionHandler:^(NSError *error){
			if (error != nil){
				[self saveAchievementToDevice:achievement];
			}		 
		}];
    }
}

- (void)saveAchievementToDevice:(GKAchievement *)achievement
{
	
	NSString *savePath = getGameCenterSavePath();
	
	// If achievements already exist, append the new achievement.
	NSMutableArray *achievements = [[[NSMutableArray alloc] init] autorelease];
	NSMutableDictionary *dict;
	if([[NSFileManager defaultManager] fileExistsAtPath:savePath]){
		dict = [[[NSMutableDictionary alloc] initWithContentsOfFile:savePath] autorelease];
		
		NSData *data = [dict objectForKey:achievementsArchiveKey];
		if(data) {
			NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
			achievements = [unarchiver decodeObjectForKey:achievementsArchiveKey];
			[unarchiver finishDecoding];
			[unarchiver release];
			[dict removeObjectForKey:achievementsArchiveKey]; // remove it so we can add it back again later
		}
	}else{
		dict = [[[NSMutableDictionary alloc] init] autorelease];
	}
	
	
	[achievements addObject:achievement];
	
	// The achievement has been added, now save the file again
	NSMutableData *data = [NSMutableData data];	
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeObject:achievements forKey:achievementsArchiveKey];
	[archiver finishEncoding];
	[dict setObject:data forKey:achievementsArchiveKey];
	[dict writeToFile:savePath atomically:YES];
	[archiver release];	
}

- (void)retrieveAchievementsFromDevice
{
	NSString *savePath = getGameCenterSavePath();
	
	// If there are no files saved, return
	if(![[NSFileManager defaultManager] fileExistsAtPath:savePath]){
		return;
	}
	
	// First get the data
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:savePath];
	NSData *data = [dict objectForKey:achievementsArchiveKey];
	
	// A file exists, but it isn't for the achievements key so return
	if(!data){
		return;
	}
	
	NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
	NSArray *achievements = [unarchiver decodeObjectForKey:achievementsArchiveKey];
	[unarchiver finishDecoding];
	[unarchiver release];
	
	// remove the achievements key and save the dictionary back again
	[dict removeObjectForKey:achievementsArchiveKey];
	[dict writeToFile:savePath atomically:YES];
	
	// Since the key file was removed, we can go ahead and try to report the achievements again
	for(GKAchievement *achievement in achievements){
		[self reportAchievementIdentifier:achievement];
	}
}

- (void)showAchievements
{	
	//if(!isAuthenticated) return;
	
    gameCenterViewController = [[UIViewController alloc] init];
    [[[CCDirector sharedDirector] openGLView] addSubview:gameCenterViewController.view];
    
    GKAchievementViewController *achievements = [[GKAchievementViewController alloc] init];	
    if (achievements != nil){
        achievements.achievementDelegate = self;
		
        [gameCenterViewController presentViewController: achievements animated: YES completion:^{
            achievements.view.transform=CGAffineTransformMakeRotation( CC_DEGREES_TO_RADIANS( 0.0f ) ); 
            achievements.view.center=ccp(240,160);        
        }];
    }	
}

- (void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
    [gameCenterViewController dismissModalViewControllerAnimated:YES];
	[viewController.view removeFromSuperview];
	[viewController release];
    
    [gameCenterViewController removeFromParentViewController];
    [gameCenterViewController release];
    gameCenterViewController=nil;
}

//--------------------------------------------------------
// Goodbye
//--------------------------------------------------------

- (void)close
{
	[gameCenterViewController release];
}
@end
