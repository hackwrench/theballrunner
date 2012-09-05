//
//  GameGui.m
//  GamePOPs
//
//  Created by hung.huynh on 3/14/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "GameGui.h"


@implementation GameGui

@synthesize times = _times;
@synthesize score = _score;
@synthesize color = _color;
@synthesize pearls = _pearls;
@synthesize timeChallenge = _timeChallenge;
@synthesize isSolutionPlay=_isSolutionPlay;

//init GameGui : 
-(id) init
{
    self=[super init];
    if(self)
    {
        _score = 0;
        _times = 1;
        _timeChallenge = 0;
        _color = ccc3(0, 0, 0);
        _pearls = 0;
        _isSolutionPlay=NO;
    }
    
    return self;
}

//Get time of player : 
-(int) getTimes
{
    NSLog(@"times = %d",_times);
    return _times;
}

-(int) getTimeChallegen
{
    return _timeChallenge;
}

-(void) increaseTime
{
    _times++;
}

//Get Score : 
-(int) getScore
{
    _score = (_pearls+1)*1000;
    if (_times == 0) {
        _times = 1;
    }
    return _score/_times;
}

//Count pearls : 
-(void) increasePearls
{
    _pearls++;
}

//Get Pearl of Player : 
-(int) getPearls
{
    return _pearls;
}

//Get color current player : 
-(ccColor3B) getColor
{
    return _color;
}

//Reset level : 
-(void)resetScore
{
    _times = 1;
    _pearls = 0;
    _score = 0;
    _timeChallenge = 0;
    _isSolutionPlay=NO;
}

@end
