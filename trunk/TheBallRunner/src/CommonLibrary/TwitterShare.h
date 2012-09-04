//
//  TwitterShare.h
//  UnderTheSea
//
//  Created by User on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UIImage;
@class CCMenu;
@protocol TwitteriOS4Delegate;

@interface TwitterShare : NSObject<TwitteriOS4Delegate>
{
    NSString *userName;
    
    NSString *msg;
    UIImage *img;
    void(^onSuccess)(void);
    void(^onFailed)(void);
}

+ (TwitterShare*) shared;

//routes
-(CCMenu*) getButton;
-(BOOL) logInWithUserName:(NSString*)name andPassword:(NSString*)pass;
-(void) shareMsg:(NSString*)msg onSuccess:(void(^)(void))_onSuccess onFailed:(void(^)(void))_onFailed  ;
-(void) shareImg:(UIImage*)img onSuccess:(void(^)(void))_onSuccess onFailed:(void(^)(void))_onFailed;
-(void) commit; //commit the share
-(void) commitForIOS4;
-(void) commit2; 

//atom


@end
