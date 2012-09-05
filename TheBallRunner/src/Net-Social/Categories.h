//
//  Categories.h
//  UnderTheSea
//
//  Created by User on 5/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "GameCenter.h"

//==========[cocos2d] CCMenu 
@interface CCMenu (Override)
-(void) alignItemsInColumns: (NSNumber *) columns vaList: (va_list) args;

@end


//==========GKLeaderboardViewController 

@interface GKLeaderboardViewController (Override) 

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
@end

//==========GKAchievementViewController 
@interface GKAchievementViewController (Override) 

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
@end

//==========CCTouchDispatcher
@interface CCTouchDispatcher (Override) 
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;

- (void)registerExclusive:(CCNode*)node;
- (void)unregisterExclusive;

@end


@interface CCMenuItemImage (Override)

-(id) initFromNormalImage: (NSString*) normalI selectedImage:(NSString*)selectedI disabledImage: (NSString*) disabledI target:(id)t selector:(SEL)sel;
@end


//==========NSTimer with Block
@interface TimerBlock : NSObject {
    void(^onExec)(NSTimer*);
}
-(id) initWithBlock:(void(^)(NSTimer*))_onExec;
-(void) execWithTimer:(NSTimer*)timer;
@end

@interface NSTimer (Override) 

+(id) timerWithTimeout:(float)seconds andBlock:(void(^)(NSTimer*))onTimeout;
+(id) timerWithInterval:(float)seconds andBlock:(void(^)(NSTimer*))onInterval;
@end



