//
// Copyright 2012 GREE, Inc.
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

#import "UIKit/UIKit.h"
#import "GreeEnumerator.h"

/**
 * @internal
 * @file GreeFriendCodes.h
 * GreeFriendCodes Interface
 */

/**
 * @internal
 * @brief The GreeFriendCodes interface encapsulates friend codes.  No instances of this class are created
 *
 */
@interface GreeFriendCodes : NSObject
/**
 * @brief Retrieve a new friend code for this user and application
 * @param block This block will get the code as a displayable string as well as any errors
 * If a friend code is already active, this will return error code GreeFriendCodeAlreadyRegistered
 *
 */
+ (void)requestCodeWithBlock:(void(^)(NSString* code, NSError* error)) block;

/**
 * @brief Retrieve a new friend code for this user and application, specifying an expiration time
 * @param expireTime An NSDate to use as the last date this code can be used.
 * @param block This block will get the code as a displayable string as well as any errors
 * If a friend code is already active, this will return error code GreeFriendCodeAlreadyRegistered
 */
+ (void)requestCodeWithExpireTime:(NSDate*) expireTime block:(void(^)(NSString* code, NSError* error)) block;

/**
 * @brief Try to verify a friend code
 * @param expireTime An NSDate to use as the last date this code can be used.
 * @param block If valid, this block will receive a nil value.
 * If the friend code was already used, error code GreeFriendCodeAlreadyEntered will be returned
 */
+ (void)verifyCode:(NSString*)code withBlock:(void(^)(NSError* error)) block;

/**
 * @brief Load your existing friend code
 * @param block This will receive the code and expiration time if any exists
 * If the friend code can't be found, error code GreeFriendCodeNotFound will be returned
 */
+ (void)loadCodeWithBlock:(void(^)(NSString* code, NSDate* expiration, NSError* error)) block;

/**
 * @brief Loads a list of friends who verified your code
 * @param block This receives an array of userIds and any errors
 */
+ (id<GreeEnumerator>)loadFriendsWithBlock:(void(^)(NSArray* friends, NSError* error)) block;

/**
 * @brief Load the userId that gave you the code
 * @param block This will receive the userId, if it exists and any errors
 * If no friend code can be found, error code GreeFriendCodeNotFound will be returned
 */
+ (void)loadCodeOwner:(void(^)(NSString* userId, NSError* error)) block;

/**
 * @brief Delete a code
 * @param block This will receive any errors, if there are none the code was deleted
 */
+ (void)deleteCodeWithBlock:(void(^)(NSError* error)) block;

@end
