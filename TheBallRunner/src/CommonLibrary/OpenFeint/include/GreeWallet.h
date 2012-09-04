//
// Copyright 2011 GREE, Inc.
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
/**
 * @file GreeWallet.h
 * GreeWallet class
 */

#import <UIKit/UIKit.h>
#import "GreeWalletPaymentItem.h"

/**
 * @brief Protocol methods to notify events for opening/closing GreeWallet's popup dialogs.
 */
@protocol GreeWalletDelegate <NSObject>
@optional
/**
 * @brief Called when popup dialogs for buying coins are opened.
 */
- (void)walletDepositDidLaunchPopup;
/**
 * @brief Called when popup dialogs for buying coins are closed.
 */
- (void)walletDepositDidDismissPopup;
/**
 * @brief Called when popup dialogs for IAP purchase history.
 */
- (void)walletDepositDidLaunchHistoryPopup;
/**
 * @brief Called when popup dialogs for IAP purchase history.
 */
- (void)walletDepositDidDismissHistoryPopup;
/**
 * @brief Called when popup dialogs for purchasing items are opened.
 */
- (void)walletPaymentDidLaunchPopup;
/**
 * @brief Called when popup dialogs for purchasing items are closed.
 */
- (void)walletPaymentDidDismissPopup;
@end

/**
 * @brief Class for buying app-specific currency and purchasing virtual items with app-specific currency.
 * 
 * This class provides 2 APIs, buying app-specific currency and another one is purchasing virtual items with app-specific currency. Results of these APIs can be fetched by using delegate method or blocks.
 */
@interface GreeWallet : NSObject
/**
 * @brief Set the delegate
 */
+(void)setDelegate:(id<GreeWalletDelegate>)delegate;

/**
 * @brief Launching a popup dialog for showing App-Specific currency store
 */
+ (void)launchDepositPopup;
/**
 * @brief Launching a popup dialog for showing App-Specific currency purchase history
 */
+ (void)launchDepositHistoryPopup;

/**
 * @brief API for purchasing virtual items.
 * @param items Array of GreeWalletPaymentItem objects
 * @param message  optional message that is shown above.
 * @param successBlock Block that is executed when succeeded to purchase items.
 * @param failureBlock Block that is executed when failed to purchase items.
 */
+ (void)paymentWithItems:(NSMutableArray*)items
    message:(NSString*)message
    callbackUrl:(NSString*)callbackUrl
    successBlock:(void(^)(NSString* paymentId, NSArray* items))successBlock
    failureBlock:(void(^)(NSString* paymentId, NSArray* items, NSError* error))failureBlock;

/**
 * @brief Get result of virtual item purchasing.
 * @param paymentId This is a transaction ID for the purchasing.
 * @param successBlock Block that is executed when succeeded to receive transaction results from server.
 * @param failureBlock Block that is executed when failed to receive transaction results from server.
 * @see paymentWithItems:callbackUrl:successBlock:failureBlock:
 * 
 * When failureBlock is executed by getting network error from paymentWithItems:callbackUrl:successBlock:failureBlock, there is a possibility that the transaction has been done successfully on server side.
 * For this situation, you can verify the transaction result by using this method.
 */
+ (void)paymentVerifyWithPaymentId:(NSString*)paymentId
    successBlock:(void(^)(NSString* paymentId, NSArray* items))successBlock
    failureBlock:(void(^)(NSString* paymentId, NSArray* items, NSError* error))failureBlock;

@end
