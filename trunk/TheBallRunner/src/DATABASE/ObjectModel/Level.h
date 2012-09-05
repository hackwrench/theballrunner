//
//  Level.h
//

#import <Foundation/Foundation.h>

@interface Level : NSObject {

  
}

// Declare variable properties without an underscore
@property (nonatomic, retain) NSString *name;
@property int number;
@property int unlocked;
@property int stars;
@property int score;
@property int time;
@property (nonatomic, retain) NSString *data;
@property (nonatomic) BOOL isSolutionUnlocked;

-(id)initLevelWith;
-(void)setValueDictionary:(NSDictionary*)dic;
@end



/*
 [lockData default]
 level3,level4,level5,level6,level7,level8,solution3,solution4,solution5,solution6,solution7,solution8
 */