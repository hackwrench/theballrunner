//
//  ShareFacebook.m
//  UnderTheSea
//
//  Created by hung.huynh on 4/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ShareFacebook.h"
#import "MainGame.h"

@implementation ShareFacebook

-(id)init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) 
    {
        loggedIn = NO;
        facebook = nil;
    }
    
    return self;
}

// Create Facebook button
-(void)createMenuFacebook:(id)layer withPos:(CGPoint)pos
{
    CCMenuItemSprite *fbLogin = [CCMenuItemSprite 
                                 itemFromNormalSprite:[CCSprite spriteWithFile:@"FBConnect.bundle/images/LoginNormal@2x.png"]                                                                   selectedSprite:[CCSprite spriteWithFile:@"FBConnect.bundle/images/LogoutPressed@2x.png"] target:self selector:@selector(faceBookLoginPushed:)];
    
    CCMenu *menu = [CCMenu menuWithItems:fbLogin, nil];
    menu.position = pos;
    [layer addChild:menu z:1];
}

#pragma mark - FACEBOOK 

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
    
    UIImage *screenshot = [MainGame screenShotUIImageWith:CCDeviceOrientationPortrait];
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
		facebook = [[Facebook alloc] initWithAppId:ID_APP_FB andDelegate:self];
	}	
	
	NSArray* permissions =  [[NSArray arrayWithObjects:
							  @"publish_stream", @"offline_access", nil] retain];
	
	[facebook authorize:permissions delegate:self];
    facebook.sessionDelegate = self;
}

-(void)faceBookLogoutPushed:(id)sender{
    [facebook logout:self];
}

- (void)fbDidLogin{
    loggedIn = YES;
    
    //Take Screen : 
    [self postImage];
    
}

- (void)fbDidNotLogin:(BOOL)cancelled{
    
}

- (void)fbDidLogout{
    loggedIn = NO; 
}

- (void) fbSessionInvalidated{
    
}

- (void) fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt
{
    
}

- (void)request:(FBRequest *)request didLoad:(id)result {
    //[message setString:@"Photo posted"];
    NSLog(@"dic post facebook");
}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error {
    //[message setString:@"Error. Please try again."];
}


@end
