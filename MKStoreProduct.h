//
//  MKStoreProduct.h
//  IAPDemo
//
//  Created by Mugunth on 19/11/14.
//  Copyright (c) 2014 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _MKStoreProductType {

  MKStoreProductTypeConsumable,
  MKStoreProductTypeNonConsumable,
  MKStoreProductTypeAutoRenewableSubscription,
  MKStoreProductTypeNonRenewableSubscription,
  MKStoreProductTypeFreeSubscription,
} MKStoreProductType;

@interface MKStoreProduct : NSObject
@property MKStoreProductType *productType;
@property NSString *productIdentifier;
@property NSString *latestReceiptInfo;
@end
