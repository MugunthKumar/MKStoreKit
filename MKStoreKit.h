//
//  MKStoreKit.h
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

#import <Foundation/Foundation.h>

#if ! __has_feature(objc_arc)
#error MKStoreKit is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#ifndef __IPHONE_7_0
#error "MKStoreKit is supported only on iOS 7 or later."
#endif

/*!
 *  @abstract This notification is posted when MKStoreKit completes initialization sequence
 */
extern NSString *const kMKStoreKitProductsAvailableNotification;

/*!
 *  @abstract This notification is posted when MKStoreKit completes purchase of a product
 */
extern NSString *const kMKStoreKitProductPurchasedNotification;

/*!
 *  @abstract This notification is posted when MKStoreKit failes to complete the purchase of a product
 */
extern NSString *const kMKStoreKitProductPurchaseFailedNotification;

/*!
 *  @abstract This notification is posted when MKStoreKit completes restoring purchases
 */
extern NSString *const kMKStoreKitRestoredPurchasesNotification;

/*!
 *  @abstract This notification is posted when MKStoreKit fails to restore purchases
 */
extern NSString *const kMKStoreKitRestoringPurchasesFailedNotification;

/*!
 *  @abstract This notification is posted when MKStoreKit fails to validate receipts
 */
extern NSString *const kMKStoreKitReceiptValidationFailedNotification;

/*!
 *  @abstract This notification is posted when MKStoreKit detects expiration of a auto-renewing subscription
 */
extern NSString *const kMKStoreKitSubscriptionExpiredNotification;


/*!
 *  @abstract The singleton class that takes care of In App Purchasing
 *  @discussion
 *  MKStoreKit provides three basic functionalities, namely, managing In App Purchases,
 *  remembering purchases for you and also provides a basic virtual currency manager
 */

@interface MKStoreKit : NSObject

/*!
 *  @abstract Property that stores the list of available In App purchaseable products
 *
 *  @discussion
 *	This property is initialized after the call to startProductRequest completes
 *  If the startProductRequest fails, this property will be nil
 *  @seealso
 *  -startProductRequest
 */
@property NSArray *availableProducts;

/*!
 *  @abstract Accessor for the shared singleton object
 *
 *  @discussion
 *	Use this to access the only object of MKStoreKit
 */
+ (MKStoreKit*) sharedKit;

/*!
 *  @abstract Initializes MKStoreKit singleton by making the product request using StoreKit's SKProductRequest
 *
 *  @discussion
 *	This method should be called in your application:didFinishLaunchingWithOptions: method
 *  If this method fails, MKStoreKit will not work
 *  Most common reason for this method to fail is Internet connection being offline
 *  It's your responsibility to call startProductRequest if the Internet connection comes online 
 *  and the previous call to startProductRequest failed (availableProducts.count == 0).
 *
 *  @seealso
 *  -availableProducts
 */
-(void) startProductRequest;

/*!
 *  @abstract Restores In App Purchases made on other devices
 *
 *  @discussion
 *	This method restores your user's In App Purchases made on other devices.
 */
-(void) restorePurchases;

/*!
 *  @abstract Initiates payment request for a In App Purchasable Product
 *
 *  @discussion
 *	This method starts a payment request to App Store.
 *  Purchased products are notified through NSNotifications
 *  Observe kMKStoreKitProductPurchasedNotification to get notified when the purchase completes
 *
 *  @seealso
 *  -isProductPurchased
 *  -expiryDateForProduct
 */
-(void) initiatePaymentRequestForProductWithIdentifier:(NSString*) productId;

/*!
 *  @abstract Checks whether the product identified by the given productId is purchased previously
 *
 *  @discussion
 *	This method checks against the local store maintained by MKStoreKit if the product was previously purchased
 *  This method can be used for Consumables/Non-Consumables/Auto-renewing subscriptions
 *  Observe kMKStoreKitProductPurchasedNotification to get notified when the purchase completes
 *
 *  @seealso
 *  -expiryDateForProduct
 */
-(BOOL) isProductPurchased:(NSString*) productId;

/*!
 *  @abstract Checks the expiry date for the product identified by the given productId
 *
 *  @discussion
 *	This method checks against the local store maintained by MKStoreKit for expiry date of a given product
 *  This method can be used for Consumables/Non-Consumables/Auto-renewing subscriptions
 *  Expiry date for Consumables/Non-Consumables is always [NSNull null]
 *  Expiry date for Auto-renewing subscriptions is fetched from receipt validation server and remembered by MKStoreKit
 *  Expiry date for Auto-renewing subscriptions will be [NSNull null] for a subscription that was just purchased
 *  MKStoreKit automatically takes care of updating expiry date when a auto-renewing subscription renews
 *  Observe kMKStoreKitProductPurchasedNotification to get notified when the purchase completes
 *  Observe kMKStoreKitSubscriptionExpiredNotification to get notified when a auto-renewing subscription expires and the
 *  user has stopped the subscription
 *
 *  @seealso
 *  -isProductPurchased
 */
-(NSDate*) expiryDateForProduct:(NSString*) productId;

/*!
 *  @abstract This method returns the available credits (managed by MKStoreKit) for a given consumable
 *
 *  @discussion
 *	MKStoreKit provides a basic virtual currency manager for your consumables
 *  This method returns the available credits for a consumable
 *  A consumable ID is different from its product id, and it is configured in MKStoreKitConfigs.plist file
 *  Observe kMKStoreKitProductPurchasedNotification to get notified when the purchase of the consumable completes
 *
 *  @seealso
 *  -isProductPurchased
 */
-(NSNumber*) availableCreditsForConsumable:(NSString*) consumableID;

/*!
 *  @abstract This method updates the available credits (managed by MKStoreKit) for a given consumable
 *
 *  @discussion
 *	MKStoreKit provides a basic virtual currency manager for your consumables
 *  This method should be called if the user consumes a consumable credit
 *  A consumable ID is different from its product id, and it is configured in MKStoreKitConfigs.plist file
 *  Observe kMKStoreKitProductPurchasedNotification to get notified when the purchase of the consumable completes
 *
 *  @seealso
 *  -isProductPurchased
 */
-(NSNumber*) consumeCredits:(NSNumber*) creditCountToConsume identifiedByConsumableIdentifier:(NSString*) consumableId;

/*!
 *  @abstract This method sets the default credits (managed by MKStoreKit) for a given consumable
 *
 *  @discussion
 *	MKStoreKit provides a basic virtual currency manager for your consumables
 *  This method should be called if you provide free credits to start with
 *  A consumable ID is different from its product id, and it is configured in MKStoreKitConfigs.plist file
 *  Observe kMKStoreKitProductPurchasedNotification to get notified when the purchase of the consumable completes
 *
 *  @seealso
 *  -isProductPurchased
 */
-(void) setDefaultCredits:(NSNumber*) creditCount forConsumableIdentifier:(NSString*) consumableId;


@end
