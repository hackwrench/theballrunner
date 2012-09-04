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
 * @file GreeError.h
 * Defines all publicly available error codes.
 */

#import <Foundation/Foundation.h>

/**
 * The NSError domain for all Gree-specific errors
 */
extern NSString* GreeErrorDomain;

enum {
/**
 * @brief A generic message for networking errors.  The request generally can not be fulfilled
 */
  GreeErrorCodeNetworkError = 1000,
/**
 * @brief Indicates that the server data was not understood, this usually means a networking error.
 */
  GreeErrorCodeBadDataFromServer = 1010,
/**
 * Indicates that the logged in user is not validated by the server.
 * A user type upgrade may be necessary
 */
  GreeErrorCodeNotAuthorized = 1020,
/**
 * @brief Indicates that the API requires a user and no local user was found
 */
  GreeErrorCodeUserRequired = 1030,
  
  /**
   @ref Shows that a communication error, etc. has occurred in a GreeWallet spending method.
   @see GreeWallet::paymentVerifyWithPaymentId:successBlock:failureBlock:
   */
  GreeWalletPaymentErrorCodeUnknown  = 2000,
  /**
   @ref Shows that the argument specified by a GreeWallet spending method is invalid.
   @see GreeWallet::paymentWithItems:message:callbackUrl:successBlock:failureBlock:
   @see GreeWallet::paymentVerifyWithPaymentId:successBlock:failureBlock:
   */
  GreeWalletPaymentErrorCodeInvalidParameter  = 2010,
  /**
   @ref Shows that a user has made a cancellation on the GreeWallet spending popup.
   */
  GreeWalletPaymentErrorCodeUserCanceled  = 2020,
  /**
   @ref Shows that a transaction on the GreeWallet spending popup has expired.
   */
  GreeWalletPaymentErrorCodeTransactionExpired  = 2030,

/**
 * @brief Indicates that this user already has a friend code
 */
  GreeFriendCodeAlreadyRegistered = 4000,
/**
 * @brief Indicates that this user has already used a friend code
 */
  GreeFriendCodeAlreadyEntered = 4010,
/**
 * @brief Indicates that no friend code could be found
 */
  GreeFriendCodeNotFound = 4020,

  
  GreeErrorCodeReservedBase = 10000
};

