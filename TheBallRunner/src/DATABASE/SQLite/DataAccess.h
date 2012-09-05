//
//  DataAccess.h
//  ZombieFarmPops
//
//  Created by Truong NAM on 2/10/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSSQLite.h"


@interface DataAccess : NSObject {
    NSString *writableDBPath;
	NSString *sql;
	NSSQLite *sqlite;
    
    NSMutableArray *userList;
    NSMutableArray *levelList;
    NSMutableArray *characterList;
}

-(id)initDataAccessWith;
-(BOOL)createEditableCopyOfDatabaseIfNeeded;
-(NSMutableArray*)getUserList;
-(NSMutableArray*)getLevelList;
-(NSMutableArray*)getCharacterList;

-(void)updateNewHighScoreWith:(NSString*)name forFB:(NSString*)fbAcc forGC:(NSString*)gcAcc;
-(void)updateLevel:(int)level forStar:(int)star forScore:(int)score;
-(void)updateSetting:(float)sound withPlayType:(int)type;
-(void)updateHighScore;
-(void)updateUnlock:(int)level;
-(int)getLastScores:(int)level;

@end
