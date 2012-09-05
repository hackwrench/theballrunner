//
//  Character.m
//  UnderTheSea
//
//  Created by hung.huynh on 5/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Character.h"

@implementation Character

@synthesize imageCharacter,nameCharacter,decription;

-(id)init
{
    self = [super init];
    return self;
}

-(void)setValueDictionary:(NSDictionary*)dic 
{
    nameCharacter   = [[dic valueForKey:@"name"] retain ];
    imageCharacter  = [[dic valueForKey:@"image"] retain];
    decription      = [[dic valueForKey:@"Decription"] retain];
    
    NSLog(@"Character name = %@ image = %@ decription = %@",nameCharacter,imageCharacter,decription);
}

@end
