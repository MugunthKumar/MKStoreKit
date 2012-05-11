//
//  MKStoreObserver.m
//  MKStoreKit (Version 4.2)
//
//  Created by Mugunth Kumar on 17-Nov-2010.
//  Copyright 2010 Steinlogic. All rights reserved.
//
//  As a side note on using this code, you might consider giving some credit to me by
//	1) linking my website from your app's website 
//	2) or crediting me inside the app's credits page 
//	3) or a tweet mentioning @mugunthkumar
//	4) A paypal donation to mugunth.kumar@gmail.com
//
//  A note on redistribution
//	While I'm ok with modifications to this source code, 
//	if you are re-publishing after editing, please retain the above copyright notices

#import "MKStoreObserver.h"
#import "MKStoreManager.h"
#if ! __has_feature(objc_arc)
#error MKStoreKit is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

@interface MKStoreManager (InternalMethods)

// these three functions are called from MKStoreObserver
- (void) transactionCanceled: (SKPaymentTransaction *)transaction;
- (void) failedTransaction: (SKPaymentTransaction *)transaction;

- (void) provideContent: (NSString*) productIdentifier 
             forReceipt: (NSData*) recieptData;
@end

@implementation MKStoreObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	for (SKPaymentTransaction *transaction in transactions)
	{
		switch (transaction.transactionState)
		{
			case SKPaymentTransactionStatePurchased:
				
        [self completeTransaction:transaction];
				
        break;
				
      case SKPaymentTransactionStateFailed:
				
        [self failedTransaction:transaction];
				
        break;
				
      case SKPaymentTransactionStateRestored:
				
        [self restoreTransaction:transaction];
				
      default:
				
        break;
		}			
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
  [[MKStoreManager sharedManager] restoreFailedWithError:error];    
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue 
{
  [[MKStoreManager sharedManager] restoreCompleted];
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction
{	
	[[MKStoreManager sharedManager] transactionCanceled:transaction];
  [[SKPaymentQueue defaultQueue] finishTransaction: transaction];	
}

- (void) completeTransaction: (SKPaymentTransaction *)transaction
{			
#if TARGET_OS_IPHONE
  [[MKStoreManager sharedManager] provideContent:transaction.payment.productIdentifier 
                                      forReceipt:transaction.transactionReceipt];	
#elif TARGET_OS_MAC
  [[MKStoreManager sharedManager] provideContent:transaction.payment.productIdentifier 
                                      forReceipt:nil];	
#endif
  
  [[SKPaymentQueue defaultQueue] finishTransaction: transaction];	
}

- (void) restoreTransaction: (SKPaymentTransaction *)transaction
{	
#if TARGET_OS_IPHONE
  [[MKStoreManager sharedManager] provideContent: transaction.originalTransaction.payment.productIdentifier
                                      forReceipt:transaction.transactionReceipt];
#elif TARGET_OS_MAC
  [[MKStoreManager sharedManager] provideContent: transaction.originalTransaction.payment.productIdentifier
                                      forReceipt:nil];
#endif
	
  [[SKPaymentQueue defaultQueue] finishTransaction: transaction];	
}

@end
