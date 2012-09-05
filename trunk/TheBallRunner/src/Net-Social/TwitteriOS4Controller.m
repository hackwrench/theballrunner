//
//  TwitteriOS4Controller.m
//  escp
//
//  Created by nam trnam on 4/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TwitteriOS4Controller.h"
#import "cocos2d.h"
#import "Categories.h"

@implementation TwitteriOS4Controller

-(id)initTwitterControllerWithDefault {
    self = [super init];
    return self;
}

-(void)setTwitteriOS4Controller:(UIViewController*)_handler withNSDictionary:(NSMutableDictionary*)_dic andDelegate:(id<TwitteriOS4Delegate>)delg {
    handler = _handler;
    data = [_dic retain];
    delegate=delg;
    [self twiteLinkOfArticleToWall];
}

-(void) tweet
{
    NSString *msg=[data objectForKey:@"msg"];
    if (msg==nil) msg=@"Null tweet";
    [_engine sendUpdate:msg];        
}

-(void)twiteLinkOfArticleToWall {
	_engine = [[SA_OAuthTwitterEngine alloc] initOAuthWithDelegate:self];
	_engine.consumerKey = @"5VZi3dzTCrLDUw3Xy7QyA";
	_engine.consumerSecret = @"gBKPSgYiLxMHZ0G3DR8yMfiFCsYoQUiNcIzBSLLw";
    
	UIViewController *controller = [SA_OAuthTwitterController controllerToEnterCredentialsWithTwitterEngine: _engine delegate: self];    
    
    __block UIViewController *__controller=controller;    
    __controller.view.transform=CGAffineTransformMakeRotation( CC_DEGREES_TO_RADIANS( 0.0f ) ); 

	if (controller) 
		[handler presentViewController:controller animated:NO completion:^(void){
            __controller.view.transform=CGAffineTransformMakeRotation( CC_DEGREES_TO_RADIANS( 0.0f));
            [__controller.view setFrame:CGRectMake(0, 0, 480, 320)];
            __controller.view.center=ccp(240,160);
        }];
	else {
		tweets = [[NSMutableArray alloc] init];
        [self tweet];
	}
	
}


- (void) storeCachedTwitterOAuthData: (NSString *) data forUsername: (NSString *) username {
	
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setObject: data forKey: @"authData"];
	[defaults synchronize];
}

- (NSString *) cachedTwitterOAuthDataForUsername: (NSString *) username {
	
	return [[NSUserDefaults standardUserDefaults] objectForKey: @"authData"];
}

#pragma mark SA_OAuthTwitterController Delegate

- (void) OAuthTwitterController: (SA_OAuthTwitterController *) controller authenticatedWithUsername: (NSString *) username {
	
	NSLog(@"Authenticated with user %@", username);
	
	tweets = [[NSMutableArray alloc] init];
	[self tweet];

}

- (void) OAuthTwitterControllerFailed: (SA_OAuthTwitterController *) controller {
	
	NSLog(@"Authentication Failure");
    [delegate requestFailed:@"Cancel" withError:nil];
}

- (void) OAuthTwitterControllerCanceled: (SA_OAuthTwitterController *) controller {
	
    [delegate requestFailed:@"Cancel" withError:nil];    
	NSLog(@"Authentication Canceled");
}

#pragma mark MGTwitterEngineDelegate Methods

- (void)requestSucceeded:(NSString *)connectionIdentifier {
	NSLog(@"Request Suceeded: %@", connectionIdentifier);
    [delegate requestSucceeded:connectionIdentifier];    
}

- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
    [delegate requestFailed:connectionIdentifier withError:error];
}



- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)connectionIdentifier {
	
	tweets = [[NSMutableArray alloc] init];
	
	for(NSDictionary *d in statuses) {
		
		NSLog(@"See dictionary: %@", d);
		
		
	}
	
	
}

- (void)receivedObject:(NSDictionary *)dictionary forRequest:(NSString *)connectionIdentifier {
	
	NSLog(@"Recieved Object: %@", dictionary);
}

- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)connectionIdentifier {
	
	NSLog(@"Direct Messages Received: %@", messages);
}

- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)connectionIdentifier {
	
	NSLog(@"User Info Received: %@", userInfo);
}

- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)connectionIdentifier {
	
	NSLog(@"Misc Info Received: %@", miscInfo);
}





-(void)dealloc{
    [data release];
	[_engine release];
	[tweets release];

    [super dealloc];
}

@end
