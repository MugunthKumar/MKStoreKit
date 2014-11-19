//
//  MKStoreKit.m
//  MKStoreKit 6.0
//
//  Copyright 2014 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//	File created using Singleton Xcode Template by Mugunth Kumar (http://blog.mugunthkumar.com)
//  More information about this template on the post http://mk.sg/89
//  Permission granted to do anything, commercial/non-commercial with this file apart from removing the line/URL above
//  Created by Mugunth Kumar (@mugunthkumar) on 17 Nov 2014.
//  Copyright (C) 2011-2020 by Steinlogic Consulting And Training Pte Ltd.

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

//  As a side note on using this code, you might consider giving some credit to me by
//	1) linking my website from your app's website
//	2) or crediting me inside the app's credits page
//	3) or a tweet mentioning @mugunthkumar
//	4) A paypal donation to mugunth.kumar@gmail.com
//
//  A note on redistribution
//	if you are re-publishing after editing, please retain the above copyright notices

#import "MKStoreKit.h"

@import StoreKit;
NSString *const kMKStoreKitProductsAvailableNotification = @"com.mugunthkumar.mkstorekit.productsavailable";
NSString *const kMKStoreKitProductPurchasedNotification = @"com.mugunthkumar.mkstorekit.productspurchased";
NSString *const kMKStoreKitRestoredPurchasesNotification = @"com.mugunthkumar.mkstorekit.restoredpurchases";
NSString *const kMKStoreKitRestoringPurchasesFailedNotification = @"com.mugunthkumar.mkstorekit.failedrestoringpurchases";
NSString *const kMKStoreKitSubscriptionExpiredNotification = @"com.mugunthkumar.mkstorekit.subscriptionexpired";

NSString *const kSandboxServer = @"https://sandbox.itunes.apple.com/verifyReceipt";
NSString *const kLiveServer = @"https://buy.itunes.apple.com/verifyReceipt";

static NSDictionary *errorDictionary;

@interface MKStoreKit (/*Private Methods*/) <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property NSMutableDictionary *purchaseRecord;
@end

@implementation MKStoreKit

#pragma mark -
#pragma mark Singleton Methods

+ (MKStoreKit*)sharedKit {
  
  static MKStoreKit *_sharedKit;
  if(!_sharedKit) {
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
      _sharedKit = [[super allocWithZone:nil] init];
      [[SKPaymentQueue defaultQueue] addTransactionObserver:_sharedKit];
      [_sharedKit restorePurchaseRecord];
      [[NSNotificationCenter defaultCenter] addObserver:_sharedKit
                                               selector:@selector(savePurchaseRecord)
                                                   name:UIApplicationDidEnterBackgroundNotification object:nil];
      
      [_sharedKit startValidatingReceiptsAndUpdateLocalStore];
    });
		}
  
		return _sharedKit;
}

+ (id)allocWithZone:(NSZone *)zone {
  
  return [self sharedKit];
}

- (id)copyWithZone:(NSZone *)zone {
  
  return self;
}

#pragma mark -
#pragma mark Initializer

+(void) initialize {
  
  errorDictionary = @{@(21000) : @"The App Store could not read the JSON object you provided.",
                      @(21002) : @"The data in the receipt-data property was malformed or missing.",
                      @(21003) : @"The receipt could not be authenticated.",
                      @(21004) : @"The shared secret you provided does not match the shared secret on file for your accunt.",
                      @(21005) : @"The receipt server is not currently available.",
                      @(21006) : @"This receipt is valid but the subscription has expired.",
                      @(21007) : @"This receipt is from the test environment.",
                      @(21008) : @"This receipt is from the production environment."};
}

#pragma mark -
#pragma mark Helpers

+(NSDictionary*) configs {
  
  return [NSDictionary dictionaryWithContentsOfFile:
          [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:
           @"MKStoreKitConfigs.plist"]];
}


#pragma mark -
#pragma mark Store File Management

-(NSString*) purchaseRecordFilePath {
  
  NSString *documentDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                    NSUserDomainMask, YES).firstObject;
  return [documentDirectory stringByAppendingPathComponent:@"purchaserecord.plist"];
}

-(void) restorePurchaseRecord {
  
  self.purchaseRecord = (NSMutableDictionary*) [[NSKeyedUnarchiver unarchiveObjectWithFile:
                                                 [self purchaseRecordFilePath]] mutableCopy];
  if(self.purchaseRecord == nil) {
    self.purchaseRecord = [NSMutableDictionary dictionary];
  }
}

-(void) savePurchaseRecord {
  
  NSError *error = nil;
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.purchaseRecord];
  BOOL success = [data writeToFile:[self purchaseRecordFilePath]
                           options:NSDataWritingAtomic | NSDataWritingFileProtectionComplete
                             error:&error];
  
  if(!success) {
    
    NSLog(@"Failed to remember data record");
  }
  NSLog(@"%@", self.purchaseRecord);
}

#pragma mark -
#pragma mark Feature Management

-(BOOL) isProductPurchased:(NSString*) productId {
  
  return [self.purchaseRecord.allKeys containsObject:productId];
}

-(NSDate*) expiryDateForProduct:(NSString*) productId {
  
  NSNumber *expiresDateMs = self.purchaseRecord[productId];
  return [NSDate dateWithTimeIntervalSince1970:[expiresDateMs doubleValue]];
}

-(NSNumber*) availableCreditsForConsumable:(NSString*) consumableId {
  
  return self.purchaseRecord[consumableId];
}

-(NSNumber*) consumeCredits:(NSNumber*) creditCountToConsume identifiedByConsumableIdentifier:(NSString*) consumableId {
  
  NSNumber *currentConsumableCount = self.purchaseRecord[consumableId];
  currentConsumableCount = @([currentConsumableCount doubleValue] - [creditCountToConsume doubleValue]);
  self.purchaseRecord[consumableId] = currentConsumableCount;
  [self savePurchaseRecord];
  return currentConsumableCount;
}

#pragma mark -
#pragma mark Start requesting for available in app purchases

-(void) startProductRequest {
  
  NSMutableArray *productsArray = [NSMutableArray array];
  NSArray *consumables = [[MKStoreKit configs][@"Consumables"] allKeys];
  NSArray *others = [MKStoreKit configs][@"Others"];
  
  [productsArray addObjectsFromArray:consumables];
  [productsArray addObjectsFromArray:others];
  
  SKProductsRequest *productsRequest = [[SKProductsRequest alloc]
                                        initWithProductIdentifiers:[NSSet setWithArray:productsArray]];
  productsRequest.delegate = self;
  [productsRequest start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
  
  if(response.invalidProductIdentifiers.count > 0) {
    NSLog(@"Invalid Product IDs: %@", response.invalidProductIdentifiers);
  }
  
  self.availableProducts = response.products;
  [[NSNotificationCenter defaultCenter] postNotificationName:kMKStoreKitProductsAvailableNotification
                                                      object:self.availableProducts];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
  
  NSLog(@"Product request failed with error: %@", error);
}

#pragma mark -
#pragma mark Restore Purchases

-(void) restorePurchases {
  
  [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
  
  [[NSNotificationCenter defaultCenter] postNotificationName:kMKStoreKitRestoredPurchasesNotification
                                                      object:error];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
  
  [[NSNotificationCenter defaultCenter] postNotificationName:kMKStoreKitRestoredPurchasesNotification
                                                      object:nil];
}

#pragma mark -
#pragma mark Initiate a Purchase

-(void) initiatePaymentRequestForProductWithIdentifier:(NSString*) productId {
  
  if(!self.availableProducts) {
    // FIX ME
    // Initializer might be running or internet might not be available
    NSLog(@"No products are available. Did you initialize MKStoreKit by calling [[MKStoreManager sharedManager] startProductRequest]");
  }
  if(![SKPaymentQueue canMakePayments]) {
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"In App Purchasing Disabled", @"")
                                message:NSLocalizedString(@"Check your parental control settings and try again later", @"")
                               delegate:self
                      cancelButtonTitle:NSLocalizedString(@"OK", @"")
                      otherButtonTitles: nil] show];
    
    return;
  }
  [self.availableProducts enumerateObjectsUsingBlock:^(SKProduct *thisProduct, NSUInteger idx, BOOL *stop) {
    
    if([thisProduct.productIdentifier isEqualToString:productId]) {
      
      *stop = YES;
      SKPayment *payment = [SKPayment paymentWithProduct:thisProduct];
      [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
  }];
}

#pragma mark -
#pragma mark Receipt validation

-(void) startValidatingAppStoreReceiptWithCompletionHandler:(void (^)(NSArray *receipts, NSError *error)) completionHandler {
  
  NSData *receiptData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
  if(!receiptData) {
    completionHandler(nil, nil);
    return;
  }
  NSError *error;
  NSMutableDictionary *requestContents = [NSMutableDictionary dictionaryWithObject:
                                          [receiptData base64EncodedStringWithOptions:0] forKey:@"receipt-data"];
  NSString *sharedSecret = [MKStoreKit configs][@"SharedSecret"];
  if(sharedSecret) requestContents[@"password"] = sharedSecret;
  
  NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestContents
                                                        options:0
                                                          error:&error];
  
#ifdef DEBUG
  NSMutableURLRequest *storeRequest = [NSMutableURLRequest requestWithURL:
                                       [NSURL URLWithString:kSandboxServer]];
#else
  NSMutableURLRequest *storeRequest = [NSMutableURLRequest requestWithURL:
                                       [NSURL URLWithString:kLiveServer]];
#endif
  
  [storeRequest setHTTPMethod:@"POST"];
  [storeRequest setHTTPBody:requestData];
  
  NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
  
  [[session dataTaskWithRequest:storeRequest
              completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                
                if(!error) {
                  NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                  NSInteger status = [jsonResponse[@"status"] integerValue];
                  if(status != 0) {
                    NSError *error = [NSError errorWithDomain:@"com.mugunthkumar.mkstorekit"
                                                         code:status
                                                     userInfo:@{NSLocalizedDescriptionKey : errorDictionary[@(status)]}];
                    completionHandler(nil, error);
                  } else {
                    
                    NSMutableArray *receipts = [jsonResponse[@"latest_receipt_info"] mutableCopy];
                    NSArray *inAppReceipts = jsonResponse[@"receipt"][@"in_app"];
                    [receipts addObjectsFromArray:inAppReceipts];
                    completionHandler(receipts, nil);
                  }
                } else {
                  completionHandler(nil, error);
                }
              }] resume];
}

-(void) startValidatingReceiptsAndUpdateLocalStore {
  
  [self startValidatingAppStoreReceiptWithCompletionHandler:^(NSArray *receipts, NSError *error) {
    
    if(error) {
      
      NSLog(@"Receipt validation failed with error: %@", error);
    } else {
      
      __block BOOL purchaseRecordDirty = NO;
      [receipts enumerateObjectsUsingBlock:^(NSDictionary *receiptDictionary, NSUInteger idx, BOOL *stop) {
        
        NSString *productIdentifier = receiptDictionary[@"product_id"];
        NSNumber *expiresDateMs = receiptDictionary[@"expires_date_ms"];
        if(expiresDateMs && ![expiresDateMs isKindOfClass: [NSNull class]]) {
          NSNumber *previouslyStoredExpiresDateMs = self.purchaseRecord[productIdentifier];
          if([expiresDateMs doubleValue] > [previouslyStoredExpiresDateMs doubleValue]) {
            self.purchaseRecord[productIdentifier] = expiresDateMs;
            purchaseRecordDirty = YES;
          }
        }
      }];
      
      if(purchaseRecordDirty) [self savePurchaseRecord];
      
      [self.purchaseRecord enumerateKeysAndObjectsUsingBlock:^(NSString *productIdentifier, NSNumber *expiresDateMs, BOOL *stop) {
        
        if(![expiresDateMs isKindOfClass: [NSNull class]]) {
          
          if([[NSDate date] timeIntervalSince1970] > [expiresDateMs doubleValue]) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kMKStoreKitSubscriptionExpiredNotification
                                                                object:productIdentifier];
          }
        }
      }];
    }
  }];
}

#pragma mark -
#pragma mark Transaction Observers

//FIX ME
-(void) paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray *)downloads {
  
  [downloads enumerateObjectsUsingBlock:^(SKDownload *thisDownload, NSUInteger idx, BOOL *stop) {
    
    switch (thisDownload.downloadState) {
      case SKDownloadStateActive:
        break;
      case SKDownloadStateFinished:
        break;
      default:
        break;
    }
  }];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
  
  for (SKPaymentTransaction *transaction in transactions) {
    switch (transaction.transactionState) {
        
      case SKPaymentTransactionStatePurchasing:
        break;
        
      case SKPaymentTransactionStateDeferred:
        // FIX ME
        break;
        
      case SKPaymentTransactionStateFailed:
        NSLog(@"Transaction Failed with error: %@", transaction.error);
        [queue finishTransaction:transaction];
        break;
        
      case SKPaymentTransactionStatePurchased:
      case SKPaymentTransactionStateRestored: {
        
        if(transaction.downloads.count > 0) {
          [queue startDownloads:transaction.downloads];
        }
        
        [queue finishTransaction:transaction];
        
        self.purchaseRecord[transaction.payment.productIdentifier] = [NSNull null];
        NSDictionary *availableConsumables = [MKStoreKit configs][@"Consumables"];
        NSArray *consumables = [availableConsumables allKeys];
        if([consumables containsObject:transaction.payment.productIdentifier]) {
          
          NSDictionary *thisConsumable = availableConsumables[transaction.payment.productIdentifier];
          NSString *consumableId = thisConsumable[@"ConsumableId"];
          NSNumber *consumableCount = thisConsumable[@"ConsumableCount"];
          NSNumber *currentConsumableCount = self.purchaseRecord[consumableId];
          consumableCount = @([consumableCount doubleValue] + [currentConsumableCount doubleValue]);
          self.purchaseRecord[consumableId] = consumableCount;
          [self savePurchaseRecord];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kMKStoreKitProductPurchasedNotification
                                                            object:transaction.payment.productIdentifier];
      }
        break;
    }
  }
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction {
  
  NSLog(@"Transaction Failed with error: %@", transaction.error);
  [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

@end
