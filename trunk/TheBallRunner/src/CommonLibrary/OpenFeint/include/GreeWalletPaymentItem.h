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
 * @file GreeWalletPaymentItem.h
 * GreeWalletPaymentItem class
 */

#import <Foundation/Foundation.h>
#import "GreeSerializable.h"

/**
 * @brief The class for purchasing virtual items with app-specific currency.
 * @see paymentWithItems:callbackUrl:successBlock:failureBlock:
 * 
 * To purchase items, set an array of virtual items that are going to be purchased in the first parameter.
 */
@interface GreeWalletPaymentItem : NSObject<GreeSerializable>

/**
 * @brief Item ID.
 */
@property (nonatomic, copy) NSString*	itemId;
/**
 * @brief Item name.
 */
@property (nonatomic, copy) NSString*	itemName;
/**
 * @brief Unit price.
 */
@property (nonatomic)	NSUInteger	unitPrice;
/**
 * @brief Item quantity.
 */
@property (nonatomic)	NSUInteger	quantity;
/**
 * @brief Thumbnail URL for the item.
 */
@property (nonatomic, copy)	NSString*	imageUrl;
/**
 * @brief Item description.
 */
@property (nonatomic, copy) NSString* description;

/**
 * @brief A method to create GreeWalletPaymentItem object.
 * @param itemId Item ID
 * @param itemName Item Name
 * @param unitPrice Item unit price
 * @param quantity Quantity
 * @param imageUrl Item thumbnail URL. Used to show an item image in purchase dialog.
 * @param description Item description.
 */
+ (GreeWalletPaymentItem*)paymentItemWithItemId:(NSString*)itemId 
    itemName:(NSString*)itemName 
    unitPrice:(NSUInteger)unitPrice
    quantity:(NSUInteger)quantity
    imageUrl:(NSString*)imageUrl
    description:(NSString*)description;

/**
 * @brief Showing description in string.
 */
- (NSString*)descriptionString;

@end
