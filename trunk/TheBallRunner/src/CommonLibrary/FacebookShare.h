//
//  FacebookShare.h
//  UnderTheSea
//
//  Created by User on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FBDialogDelegate;
@protocol FBRequestDelegate;
@protocol FBSessionDelegate;
@class Facebook;
@class CCMenu;

@interface FacebookShare : NSObject<FBDialogDelegate,FBRequestDelegate,FBSessionDelegate,UIAlertViewDelegate>
{
    NSString *userName;
    bool loggedIn;
    NSString *msg;
    UIImage *img;
    
    Facebook *facebook;
    void(^onSuccess)(void);
    void(^onFailed)(void);    
}

//routes
-(CCMenu*) getButton;
-(BOOL) logInWithUserName:(NSString*)name andPassword:(NSString*)pass;
-(void) shareMsg:(NSString*)msg onSuccess:(void(^)(void))_onSuccess onFailed:(void(^)(void))_onFailed  ;
-(void) shareImg:(UIImage*)img onSuccess:(void(^)(void))_onSuccess onFailed:(void(^)(void))_onFailed;
-(void) commit; //commit the share

//atoms
-(void)faceBookLoginPushed:(id)sender;
@end
