//
// Copyright 2010-2011 GREE, inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

//Delegate Method define for GreePlatform
@protocol GreeAuthorizationDelegate <NSObject>
//For update access token/secret before authorizeDidFinishWithLogin: method call
- (void)authorizeDidUpdateUserId:(NSString*)userId withToken:(NSString*)token withSecret:(NSString*)secret;
//Login or reAuthorize success
- (void)authorizeDidFinishWithLogin:(BOOL)blogin;
//Logout or when recieving 401
- (void)revokeDidFinish;
@end

@class GreeSettings;
@interface GreeAuthorization : NSObject
@property (nonatomic, readonly, getter=accessTokenData) NSString* accessToken;
@property (nonatomic, readonly, getter=accessTokenSecretData) NSString* accessTokenSecret;

//initialize
- (id)initWithConsumerKey:(NSString*)consumerKey 
    consumerSecret:(NSString*)consumerSecret
    settings:(GreeSettings*)settings
    delegate:(id<GreeAuthorizationDelegate>)delegate;

//authorize before login
- (void)authorize;

//revoke after logged in
- (void)revoke;

//When recieving 401 this is called
- (void)reAuthorize;

//When needed upgrade this is called
- (void)upgradeWithParams:(NSDictionary*)params
    successBlock:(void(^)(void))successBlock
    failureBlock:(void(^)(void))failureBlock;

//handling openURL
- (BOOL)handleOpenURL:(NSURL*)url;

//handling before authorize
- (BOOL)handleBeforeAuthorize:(NSString*)serviceString;

//check if finishing authorization
- (BOOL)isAuthorized;

//sharedInstance
+ (GreeAuthorization*)sharedInstance;

@end
