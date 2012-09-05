//
//  GameGui.h
//  GamePOPs
//
//  Created by hung.huynh on 3/14/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface GameGui : CCNode 
{
    
}

@property  int score;
@property  int times;
@property  int pearls;
@property  ccColor3B color;
@property  int timeChallenge; 
@property  BOOL isSolutionPlay;

//Time Game : 
-(int) getTimes;
-(void) increaseTime;

//Pearls of Player : 
-(int) getPearls;
-(void) increasePearls;

//Color menu : 
-(ccColor3B) getColor;
-(int) getScore;
-(void)resetScore;




@end
