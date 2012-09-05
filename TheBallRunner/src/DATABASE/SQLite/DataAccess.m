//
//  DataAccess.m
//  ZombieFarmPops
//
//  Created by Truong NAM on 2/10/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "DataAccess.h"
#import "User.h"
#import "Level.h"
#import "Character.h"

@implementation DataAccess

-(id)initDataAccessWith {
    self = [super init];
    
    if (![self createEditableCopyOfDatabaseIfNeeded])
		return nil; 
    
	sqlite = [[NSSQLite alloc] init];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"Database"];
	if (![sqlite open:writableDBPath])
		return nil;
	
    //init user list
    userList=nil;
    levelList=nil;
    
	return self;
  
}

- (BOOL)createEditableCopyOfDatabaseIfNeeded  {
    /* First, test for existence.*/
    BOOL success;
            
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"Database"];
    success = [fileManager fileExistsAtPath:writableDBPath];
       
    if (success){ 
		return TRUE;
	}
    /* The writable database does not exist, so copy the default to the appropriate location.*/
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Database"];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
		return FALSE;
    }
	else
		return TRUE;
}

-(NSMutableArray*)getUserList{ 
    if (userList!=nil) return userList;
    
    NSMutableArray *array = [[NSMutableArray alloc]init];
    
    sql = [NSString stringWithFormat:@"select * from User"];
	NSArray *results = [sqlite executeQuery:sql];
	for (NSDictionary *dictionary in results) {
        User *user = [[[User alloc]initUserWith] autorelease];
        [user setValueDictionary:dictionary];
        [array addObject:user];
    }

    userList=array;  
    return array;    
}

//get level from database : 
-(NSMutableArray*) getLevelList{
    if (levelList!=nil) return levelList;
    
    
    NSMutableArray *array = [NSMutableArray array];
    
    sql = [NSString stringWithFormat:@"select * from Level"];
	NSArray *results = [sqlite executeQuery:sql];
   // NSLog(@"results = %@",results);
    
	for (NSDictionary *dictionary in results) {
        Level *level = [[[Level alloc] initLevelWith] autorelease];
        [level setValueDictionary:dictionary];
        [array addObject:level];
    }

    levelList = [array retain];
    return array;
}

//get character from database :
-(NSMutableArray*)getCharacterList
{
    if (characterList!=nil) return characterList;
    
    NSMutableArray *array = [[NSMutableArray alloc]init];
    
    sql = [NSString stringWithFormat:@"select * from Character"];
	NSArray *results = [sqlite executeQuery:sql];
	for (NSDictionary *dictionary in results) {
        Character *character = [[[Character alloc] init] autorelease];
        [character setValueDictionary:dictionary];
        [array addObject:character];
    }
    
    characterList = array;  
    return array;    
}

//update score of user : 
-(void)updateNewHighScoreWith:(NSString*)name forFB:(NSString*)fbAcc forGC:(NSString*)gcAcc{
    NSString *userInfo = [NSString stringWithFormat:@"SELECT ID FROM User WHERE username='%@'",name];
    NSArray *userResults = [sqlite executeQuery:userInfo];
    NSString* userID;
    for(NSDictionary *dic in userResults){ 
        userID = [dic objectForKey:@"ID"];        
    }
    if ([userResults count]==0) {
        // Add new user
        NSString *insertQuery = [NSString stringWithFormat:@"INSERT INTO User (username, fbaccount, gcaccount) VALUES ('%@','%@','%@')", name, fbAcc,gcAcc];
        [sqlite executeNonQuery:insertQuery];
    }
    else{
        // Update a existing user    
        NSString *sumScore;
        NSString *sumQuery = [NSString stringWithFormat:@"SELECT SUM(score) AS scoreTotal FROM Level"];
        NSArray *results = [sqlite executeQuery:sumQuery];
        for(NSDictionary *dic in results){ 
            sumScore = [dic objectForKey:@"scoreTotal"];        
        }
        
        NSString *updateQuery = [NSString stringWithFormat:@"UPDATE User SET highscore='%@' WHERE username='%@'", sumScore, name];
        [sqlite executeNonQuery:updateQuery];
    }
    
    //reset userlist 
    [userList release];
    userList=nil;
}

-(void)updateHighScore{
    NSString *sumScore;
    NSString *sumQuery = [NSString stringWithFormat:@"SELECT SUM(score) AS scoreTotal FROM Level"];
    NSArray *results = [sqlite executeQuery:sumQuery];
    for(NSDictionary *dic in results){ 
        sumScore = [dic objectForKey:@"scoreTotal"];        
    }
    
    NSString *updateQuery = [NSString stringWithFormat:@"UPDATE User SET highscore='%@'", sumScore];
    [sqlite executeNonQuery:updateQuery];
    
    //reset userlist 
    [userList release];
    userList=nil;
}

-(int)getLastScores:(int)level
{
    NSString *levelScore = [NSString stringWithFormat:@"SELECT score FROM Level WHERE ID='%i'",level];
    NSArray *levelResult = [sqlite executeQuery:levelScore];
    int oldScore;
    for(NSDictionary *dic in levelResult){ 
        oldScore = [[dic objectForKey:@"score"]intValue];        
    }
    return oldScore;
}

-(void)updateLevel:(int)level forStar:(int)star forScore:(int)score{
    NSString *levelScore = [NSString stringWithFormat:@"SELECT score FROM Level WHERE ID='%i'",level];
    NSArray *levelResult = [sqlite executeQuery:levelScore];
    int oldScore;
    for(NSDictionary *dic in levelResult){ 
        oldScore = [[dic objectForKey:@"score"]intValue];        
    }
    
    if(score < oldScore && oldScore != 0)
        return;
    
    NSString *updateQuery = [NSString stringWithFormat:@"UPDATE Level SET  star='%i',unlocked='1',score='%i' WHERE ID='%i'", star, score, level];
    [sqlite executeNonQuery:updateQuery];
    
    [levelList release];
    levelList=nil;
}

-(void)updateUnlock:(int)level{
    
    NSString *updateQuery = [NSString stringWithFormat:@"UPDATE Level SET  unlocked='1' WHERE ID='%i'",level];
    [sqlite executeNonQuery:updateQuery];
    
    [levelList release];
    levelList=nil;
}

-(void)updateSetting:(float)sound withPlayType:(int)type{
    NSString *updateQuery = [NSString stringWithFormat:@"UPDATE User SET sound='%f', playtype='%i'",sound,type];
    [sqlite executeNonQuery:updateQuery];
    
    //reset userlist 
    [userList release];
    userList=nil;
}

- (void) dealloc
{
    [sqlite release];
    [userList release];
    [levelList release];    
    
    [super dealloc];
    //[sql release];
    //[writableDBPath release];
    
}


@end
