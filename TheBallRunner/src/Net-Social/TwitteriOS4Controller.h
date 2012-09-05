//
//  TwitteriOS4Controller.h
//  escp
//
//  Created by nam trnam on 4/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SA_OAuthTwitterEngine.h"
#import "SA_OAuthTwitterController.h"

@protocol TwitteriOS4Delegate 
@required
- (void)requestSucceeded:(NSString *)connectionIdentifier;
- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error;
@end


@interface TwitteriOS4Controller : NSObject<SA_OAuthTwitterEngineDelegate, SA_OAuthTwitterControllerDelegate> {
	SA_OAuthTwitterEngine *_engine;
	NSMutableArray *tweets;
    UIViewController *handler;
    NSMutableDictionary *data;
    id<TwitteriOS4Delegate> delegate;
}

-(void)setTwitteriOS4Controller:(UIViewController*)_handler withNSDictionary:(NSMutableDictionary*)_dic andDelegate:(id<TwitteriOS4Delegate>)delg;
-(id)initTwitterControllerWithDefault;
-(void)twiteLinkOfArticleToWall;

-(void)tweet;

@end
