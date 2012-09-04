//
//  OpenFeintShare.m
//  UnderTheSea
//
//  Created by User on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//



#import "cocos2d.h"
#import "AppDelegate.h"

#import "GreePlatform.h"
#import "GreePlatformSettings.h"
#import "OpenFeintShare.h"
#import "GreeScore.h"
#import "MainGame.h"
#import "ScoreViewController.h"
#import "GreeLeaderboard.h"
#import "Categories.h"
#import "UIAlertView+Block.h"

@implementation OpenFeintShare


-(id) init
{
    self=[super init];
    greeRootController=nil;
    

    
    return self;
}

-(void) authenticate
{
    [GreePlatform authorize];    

}

-(CCMenu*) getButton
{
    
    __block OpenFeintShare* __self=self;
    __block BOOL __isAuthenticated=isAuthenticated;
    
    CCMenuItemImage *bt=[CCMenuItemImage itemFromNormalImage:OPENFEINT_IMG selectedImage:nil block:^(id sender){
        tryShowCount=0;
        if (!__isAuthenticated) [__self authenticate];
        
        __self->tmr=[NSTimer scheduledTimerWithTimeInterval:0.2 target:__self selector:@selector(showLeaderBoard) userInfo:nil repeats:YES];
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
    if (!isAuthenticated) return;

    [GreeScore loadMyScoreForLeaderboard:GREE_LEADER_BOARD_ID timePeriod:10 block:^(GreeScore* gscore,NSError *err ){
        if (err!=nil)
        {
            NSLog(@"[OpenFeint/updateTotalScore] Error: %@",err.description);
        }
        else
        {
            NSLog(@"[OpenFeint/updateTotalScore] Current score = %lld",gscore.score);
            currentScore=gscore.score;
        }
    }];
}

//--------------------------------------------------
-(void) commitTotalScore:(int)score
{
    if (!isAuthenticated) return;
    if (score<=currentScore) return;
    
    GreeScore* gscore = [[GreeScore alloc] initWithLeaderboard:GREE_LEADER_BOARD_ID score:score];
    
    [gscore setGameCenterResponseBlock:^(NSError* err){ 
        if (err!=nil)
        {
            NSLog(@"Error : %@",err.description);
        }
        else NSLog(@"Score submitted to GameCenter!"); 
    }];
    
    [gscore submitWithBlock:^(void)
    { 
        NSLog(@"Score submitted to GREE!");
    }]; 
    
    [gscore release];
}

//--------------------------------------------------
- (BOOL)isAuthenticated
{
    return  [GreePlatform isAuthorized];
}


//--------------------------------------------------
-(void) showLeaderBoard
{
    UIView *glView=[[CCDirector sharedDirector] openGLView];
    
    tryShowCount++;
    if (tryShowCount>20) {
        [tmr invalidate];
        tryShowCount=0;
        
        UIAlertView *alert=[UIAlertView alertViewWithOK:@"OpenFeint" :@"Cannot open leaderboard now! Please try again later" onOK:nil];
        [alert show];
        [GreePlatform revokeAuthorization];
        
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
    
    //glView.alpha=0.7;
    //[glView setExclusiveTouch:YES];
    
    [GreePlatform handleLaunchOptions:[AppDelegate getLauchOptions]   
                          application:[AppDelegate getApp]];
    
    if (greeRootController==nil) {     
        greeRootController=[[UIViewController alloc] init ];
    }
    
    __block UIViewController * __greeRootController=greeRootController;
    __block UIView *__glView=glView;
    
    [GreeLeaderboard loadLeaderboardsWithBlock:^(NSArray *boards,NSError* err){
        if (err!=nil)
        {
            NSLog(@"[OpenFeintShare/showLeaderBoard]Error: %@",err.description);            
            UIAlertView *alert=[UIAlertView alertViewWithOK:@"OpenFeint" :@"Cannot open leaderboard now! Please try again later" onOK:^(void){
                [GreePlatform authorize];
            }];
            [alert show];
            __glView.alpha=1.0;
            [__glView setExclusiveTouch:NO];
            return;
        }
        
        greeRootController.view=[[UIView alloc] init];
        [[CCDirector sharedDirector].openGLView addSubview:__greeRootController.view];
        
        for (GreeLeaderboard *board in boards){            
            ScoreViewController *greeLeaderboard=[[ScoreViewController alloc] initWithLeaderboard:board];           
            [greeLeaderboard autorelease];
            
            greeLeaderboard.delegate=__greeRootController;
            
            __block ScoreViewController* __greeLeaderboard=greeLeaderboard;
                        
            [__greeRootController presentViewController:greeLeaderboard animated:NO completion:^(void){
                __greeLeaderboard.view.transform=CGAffineTransformMakeRotation( CC_DEGREES_TO_RADIANS( 0.0f ) ); 
                [__greeLeaderboard.view setFrame:CGRectMake(0, 0, 480, 320)];
                __greeLeaderboard.view.center=ccp(240,160);
                __greeLeaderboard.view.alpha=1;
            
                /*
                
                [NSTimer timerWithInterval:0.05 andBlock:^(NSTimer* _tmr){
                    if (__greeLeaderboard.view.alpha<1)
                    {
                        __greeLeaderboard.view.alpha+=0.1;
                    } else
                    {
                        [_tmr invalidate];
                        __glView.alpha=1.0;                        
                        [__glView setExclusiveTouch:NO];
                    }
                }];
                // */
            }];
             
        }
    }];

    
}


-(void) dealloc{
    
    [greeRootController release];
    [super dealloc];
}

/*--------------------------------------------------
 Conform to GreePlatformDelegate
 --------------------------------------------------*/


-(void) greePlatformWillShowModalView:(GreePlatform *)platform
{
    NSLog(@"greePlatformWillShowModalView:(GreePlatform *)platform");
    
}

-(void) greePlatformDidDismissModalView:(GreePlatform *)platform
{
    NSLog(@"greePlatformDidDismissModalView:(GreePlatform *)platform");
    
}

-(void) greePlatform:(GreePlatform *)platform didLoginUser:(GreeUser *)localUser
{
    isAuthenticated=YES;
    [self updateTotalScore];
    NSLog(@"greePlatform:(GreePlatform *)platform didLoginUser:(GreeUser *)localUser");
}

-(void) greePlatform:(GreePlatform *)platform didLogoutUser:(GreeUser *)localUser
{
    isAuthenticated=NO;
    NSLog(@"greePlatform:(GreePlatform *)platform didLogoutUser:(GreeUser *)localUser");
}

-(void) greePlatformParamsReceived:(NSDictionary *)params
{
    NSLog(@"greePlatformParamsReceived:(NSDictionary *)params");
}

@end
