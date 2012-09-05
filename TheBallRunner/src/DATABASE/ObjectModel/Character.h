//
//  Character.h
//  UnderTheSea
//
//  Created by hung.huynh on 5/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Character : NSObject

@property (nonatomic, retain) NSString *decription;
@property (nonatomic, retain) NSString *nameCharacter;
@property (nonatomic, retain) NSString *imageCharacter;

-(void)setValueDictionary:(NSDictionary*)dic;

@end
