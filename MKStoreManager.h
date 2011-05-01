//
//  StoreManager.h
//  MKStoreKit (Version 3.5)
//
//  Created by Mugunth Kumar on 17-Nov-2010.
//  Version 3.5
//  Copyright 2010 Steinlogic. All rights reserved.
//	File created using Singleton XCode Template by Mugunth Kumar (http://mugunthkumar.com
//  Permission granted to do anything, commercial/non-commercial with this file apart from removing the line/URL above
//  Read my blog post at http://mk.sg/1m on how to use this code

//  As a side note on using this code, you might consider giving some credit to me by
//	1) linking my website from your app's website 
//	2) or crediting me inside the app's credits page 
//	3) or a tweet mentioning @mugunthkumar
//	4) A paypal donation to mugunth.kumar@gmail.com
//
//  A note on redistribution
//	While I'm ok with modifications to this source code, 
//	if you are re-publishing after editing, please retain the above copyright notices


#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "MKStoreObserver.h"

// CONFIGURATION STARTS -- Change this in your app
#define kSharedSecret @"749a1ca3750a421fa92cf8e139a6f539"

#define kReceiptStringKey @"MK_STOREKIT_RECEIPTS_STRING"

#ifndef NDEBUG
    #define kReceiptValidationURL @"https://sandbox.itunes.apple.com/verifyReceipt"
#else
    #define kReceiptValidationURL @"https://buy.itunes.apple.com/verifyReceipt"
#endif

#define SERVER_PRODUCT_MODEL 0
#define IAP_SUBSCRIPTIONS_MODEL 1
// CONFIGURATION ENDS -- Change this in your app

@protocol MKStoreKitDelegate <NSObject>
- (NSSet *) productIdentifiers;
// consumable features should have only number as the last part of the product name
// e.g. com.mycompany.myapp.coins.005 to purchase 5 coins
// If you follow this naming standard, MKStoreKit automatically keeps track of the 
// count of your consumable product

@optional
- (void)productFetchComplete;
- (void)productPurchased:(NSString *)productId;
- (void)restoreComplete;
- (void)transactionCanceled;
// as a matter of UX, don't show a "User Canceled transaction" alert view here
// use this only to "enable/disable your UI or hide your activity indicator view etc.,
@end

@interface MKStoreManager : NSObject<SKProductsRequestDelegate> {

	NSMutableArray *_purchasableObjects;
	MKStoreObserver *_storeObserver;
	
	BOOL isProductsAvailable;
    
    NSString *_latestReceiptString;
}

@property (nonatomic, retain) NSMutableArray *purchasableObjects;
@property (nonatomic, retain) MKStoreObserver *storeObserver;
@property (nonatomic, retain) NSString *latestReceiptString;

// These are the methods you will be using in your app
+ (MKStoreManager*)sharedManager;

// this is a static method, since it doesn't require the store manager to be initialized prior to calling
+ (BOOL) isFeaturePurchased:(NSString*) featureId; 

// these three are not static methods, since you have to initialize the store with your product ids before calling this function
- (void) buyFeature:(NSString*) featureId;
- (NSMutableArray*) purchasableObjectsDescription;
- (void) restorePreviousTransactions;
- (NSString*) verifySubscriptionReceipts;

- (BOOL) canConsumeProduct:(NSString*) productIdentifier quantity:(int) quantity;
- (BOOL) consumeProduct:(NSString*) productIdentifier quantity:(int) quantity;


//DELEGATES
+(id)delegate;	
+(void)setDelegate:(id)newDelegate;

@end
