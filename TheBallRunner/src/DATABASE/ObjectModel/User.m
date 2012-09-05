//
//  User.m
//  GamePOPs
//
//  Created by QuanTran on 3/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "User.h"

@implementation User
@synthesize userName, score,fbAcc, gcAcc;
@synthesize sound, playType;

-(id)initUserWith {
    self = [super init];
    return self;
}

-(void)setValueDictionary:(NSDictionary*)dic {
    userName = [[dic valueForKey:@"user"] retain ];
    score = [[dic valueForKey:@"highscore"] retain ];
    fbAcc = [[dic valueForKey:@"fbaccount"] retain ];
    gcAcc = [[dic valueForKey:@"gcaccount"] retain ];
    sound = [[dic valueForKey:@"sound"] retain ];
    playType = [[dic valueForKey:@"playtype"] intValue];
}

- (void) dealloc
{
    [userName release];
    [score release];
    [fbAcc release];
    [gcAcc release];
    [sound release];
    
    [super dealloc];
}
@end
