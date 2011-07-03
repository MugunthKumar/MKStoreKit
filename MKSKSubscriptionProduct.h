//
//  MKSKSubscriptionProduct.h
//  MKStoreKitDemo
//  Version 4.0
//
//  Created by Mugunth on 03/07/11.
//  Copyright 2011 Steinlogic. All rights reserved.

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
#import "MKStoreManager.h"

@interface MKSKSubscriptionProduct : NSObject

@property (nonatomic, copy) void (^onSubscriptionVerificationFailed)();
@property (nonatomic, copy) void (^onSubscriptionVerificationCompleted)(NSNumber* isActive);
@property (nonatomic, retain) NSData *receipt;
@property (nonatomic, retain) NSDictionary *verifiedReceiptDictionary;
@property (nonatomic, assign) int subscriptionDays; 
@property (nonatomic, retain) NSString *productId;
@property (nonatomic, retain) NSURLConnection *theConnection;
@property (nonatomic, retain) NSMutableData *dataFromConnection;


- (void) verifyReceiptOnComplete:(void (^)(NSNumber*)) completionBlock
                         onError:(void (^)(NSError*)) errorBlock;

-(BOOL) isSubscriptionActive;
-(id) initWithProductId:(NSString*) productId subscriptionDays:(int) days;
@end
