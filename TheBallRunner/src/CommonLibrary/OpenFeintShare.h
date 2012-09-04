//
//  OpenFeintShare.h
//  UnderTheSea
//
//  Created by User on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define GREE_APPID                  @"14080"
#define GREE_LEADER_BOARD_ID        @"1045"

#define GREE_KEY                    @"50a006b2da43"
#define GREE_KEY_ENCRYPTED          @"4d840b430191e75b79113b8d232cc40d"
#define GREE_SECRET                 @"808c57e250956695cd2de15eab33c850"
#define GREE_SECRET_ENCRYPTED       @"777e8fa3ea5d4d16f79ed5b5cf6bc7876b05fb0a5db36a3f11c9b5ba3600a4d21143ba3e94fc9510ee37cf1ab1d918fb"
#define GREE_SCRAMBLE               @"POPS worldwide"


@class CCMenu;

@protocol GreePlatformDelegate; 

@interface OpenFeintShare : NSObject<GreePlatformDelegate>
{
    BOOL isAuthenticated;
    
    NSTimer *tmr;
    int tryShowCount;
    
    NSString* playerID;
    int currentScore;

    UIViewController *greeRootController;
    
    
}

//routes
//button to view openfeint leader board
-(void) authenticate;
-(CCMenu*) getButton;
-(int) getCurrentScore;
-(void) updateTotalScore;
-(void) commitTotalScore:(int)score;

//atoms
- (BOOL)isAuthenticated;
-(void) showLeaderBoard;

@end
