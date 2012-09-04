//
//  InAppPurchase.m
//  UnderTheSea
//
//  Created by User on 4/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "InAppPurchase.h"
#import "Encryptor.h"

#import "StoreKit/StoreKit.h"
#import "UIAlertView+Block.h"

#import "Categories.h"

@implementation InAppPurchase
@synthesize delegate;
@synthesize isPurchasing;

//--------------------------------------------------
-(id) initWithFile:(NSString*)name
{
    self=[super init];
    preference=[NSUserDefaults standardUserDefaults];    
    encryptor=[[Encryptor alloc] init];
    encoding=NSUTF8StringEncoding;
    pathLock=[[NSBundle mainBundle] pathForResource:name ofType:@""];
    
    dictProducts=[[NSMutableDictionary alloc] initWithCapacity:4];
    dictNames=[[NSMutableDictionary alloc] initWithCapacity:4];
    
    lockData=[preference stringForKey:LOCK_NAME];
    if (lockData==nil) 
    {
        //load lockData from file
        lockData=[NSString stringWithContentsOfFile:pathLock usedEncoding:&encoding error:nil];
        lockData=[encryptor encrypt:lockData :LOCK_KEY]; 
        [lockData writeToFile:pathLock atomically:YES encoding:encoding error:nil];        
        [preference setObject:lockData forKey:LOCK_NAME];
        [preference synchronize];        
    }
    
    NSString *actualData=[encryptor decrypt:lockData :LOCK_KEY];
    arrUnLocking=[[NSMutableArray arrayWithArray:[actualData componentsSeparatedByString:@","]] retain];
    
    //read Products.plist to get product-ids
    dictIds=[[NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:PRODUCT_LISTNAME ofType:@""]] retain];
    
    //create reverse dictionary
    for (NSString *k in dictIds.allKeys)
        [dictNames setObject:k forKey:[dictIds objectForKey:k]]; 
        
    //ask for product detail follow ids
    NSSet *setIds=[NSSet setWithArray:[dictIds allValues]];    
    req=[[SKProductsRequest alloc] initWithProductIdentifiers:setIds];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [req setDelegate:self];
    [req start];
        
    //register self as observer
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    return self;
}

//--------------------------------------------------
-(id) initForceWithFile:(NSString *)name
{
    preference=[NSUserDefaults standardUserDefaults];    
    [preference setObject:nil forKey:LOCK_NAME];
    [preference synchronize];   
    return [[InAppPurchase alloc] initWithFile:name];
}

//--------------------------------------------------
- (NSString*) getIdentifier:(NSString*) name
{
    return [dictIds objectForKey:name]; 
}

//--------------------------------------------------
- (SKProduct *) getProductDetail:(NSString*)name
{
    return [dictProducts objectForKey:[dictIds objectForKey:name]];
}


//--------------------------------------------------
- (void) lockName:(NSString *)name
{
    if ([self isNameLocked:name]) return;    
    
    [arrUnLocking removeObject:name];    
    NSString *src=@"";
    for (NSString *n in arrUnLocking)
        src=[NSString stringWithFormat:@"%@,%@",src,n];
    lockData=[encryptor encrypt:src :LOCK_KEY];   
    [preference setObject:lockData forKey:LOCK_NAME];
    [preference synchronize];     
    //[lockData writeToFile:pathLock atomically:YES encoding:encoding error:nil];        
}

//--------------------------------------------------
- (void) unlockName:(NSString*) name
{
    if (![self isNameLocked:name]) return;
    
    [arrUnLocking addObject:name];    
    NSString *src=@"";
    for (NSString *n in arrUnLocking)
        src=[NSString stringWithFormat:@"%@,%@",src,n];
    lockData=[encryptor encrypt:src :LOCK_KEY];
    [preference setObject:lockData forKey:LOCK_NAME];
    [preference synchronize];     
    //[lockData writeToFile:pathLock atomically:YES encoding:encoding error:nil];    
}

//--------------------------------------------------
- (BOOL) isNameLocked:(NSString*) name
{
    return ![arrUnLocking containsObject:name];
}

//--------------------------------------------------
- (void) askPurchase:(NSString *) identifier
{
    // identifier must not nil    
    if (identifier==nil || dictProducts.count<1)
    {
        __block id<InAppPurchaseDelegate> __delegate=delegate;
        UIAlertView *alert=[UIAlertView alertViewWithOK:@"InAppPurchase" :@"Cannot process this purchase now,please try again later !" onOK:^(void){
            [__delegate onFailed];        
        }];
        [alert show];        
        
        //make product request again
        [req release];        
        NSSet *setIds=[NSSet setWithArray:[dictIds allValues]];    
        req=[[SKProductsRequest alloc] initWithProductIdentifiers:setIds];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [req setDelegate:self];
        [req start];
        
        return;
    }
    
    if (delegate==nil) return;
  
#if TARGET_IPHONE_SIMULATOR    
#else
    //check if purchase is allowed
    if (![SKPaymentQueue canMakePayments])
    {
        __block id<InAppPurchaseDelegate> __delegate=delegate;
        UIAlertView *alert=[UIAlertView alertViewWithOK:@"InAppPurchase" :@"Cannot process this purchase now,please try again later !" onOK:^(void){
            [__delegate onFailed];        
        }];
        [alert show];
        
        return;
    }
#endif
    
    //ask user for purchase confirm
    purchasingId=identifier;
    [delegate askConfirm:[dictNames objectForKey:purchasingId]];
}

- (void) restorePurchase:(NSString *) identifier
{
    purchasingId=identifier;
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

//--------------------------------------------------
- (void) askPurchase_confirm
{
    if (purchasingId==nil) return;
    
    //process the purchase within purchasing id
#if TARGET_IPHONE_SIMULATOR_X
    //simulator dont support in-app-purchase 
    //, so suppose the success state of this purchase
    
    //unlock the content-or-feature by name
    NSString *name=[dictNames objectForKey:purchasingId];
    [self unlockName:name];
    
    //tell delegate all done
    [delegate onSuccess:name];
    
#else
    //for test
    //unlock the content-or-feature by name
    //NSString *name=[dictNames objectForKey:purchasingId];
    //[self unlockName:name];
    
    //tell delegate all done
    //[delegate onSuccess:name];
    
    isPurchasing=YES;
    
    //add payment to queue
    SKPayment *payment = [SKPayment paymentWithProduct:[dictProducts objectForKey:purchasingId]];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
#endif
    
    
}

//--------------------------------------------------
- (void) askPurchase_cancel
{
    
}


//--------------------------------------------------
- (void) askPurchaseByName:(NSString *) name
{
    [self askPurchase:[self getIdentifier:name]];
}

- (void) restorePurchaseByName:(NSString*)name 
{
    [self restorePurchase:[self getIdentifier:name]];
}

//--------------------------------------------------
- (void) completedTransaction:(SKPaymentTransaction *)transaction
{
    //finish transaction
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    //support single purchase-in-time
    if ([transaction.payment.productIdentifier isEqualToString:purchasingId])
    {
        //unlock the content-or-feature by name
        NSString *name=[dictNames objectForKey:purchasingId];
        [self unlockName:name];
        
        //tell delegate all done
        [delegate onSuccess:name];
        
        isPurchasing=NO;
    }
    
    
}

//--------------------------------------------------
- (void) failedTransaction:(SKPaymentTransaction *)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    if ([transaction.payment.productIdentifier isEqualToString:purchasingId])
    {
        [delegate onFailed];
        
        isPurchasing=NO;
        
    }
}

//--------------------------------------------------
- (void) restoredTransaction:(SKPaymentTransaction *)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    if ([transaction.originalTransaction.payment.productIdentifier isEqualToString:purchasingId])
    {
        //unlock the content-or-feature by name
        NSString *name=[dictNames objectForKey:purchasingId];
        [self unlockName:name];
        
        //tell delegate all done
        [delegate onSuccess:name];
    }
}

-(void) dealloc
{
    [req release];
    [super dealloc];
}

/*==================================================
 Conform to SKProductRequestDelegate
 ==================================================*/
- (void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{    
    [dictProducts removeAllObjects];
    if (response.invalidProductIdentifiers.count>0) return;
    
    for (SKProduct *product in response.products)
    {        
        [dictProducts setObject:product forKey:product.productIdentifier];    
    }
}



/*==================================================
 Conform to SKPaymentTransactionObserver
 ==================================================*/

- (void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completedTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            //if product type is non-consumable , 
            //  its purchase will be auto-restored,conform the restore attemp for user
            case SKPaymentTransactionStateRestored:
                [self restoredTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

- (void) paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    NSLog(@"%@",error.description);
    isPurchasing=NO;
    [delegate onFailed];    
}



@end


