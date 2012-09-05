//
//  TwitterShare.m
//  UnderTheSea
//
//  Created by User on 5/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import <Twitter/TWRequest.h>
#import <Accounts/Accounts.h>
#import "TwitterShare.h"

#import "MainGame.h"
#import "UIAlertView+Block.h"
#import "Categories.h"
#import "Util.h"
#import "ResourceDef.h"
#import "TwitteriOS4Controller.h"


@implementation TwitterShare

-(id) init
{
    self=[super init];
    msg=nil;
    img=nil;
    return self;
}

-(CCMenu*) getButton
{
    __block TwitterShare* __self=self;
    CCMenuItemImage *bt=[CCMenuItemImage itemFromNormalImage:TWEET_IMG selectedImage:nil  block:^(id sender){

        [[[CCDirector sharedDirector] openGLView] setAlpha:0.7];
        [[[CCDirector sharedDirector] openGLView] setExclusiveTouch:YES];  
        
        CCMenuItemImage *this=(CCMenuItemImage*)sender;
        __block CCMenuItemImage * __this=this;
        
        if ([(NSString*)[this userData] isEqualToString:@"IsShared=true"]) 
        {
            UIAlertView *alert=[UIAlertView alertViewWithOKCancel:@"Share Twitter" :@"You have made the share, do you want to continue ?" onOK:^(void){
                
                //take screenshot and make it as share-img
                UIImage *screenshot = [MainGame  screenShotUIImageWith:CCDeviceOrientationPortrait];
                
                [__self shareImg:screenshot onSuccess:^(void){
                    [__this setUserData:@"IsShared=true"];
                    
                    [[[CCDirector sharedDirector] openGLView] setAlpha:1.0];                
                    [[[CCDirector sharedDirector] openGLView] setExclusiveTouch:NO];  
                } onFailed:^(void){
                    UIAlertView *alert=[UIAlertView alertViewWithOK:@"Share Twitter" :@"Cannot make the share now,please try again later" onOK:nil];
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
                UIAlertView *alert=[UIAlertView alertViewWithOK:@"Share Twitter" :@"Cannot make the share now,please try again later" onOK:nil];
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
    return;
}

-(void) shareImg:(UIImage*)_img onSuccess:(void(^)(void))_onSuccess onFailed:(void(^)(void))_onFailed
{
    [img release];
    [onSuccess release];
    [onFailed release];

    img=[_img retain];
    onSuccess=[_onSuccess copy];
    onFailed=[_onFailed copy];
    return;
}

-(void) commit
{
     BOOL isIOS5 = NSClassFromString(@"TWTweetComposeViewController")!=nil;          
     //isIOS5=false;
     if (isIOS5) [self commit2];
     else [self commitForIOS4];
}

-(void) commitForIOS4
{
    static NSMutableDictionary * blockPool__=nil;
    
    [blockPool__ release];
    blockPool__=[[NSMutableDictionary alloc] init ];
    
    NSLog(@"iOS 4.0");
    
    NSMutableDictionary *data=[NSMutableDictionary dictionary];
    UIViewController *handler=[[[UIViewController alloc] init] autorelease];
    
    [[[CCDirector sharedDirector] openGLView] addSubview:handler.view];
    [blockPool__ setObject:handler forKey:@"Handler"];
    
    //[handler.view setTransform:CGAffineTransformMakeRotation(CC_DEGREES_TO_RADIANS(0))];
    //[handler.view setFrame:CGRectMake(0, 0, 480, 320)];
    
    TwitteriOS4Controller* twitteriOS4Controller = [[TwitteriOS4Controller alloc]initTwitterControllerWithDefault];
    [twitteriOS4Controller autorelease];
    
    
    if (img!=nil) msg=@"RayConnect from http://pops.com.vn , available in AppStore";
    [data setObject:msg forKey:@"msg"];    
    
    [twitteriOS4Controller setTwitteriOS4Controller:handler withNSDictionary:data andDelegate:self];
    [blockPool__ setObject:twitteriOS4Controller forKey:@"Twitter"];    
}



-(void) commit2
{
    __block TwitterShare* __self=self;
    
    //  First, we need to obtain the account instance for the user's Twitter account
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    //  Request access from the user for access to his Twitter accounts
    [store requestAccessToAccountsWithType:twitterAccountType 
                     withCompletionHandler:^(BOOL granted, NSError *error) 
    {
        if (error)
        {
            UIAlertView *alert=[UIAlertView alertViewWithOK:@"Share Twitter" :@"Cannot  authenticate your account,please sign-in by Settings" onOK:^(void){}];
            [alert show];
            if (__self->onFailed!=nil) __self->onFailed();
            return;
        }
         if (!granted) {
             
             // The user rejected your request 
             NSLog(@"User rejected access.");
             UIAlertView *alert=[UIAlertView alertViewWithOK:@"Share Twitter" :@"You has rejected the share" onOK:^(void){}];
             if (__self->onFailed!=nil) __self->onFailed();
             [alert show];
         } 
         else {
             
             // Grab the available accounts
             NSArray *twitterAccounts = [store accountsWithAccountType:twitterAccountType];
             
             if ([twitterAccounts count] <1)
             {
                 UIAlertView *alert=[UIAlertView alertViewWithOK:@"Share Twitter" :@"Cannot  authenticate your account,please sign-in by Settings" onOK:^(void){
                 }];
                 [alert show];
                 if (onFailed!=nil) onFailed();
                 return;
             }    
             
             // Use the first account for simplicity 
             ACAccount *account = [twitterAccounts objectAtIndex:0];
             
             if (msg!=nil){
                 //make text tweet
                 NSURL *url = [NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.json"];
                 NSMutableDictionary *params=[NSMutableDictionary dictionaryWithObjectsAndKeys:msg,@"status", nil];
                 
                 TWRequest *request = [[TWRequest alloc] initWithURL:url 
                                                          parameters:params 
                                                       requestMethod:TWRequestMethodPOST];
                 [request setAccount:account];
                                  
                 [request performRequestWithHandler:
                  ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                      if (!responseData) {
                          if (__self->onFailed!=nil) __self->onFailed();
                          
                          // inspect the contents of error 
                          NSLog(@"%@", error.description);
                      } 
                      else {
                          NSError *jsonError;
                          NSDictionary *obj = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];            
                          
                          if ([obj objectForKey:@"id_str"]!=nil) {                          
                              // at this point, we have an object that we can parse
                              NSLog(@"%@", [obj objectForKey:@"id_str"]);
                              if (__self->onSuccess!=nil) __self->onSuccess();
                          } 
                          else { 
                              // inspect the contents of jsonError
                              NSLog(@"%@", jsonError);
                              if (__self->onFailed!=nil) __self->onFailed();
                          }
                      }
                  }];

             }
             else if (img!=nil)
             {
                 //make img tweet
                 NSURL *url = [NSURL URLWithString:@"https://upload.twitter.com/1/statuses/update_with_media.json"];
                 
                 TWRequest *request = [[TWRequest alloc] initWithURL:url 
                                                          parameters:nil 
                                                       requestMethod:TWRequestMethodPOST];                     
                 [request setAccount:account];                     
                 
                 NSData *data=UIImagePNGRepresentation(img);
                 [request addMultiPartData:data withName:@"media[]" 
                                      type:@"multipart/form-data"];

                 NSString *status=@"Image tweet";
                 [request addMultiPartData:[status dataUsingEncoding:NSUTF8StringEncoding] withName:@"status" type:@"multipart/form-data" ];                     
                 
   
                 [request performRequestWithHandler:
                  ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                      if (!responseData) {
                          // inspect the contents of error 
                          NSLog(@"[TWITTER] %@", error);
                          if (__self->onFailed!=nil)  __self->onFailed();
                      } 
                      else {
                          NSError *jsonError;
                          NSDictionary *obj = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];            
                          
                          if ([obj objectForKey:@"id_str"]!=nil) {                          
                              // at this point, we have an object that we can parse
                              NSLog(@"%@", [obj objectForKey:@"id_str"]);
                              if (__self->onSuccess!=nil) __self->onSuccess();
                          } 
                          else { 
                              // inspect the contents of jsonError
                              NSLog(@"[TWITTER-local] %@", jsonError);
                              if (__self->onFailed!=nil) __self->onFailed();
                          }
                      }
                  }];
             }
                                  
             
        } // if (granted) 
                    
    }];

}

//----------
// conform to TwitteriOS4Delegate
//----------
-(void) requestSucceeded:(NSString *)connectionIdentifier
{
    if (onSuccess!=nil) onSuccess();
}

-(void) requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
    if (onFailed!=nil) onFailed();
}
@end
