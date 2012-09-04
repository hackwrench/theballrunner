//
//  FacebookShare.m
//  UnderTheSea
//
//  Created by User on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "FacebookShare.h"

#import "Facebook.h"
#import "MainGame.h"
#import "UIAlertView+Block.h"

@implementation FacebookShare

-(id) init
{
    self=[super init];
    
    img=nil;
    msg=nil;
    
    return self;
}

-(CCMenu*) getButton
{
    __block FacebookShare* __self=self;
    CCMenuItemImage *bt=[CCMenuItemImage itemFromNormalImage:FB_IMG selectedImage:nil block:^(id sender){
        
        [[[CCDirector sharedDirector] openGLView] setAlpha:0.7];
        [[[CCDirector sharedDirector] openGLView] setExclusiveTouch:YES];        
        
        CCMenuItemImage *this=(CCMenuItemImage*)sender;
        
        __block CCMenuItemImage * __this=this;
        
        if ([(NSString*)[this userData] isEqualToString:@"IsShared=true"]) 
        {
            UIAlertView *alert=[UIAlertView alertViewWithOKCancel:@"Share Facebook" :@"You have made the share, do you want to continue ?" onOK:^(void){
                //take screenshot and make it as share-img
                UIImage *screenshot = [MainGame  screenShotUIImageWith:CCDeviceOrientationPortrait];
                
                [__self shareImg:screenshot onSuccess:^(void){
                    [__this setUserData:@"IsShared=true"];
                    
                    [[[CCDirector sharedDirector] openGLView] setAlpha:1.0];                
                    [[[CCDirector sharedDirector] openGLView] setExclusiveTouch:NO];        
                    
                } onFailed:^(void){                    
                    UIAlertView *alert=[UIAlertView alertViewWithOK:@"Share Facebook" :@"Cannot make the share now,please try again later" onOK:nil];
                    [alert show];
                    [[[CCDirector sharedDirector] openGLView] setAlpha:1.0];                    
                    [[[CCDirector sharedDirector] openGLView] setExclusiveTouch:NO];                                   
                }];        
                [__self commit];
                
            } onCancel:^(void){
                [[[CCDirector sharedDirector] openGLView] setAlpha:1.0];                
                [[[CCDirector sharedDirector] openGLView] setExclusiveTouch:NO];  
                return;
            }];            
            [alert show];
        }
        else {
            //take screenshot and make it as share-img
            UIImage *screenshot = [MainGame  screenShotUIImageWith:CCDeviceOrientationPortrait];
            
            [__self shareImg:screenshot onSuccess:^(void){
                [__this setUserData:@"IsShared=true"];
                
                [[[CCDirector sharedDirector] openGLView] setAlpha:1.0];                
                [[[CCDirector sharedDirector] openGLView] setExclusiveTouch:NO];        
                
            } onFailed:^(void){
                
                UIAlertView *alert=[UIAlertView alertViewWithOK:@"Share Facebook" :@"Cannot make the share now,please try again later" onOK:nil];
                [alert show];
                [[[CCDirector sharedDirector] openGLView] setAlpha:1.0];                    
                [[[CCDirector sharedDirector] openGLView] setExclusiveTouch:NO];                                               
            }];
           
            [__self commit];
            
        }
    }];
    
    [bt setUserData:@"IsShared=false"];
    CCMenu *mn=[CCMenu menuWithItems:bt, nil];
    return mn;
}

-(BOOL) logInWithUserName:(NSString*)name andPassword:(NSString*)pass
{
    return true;
}

-(void) shareMsg:(NSString*)_msg onSuccess:(void(^)(void))_onSuccess onFailed:(void(^)(void))_onFailed  
{
    [msg release];
    [onSuccess release];
    [onFailed release];
    
    msg=[_msg retain];
    onSuccess=[_onSuccess copy];
    onFailed=[_onFailed copy];
}


-(void) shareImg:(UIImage*)_img onSuccess:(void(^)(void))_onSuccess onFailed:(void(^)(void))_onFailed
{
    [img release];
    [onSuccess release];
    [onFailed release];
    
    img=[_img retain];
    onSuccess=[_onSuccess copy];
    onFailed=[_onFailed copy];    
}

-(void) commit
{
    //if (img==nil && msg==nil){
    [self faceBookLoginPushed:self];
        //return;
    //}

}

- (void) dealloc
{
    [userName release];
    [msg release];
    [img release];
    
    [facebook release];
    [super dealloc];
}

/*--------------------------------------------------
 CONFORM TO FACEBOOK DELEAGTEs
 --------------------------------------------------*/
- (BOOL) postImage
{
    //    // get information about the currently logged in user
    //    [facebook requestWithGraphPath:@"me" andDelegate:self];
    //    
    //    // get the posts made by the "platform" page
    //    [facebook requestWithGraphPath:@"platform/posts" andDelegate:self];
    //    
    //    // get the logged-in user's friends
    //    [facebook requestWithGraphPath:@"me/friends" andDelegate:self];
    
    UIImage *screenshot = [MainGame  screenShotUIImageWith:CCDeviceOrientationPortrait];
    NSString *savePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Screenshot.png"];
    [UIImagePNGRepresentation(screenshot) writeToFile:savePath atomically:YES];
    
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"Share on Facebook",  @"user_message_prompt",
                                   screenshot,@"message",nil];
    
    [facebook requestWithGraphPath:@"me/photos"
                         andParams:params
                     andHttpMethod:@"POST"
                       andDelegate:self];   
    
	return YES;
}


-(void)faceBookLoginPushed:(id)sender{
    if (facebook == nil) {
		facebook = [[Facebook alloc]initWithAppId:ID_APP_FB andDelegate:self];
	}	
	
	NSArray* permissions =  [[NSArray arrayWithObjects:
							  @"publish_stream", @"offline_access", nil] retain];
	
	[facebook authorize:permissions delegate:self];
    facebook.sessionDelegate = self;
}

-(void)faceBookLogoutPushed:(id)sender{
}

- (void)fbDidLogin{
    loggedIn = YES;
    //[message setString:@"login success..."];
    //[self postImage];
    
    if (img!=nil)
    {
        NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"Share on Facebook",  @"user_message_prompt",
                                       img,@"message",nil];
        
        [facebook requestWithGraphPath:@"me/photos" andParams:params
                         andHttpMethod:@"POST" andDelegate:self];  
        
        img=nil;
        
        return;
    }
    
    if (msg!=nil)
    {
        NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"Share on Facebook",  @"user_message_prompt",
                                       msg,  @"message", @"status",@"type", nil];
        
        //[facebook requestWithMethodName:@"stream.publish" andParams:params andHttpMethod:@"POST" andDelegate:self];
        
        [facebook requestWithGraphPath:@"me/feed" andParams:params
                         andHttpMethod:@"POST" andDelegate:self];  
        
        msg=nil;
        return;
    }    
}

- (void)fbDidNotLogin:(BOOL)cancelled{
    if (onFailed!=nil) onFailed();
}

- (void)fbDidLogout{
    UIAlertView *ask=[[UIAlertView alloc] initWithTitle:@"Share Facebook" message:@"You logout facebook" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [ask show];
    [ask setDelegate:self];
}

/*
- (void)request:(FBRequest *)request didLoad:(id)result {
    //[message setString:@"Photo posted"];
    UIAlertView *ask=[[UIAlertView alloc] initWithTitle:@"Share Facebook" message:@"You posted success photo screen" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [ask show];
    [ask setDelegate:self];
    
}


- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    //[message setString:@"Error. Please try again."];
    UIAlertView *ask=[[UIAlertView alloc] initWithTitle:@"Share Facebook" message:@"Error, Please try again." delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [ask show];
    [ask setDelegate:self];
}*/


- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    if (onFailed!=nil) onFailed();
	NSLog(@"ResponseFailed: %@", error);
         
}

- (void)request:(FBRequest *)request didLoad:(id)result {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	NSLog(@"Parsed Response: %@", result);
}

-(void) request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response
{
    if (onSuccess!=nil) onSuccess();
}



@end
