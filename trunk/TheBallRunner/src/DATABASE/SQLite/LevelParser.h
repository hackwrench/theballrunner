//
//  LevelParser.h
//  MakeLevel
//
//  Created by User on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Levels;
#import "Level.h"

@interface LevelParser : NSObject <NSXMLParserDelegate>{
    NSString *currentElementValue;
    NSMutableArray *levels;
    //NSDictionary *levels;
    Level *aLevel;
}

- (NSMutableArray *)loadLevels;


@end
