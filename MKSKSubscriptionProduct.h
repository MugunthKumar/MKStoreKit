//
//  MKSKSubscriptionProduct.h
//  MKStoreKitDemo
//  Version 4.1
//
//  Created by Mugunth on 03/07/11.
//  Copyright 2011 Steinlogic. All rights reserved.

//  Licensing (Zlib)
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source distribution.

//  As a side note on using this code, you might consider giving some credit to me by
//	1) linking my website from your app's website 
//	2) or crediting me inside the app's credits page 
//	3) or a tweet mentioning @mugunthkumar
//	4) A paypal donation to mugunth.kumar@gmail.com


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
