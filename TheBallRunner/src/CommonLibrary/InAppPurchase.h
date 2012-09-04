//
//  InAppPurchase.h
//  UnderTheSea
//
//  Created by User on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
@class Encryptor;


//==================================================
@protocol InAppPurchaseDelegate <NSObject>
@required
/*
 Delegate process ui to confirm the purchase request
 */
-(void) askConfirm:(NSString *)name;

-(void) onSuccess:(NSString*)name;
-(void) onFailed;
@end



//==================================================
/*
 Connect and process purchase with iTunes.
 Type of product :
    Consumable : each device each user
    Non-consumable : for user 
 
    Auto-renewal subscription : auto-new the purchase for user
    Free subscription : for newstand-enabled-app only
    Non-renewing subscription : app manually re-new the purchase , include consumable feature
 */

#define LOCK_NAME @"lockData"
#define LOCK_KEY @"PopS W0r1dwiDe" //key used to decrypt lockData
#define PRODUCT_LISTNAME @"Products.plist"

@interface InAppPurchase : NSObject<SKProductsRequestDelegate,SKPaymentTransactionObserver>
{
    Encryptor *encryptor;
    NSUserDefaults *preference;
    
    NSString *pathLock;
    NSStringEncoding encoding;
    
    
    //lockData present the locking state of level and solution
    //follow syntax :
    //    "level{unlocked-id1},level{unlocked-id2},{...},solution{unlocked-id1},solution{unlocked-id2},{...}"
    //within :
    //  unlocked-id? : the id of level-or-solution which be unlocked
    //  level-name prefixed by "level"
    //  solution-name prefixed by "solution"
    NSString *lockData; 
    NSMutableArray *arrUnLocking;
    
    NSMutableDictionary *dictIds; // name=>id
    NSMutableDictionary *dictNames ; // id=>name
    NSMutableDictionary *dictProducts; // id=>SKProduct
    
    NSString *purchasingId;
    
    SKProductsRequest *req;
    
}

@property (retain,nonatomic) id<InAppPurchaseDelegate> delegate;
@property BOOL isPurchasing; //indicate that purchase in progress


//Overloaded initial 
//Load initial lockData from preference
//    in-case no lockData found, reset it from config file within name 
-(id) initWithFile:(NSString*)name;

-(id) initForceWithFile:(NSString *)name;

//Get the apple-identifier of content-or-feature name
//@name : name of content-or-feature
- (NSString*) getIdentifier:(NSString*) name;


//Get detail purchase of Product 
//@name : name of content-or-feature , which point to product in apple-store
//@return : SKProduct object
- (SKProduct *) getProductDetail:(NSString*)name;


//Lock and unlock the name in application
//Use name as an identifier of extra-require-purchase content or feature
//@name : name of content-or-feature
- (void) lockName:(NSString *)name; 
- (void) unlockName:(NSString*) name;


//Test if name is locked , see lockName descryption
//@name : name of content-or-feature
- (BOOL) isNameLocked:(NSString*) name;


//Process the purchase
//@identifier : product identifier
//
//#askPurchase_confirm : when user confirm the purchase
//#askPurchase_cancel : or cancel
- (void) askPurchase:(NSString *) identifier;
- (void) restorePurchase:(NSString *) identifier;

- (void) askPurchase_confirm;
- (void) askPurchase_cancel;

//Process the purchase
//@name : name of content-or-feature, which used to defer identifier
- (void) askPurchaseByName:(NSString *) name;
- (void) restorePurchaseByName:(NSString*)name;

//Process response to the transaction state update : completed/failed/restored
//@ transaction : current considering transaction 
- (void) completedTransaction:(SKPaymentTransaction *)transaction;
- (void) failedTransaction:(SKPaymentTransaction *)transaction;
- (void) restoredTransaction:(SKPaymentTransaction *)transaction;
@end

