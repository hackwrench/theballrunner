//
//  Level.m
//

#import "Level.h"
#import "MainGame.h"
#import "InAppPurchase.h"

@implementation Level

// Synthesize variables
@synthesize name;
@synthesize number;
@synthesize unlocked;
@synthesize stars;
@synthesize data,score;
@synthesize time;
@synthesize isSolutionUnlocked;


-(id)initLevelWith{
    self = [super init];
    return self;
}

-(void)setValueDictionary:(NSDictionary*)dic {
    name = [[dic valueForKey:@"name"] retain ];
    number = [[dic valueForKey:@"ID"] intValue];
    
    //ask InAppPurchase about locking state of level
    unlocked=![[MainGame sharedPurchase] isNameLocked:[NSString stringWithFormat:@"level%d",self.number]];
    isSolutionUnlocked=![[MainGame sharedPurchase] isNameLocked:[NSString stringWithFormat:@"solution%d",self.number]];
    
    //self.unlocked = [[dic valueForKey:@"unlocked"] intValue];
    stars = [[dic valueForKey:@"star"] intValue];
    data = [[dic valueForKey:@"map"] retain];
    score = [[dic valueForKey:@"score"] intValue];
    
    time = [[dic valueForKey:@"time"] intValue];
    NSLog(@"time dataaccess = %d",time);
}

- (void) dealloc
{
    [name release];
    [data release];
    
    [super dealloc];
}
@end