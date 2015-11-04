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

#import "TargetConditionals.h"

#if TARGET_OS_IPHONE
#import <Foundation/Foundation.h>

#ifndef __IPHONE_8_0
#error "MKStoreKit is only supported on iOS 8 or later."
#endif

#else
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#ifndef __MAC_10_10
#error "MKStoreKit is only supported on OS X 10.10 or later."
#endif

#endif

#ifdef __OBJC__
#if ! __has_feature(objc_arc)
#error MKStoreKit is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif
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
 *  @abstract This notification is posted when MKStoreKit fails to complete the purchase of a product
 */
extern NSString *const kMKStoreKitProductPurchaseFailedNotification;

/*!
 *  @abstract This notification is posted when MKStoreKit has a purchase deferred for approval
 *  @discussion
 *  This occurs when a device has parental controls for in-App Purchases enabled.
 *   iOS will present a prompt for parental approval, either on the current device or
 *   on the parent's device. Update your UI to reflect the deferred status, and wait
 *   to be notified of the completed or failed purchase.
 *  @availability iOS 8.0 or later
 */
extern NSString *const kMKStoreKitProductPurchaseDeferredNotification NS_AVAILABLE(10_10, 8_0);

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
 *  @abstract This notification is posted when MKStoreKit downloads a hosted content
 */
extern NSString *const kMKStoreKitDownloadProgressNotification;

/*!
 *  @abstract This notification is posted when MKStoreKit completes downloading a hosted content
 */
extern NSString *const kMKStoreKitDownloadCompletedNotification;


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
+ (MKStoreKit *)sharedKit;

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
- (void)startProductRequest;

/*!
 *  @abstract Initializes MKStoreKit singleton by making the product request using StoreKit's SKProductRequest
 *
 *  @discussion
 *	This method is normally called after fetching a list of products from your server.
 *  If all your products are known before hand, 
 *  fill them in MKStoreKitConfigs.plist and use -startProductRequest
 *
 *  If this method fails, MKStoreKit will not work
 *  Most common reason for this method to fail is Internet connection being offline
 *  It's your responsibility to call startProductRequest if the Internet connection comes online
 *  and the previous call to startProductRequest failed (availableProducts.count == 0).
 *
 *  @seealso
 *  -availableProducts
 *  -startProductRequest
 */
- (void)startProductRequestWithProductIdentifiers:(NSArray*) items;

/*!
 *  @abstract Restores In App Purchases made on other devices
 *
 *  @discussion
 *	This method restores your user's In App Purchases made on other devices.
 */
- (void)restorePurchases;

/*!
 *  @abstract Refreshes the App Store receipt and prompts the user to authenticate.
 *
 *  @discussion
 *	This method can generate a reciept while debugging your application. In a production
 *  environment this should only be used in an appropriate context because it will present
 *  an App Store login alert to the user (without explanation).
 */
- (void)refreshAppStoreReceipt;

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
- (void)initiatePaymentRequestForProductWithIdentifier:(NSString *)productId;

/*!
 *  @abstract Checks whether the app version the user purchased is older than the required version
 *
 *  @discussion
 *	This method checks against the local store maintained by MKStoreKit when the app was originally purchased
 *  This method can be used to determine if a user should recieve a free upgrade. For example, apps transitioning
 *  from a paid system to a freemium system can determine if users are "grandfathered-in" and exempt from extra
 *  freemium purchases.
 *
 *  @seealso
 *  -isProductPurchased
 */
- (BOOL)purchasedAppBeforeVersion:(NSString *)requiredVersion;

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
- (BOOL)isProductPurchased:(NSString *)productId;

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
- (NSDate *)expiryDateForProduct:(NSString *)productId;

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
- (NSNumber *)availableCreditsForConsumable:(NSString *)consumableID;

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
- (NSNumber *)consumeCredits:(NSNumber *)creditCountToConsume identifiedByConsumableIdentifier:(NSString *)consumableId;

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
- (void)setDefaultCredits:(NSNumber *)creditCount forConsumableIdentifier:(NSString *)consumableId;


@end