//
//  User.h
//  GamePOPs
//
//  Created by User on 3/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject{
}

@property (nonatomic, retain) NSString *userName;
@property (nonatomic, retain) NSString *score;
@property (nonatomic, retain) NSString *fbAcc;
@property (nonatomic, retain) NSString *gcAcc;
@property (nonatomic, retain) NSString *sound;
@property int playType;

-(id)initUserWith;
-(void)setValueDictionary:(NSDictionary*)dic;

@end
