//
//  MainGame.m
//  TheBallRunner
//
//  Created by Thi Huynh on 8/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MainGame.h"
#import "Test.h"


@implementation MainGame

static MainGame* mainGame;

#pragma mark - init section
/************************************************
 *Name: init main game
 *Return : self
 *
 *
 *
 *
 *
 ************************************************/
- (id)init
{
    self = [super init];
    if(self)
    {
        //TODO : init properties here
    }
    
    return self;
}

+ (id)alloc 
{
    @synchronized ([MainGame class])                            
    {
        NSAssert(mainGame == nil,
                 @"Attempted to allocated a second instance of the Main Game singleton"); 
        mainGame = [super alloc];
        return mainGame;                               
    }
    return nil;  
}
/************************************************
 *Name: get game proxy Instance(singleton)
 *Return : the only instance when app run
 *
 *
 *
 *
 *
 ************************************************/
+ (MainGame*)getInstance
{
    @synchronized([MainGame class])    
    {
        if(!mainGame)                                               
            [[self alloc] init]; 
        return mainGame;                                   
    }
    return nil; 
}

#pragma mark - method section
/************************************************
 *Name: get game proxy Instance
 *Return : the only instance when app run
 *
 *
 *
 *
 *
 ************************************************/
- (void)runScene:(enum EnumGameScene)scene
{
    switch (scene) {
        case EnumGamePlayScene:
            
            break;
        case EnumGameLevelSelectScene:
            
            break;
        case EnumGameMenuScene:
            
            break;
        case EnumGameOptionScene:
            
            break;
        case EnumGameFinishScene:
            
            break;
        case EnumGameHelpScene:
            
            break;
        case EnumGameTest:
            // Creates the view(s) and adds them to the director
            [[Isgl3dDirector sharedInstance] addView:[Test view]];
            // Run the director
            [[Isgl3dDirector sharedInstance] run];
            break;
            
        default:
            break;
    }
}


@end
