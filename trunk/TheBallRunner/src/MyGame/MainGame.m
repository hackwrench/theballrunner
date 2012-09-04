//
//  MainGame.m
//  TheBallRunner
//
//  Created by Thi Huynh on 8/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MainGame.h"

@implementation MainGame

static MainGame* mainGame;


/************************************************
 *Name: get game proxy Instance
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
            
        default:
            break;
    }
}


@end
