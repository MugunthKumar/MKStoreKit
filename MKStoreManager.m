//
//  MKStoreManager.m
//  MKStoreKit (Version 4.0)
//
//  Created by Mugunth Kumar on 17-Nov-2010.
//  Version 4.0
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

#import "MKStoreManager.h"
#import "SFHFKeychainUtils.h"
#import "MKSKSubscriptionProduct.h"

@interface MKStoreManager () //private methods and properties

@property (nonatomic, copy) void (^onTransactionCancelled)();
@property (nonatomic, copy) void (^onTransactionCompleted)(NSString *productId);

@property (nonatomic, copy) void (^onRestoreFailed)(NSError* error);
@property (nonatomic, copy) void (^onRestoreCompleted)();

@property (nonatomic, retain) NSMutableArray *purchasableObjects;
@property (nonatomic, retain) NSMutableDictionary *subscriptionProducts;

@property (nonatomic, retain) MKStoreObserver *storeObserver;
@property (nonatomic, assign, getter=isProductsAvailable) BOOL isProductsAvailable;

- (void) requestProductData;
- (BOOL) canCurrentDeviceUseFeature: (NSString*) featureID;
- (BOOL) verifyReceipt:(NSData*) receiptData;
- (void) startVerifyingSubscriptionReceipts;

@end

@implementation MKStoreManager

@synthesize purchasableObjects = _purchasableObjects;
@synthesize storeObserver = _storeObserver;
@synthesize subscriptionProducts;

@synthesize isProductsAvailable;

@synthesize onTransactionCancelled;
@synthesize onTransactionCompleted;
@synthesize onRestoreFailed;
@synthesize onRestoreCompleted;

static NSString *ownServer = nil;
static MKStoreManager* _sharedStoreManager;

- (void)dealloc {
	    
    [_purchasableObjects release], _purchasableObjects = nil;
    [_storeObserver release], _storeObserver = nil;
    [onTransactionCancelled release], onTransactionCancelled = nil;
    [onTransactionCompleted release], onTransactionCompleted = nil;
    [onRestoreFailed release], onRestoreFailed = nil;
    [onRestoreCompleted release], onRestoreCompleted = nil;    
    [super dealloc];
}

+ (void) dealloc
{
	[_sharedStoreManager release], _sharedStoreManager = nil;
	[super dealloc];
}

+(void) setObject:(id) object forKey:(NSString*) key
{
    NSString *objectString = nil;
    if([object isKindOfClass:[NSData class]])
    {
        objectString = [[[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding] autorelease];
    }
    if([object isKindOfClass:[NSNumber class]])
    {       
        objectString = [(NSNumber*)object stringValue];
    }
    NSError *error = nil;
    [SFHFKeychainUtils storeUsername:key 
                         andPassword:objectString
                      forServiceName:@"MKStoreKit"
                      updateExisting:YES 
                               error:&error];
    
    if(error)
        NSLog(@"%@", [error localizedDescription]);
}

+(id) objectForKey:(NSString*) key
{
    NSError *error = nil;
    NSObject *object = [SFHFKeychainUtils getPasswordForUsername:key 
                                                  andServiceName:@"MKStoreKit" 
                                                           error:&error];
    if(error)
        NSLog(@"%@", [error localizedDescription]);
    
    return object;
}

+(NSNumber*) numberForKey:(NSString*) key
{
    return [NSNumber numberWithInt:[[MKStoreManager objectForKey:key] intValue]];
}

+(NSData*) dataForKey:(NSString*) key
{
    NSString *str = [MKStoreManager objectForKey:key];
    return [str dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark Singleton Methods

+ (MKStoreManager*)sharedManager
{
	@synchronized(self) {
		
        if (_sharedStoreManager == nil) {
						
#if TARGET_IPHONE_SIMULATOR
			NSLog(@"You are running in Simulator MKStoreKit runs only on devices");
#else
            _sharedStoreManager = [[self alloc] init];					
			_sharedStoreManager.purchasableObjects = [[NSMutableArray alloc] init];
			[_sharedStoreManager requestProductData];						
			_sharedStoreManager.storeObserver = [[MKStoreObserver alloc] init];
			[[SKPaymentQueue defaultQueue] addTransactionObserver:_sharedStoreManager.storeObserver];            
            [_sharedStoreManager startVerifyingSubscriptionReceipts];
#endif
        }
    }
    return _sharedStoreManager;
}

+ (id)allocWithZone:(NSZone *)zone

{	
    @synchronized(self) {
		
        if (_sharedStoreManager == nil) {
			
            _sharedStoreManager = [super allocWithZone:zone];			
            return _sharedStoreManager;  // assignment and return on first allocation
        }
    }
	
    return nil; //on subsequent allocation attempts return nil	
}


- (id)copyWithZone:(NSZone *)zone
{
    return self;	
}

#if __has_feature (objc_arc)

- (id)retain
{	
    return self;	
}

- (unsigned)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;	
}
#endif

#pragma mark Internal MKStoreKit functions

- (void) restorePreviousTransactionsOnComplete:(void (^)(void)) completionBlock
                                       onError:(void (^)(NSError*)) errorBlock
{
    self.onRestoreCompleted = completionBlock;
    self.onRestoreFailed = errorBlock;
    
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

-(void) restoreCompleted
{
    if(self.onRestoreCompleted)
        self.onRestoreCompleted();
    self.onRestoreCompleted = nil;
}

-(void) restoreFailedWithError:(NSError*) error
{
    if(self.onRestoreFailed)
        self.onRestoreFailed(error);
    self.onRestoreFailed = nil;
}

-(void) requestProductData
{
	SKProductsRequest *request= [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObjects: 
								  kFeatureAId,
								  nil]];
	request.delegate = self;
	[request start];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	[self.purchasableObjects addObjectsFromArray:response.products];
	
#ifndef NDEBUG	
	for(int i=0;i<[self.purchasableObjects count];i++)
	{		
		SKProduct *product = [self.purchasableObjects objectAtIndex:i];
		NSLog(@"Feature: %@, Cost: %f, ID: %@",[product localizedTitle],
			  [[product price] doubleValue], [product productIdentifier]);
	}
	
	for(NSString *invalidProduct in response.invalidProductIdentifiers)
		NSLog(@"Problem in iTunes connect configuration for product: %@", invalidProduct);
#endif
	
	[request autorelease];
	
	isProductsAvailable = YES;    
    [[NSNotificationCenter defaultCenter] postNotificationName:kProductFetchedNotification 
                                                        object:[NSNumber numberWithBool:isProductsAvailable]];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
	[request autorelease];
	
	isProductsAvailable = NO;	
    [[NSNotificationCenter defaultCenter] postNotificationName:kProductFetchedNotification 
                                                        object:[NSNumber numberWithBool:isProductsAvailable]];
}

// call this function to check if the user has already purchased your feature
+ (BOOL) isFeaturePurchased:(NSString*) featureId
{    
    return [[MKStoreManager numberForKey:featureId] boolValue];
}

- (BOOL) isSubscriptionActive:(NSString*) featureId
{    
    MKSKSubscriptionProduct *subscriptionProduct = [self.subscriptionProducts objectForKey:featureId];
    return [subscriptionProduct isSubscriptionActive];
}

// Call this function to populate your UI
// this function automatically formats the currency based on the user's locale

- (NSMutableArray*) purchasableObjectsDescription
{
	NSMutableArray *productDescriptions = [[NSMutableArray alloc] initWithCapacity:[self.purchasableObjects count]];
	for(int i=0;i<[self.purchasableObjects count];i++)
	{
		SKProduct *product = [self.purchasableObjects objectAtIndex:i];
		
		NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
		[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
		[numberFormatter setLocale:product.priceLocale];
		NSString *formattedString = [numberFormatter stringFromNumber:product.price];
		[numberFormatter release];
		
		// you might probably need to change this line to suit your UI needs
		NSString *description = [NSString stringWithFormat:@"%@ (%@)",[product localizedTitle], formattedString];
		
#ifndef NDEBUG
		NSLog(@"Product %d - %@", i, description);
#endif
		[productDescriptions addObject: description];
	}
	
	[productDescriptions autorelease];
	return productDescriptions;
}


- (void) buyFeature:(NSString*) featureId
         onComplete:(void (^)(NSString*)) completionBlock         
        onCancelled:(void (^)(void)) cancelBlock
{
    self.onTransactionCompleted = completionBlock;
    self.onTransactionCancelled = cancelBlock;
    
	if([self canCurrentDeviceUseFeature: featureId])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Review request approved", @"")
														message:NSLocalizedString(@"You can use this feature for reviewing the app.", @"")
													   delegate:self 
											  cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
		
        if(self.onTransactionCompleted)
            self.onTransactionCompleted(featureId);
		return;
	}
	
	if ([SKPaymentQueue canMakePayments])
	{
		SKPayment *payment = [SKPayment paymentWithProductIdentifier:featureId];
		[[SKPaymentQueue defaultQueue] addPayment:payment];
	}
	else
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"In-App Purchasing disabled", @"")
														message:NSLocalizedString(@"Check your parental control settings and try again later", @"")
													   delegate:self 
											  cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
											  otherButtonTitles: nil];
		[alert show];
		[alert release];
	}
}

- (BOOL) canConsumeProduct:(NSString*) productIdentifier
{
	int count = [[MKStoreManager numberForKey:productIdentifier] intValue];
	
	return (count > 0);
	
}

- (BOOL) canConsumeProduct:(NSString*) productIdentifier quantity:(int) quantity
{
	int count = [[MKStoreManager numberForKey:productIdentifier] intValue];
	return (count >= quantity);
}

- (BOOL) consumeProduct:(NSString*) productIdentifier quantity:(int) quantity
{
	int count = [[MKStoreManager numberForKey:productIdentifier] intValue];
	if(count < quantity)
	{
		return NO;
	}
	else 
	{
		count -= quantity;
        [MKStoreManager setObject:[NSNumber numberWithInt:count] forKey:productIdentifier];
		return YES;
	}	
}

- (void) startVerifyingSubscriptionReceipts
{
    NSDictionary *subscriptions = [[NSDictionary dictionaryWithContentsOfFile:
                     [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:
                      @"MKStoreKitConfigs.plist"]] objectForKey:@"Subscriptions"];
    
    self.subscriptionProducts = [NSMutableDictionary dictionary];
    for(NSString *productId in [subscriptions allKeys])
    {
        MKSKSubscriptionProduct *product = [[[MKSKSubscriptionProduct alloc] initWithProductId:productId subscriptionDays:[[subscriptionProducts objectForKey:productId] intValue]] autorelease];        
        product.receipt = [MKStoreManager dataForKey:productId]; // cached receipt
        
        if(product.receipt)
        {
            [product verifyReceiptOnComplete:^(NSNumber* isActive)
             {
                 if([isActive boolValue] == NO)
                 {
                     NSLog(@"Subscription: %@ is inactive", product.productId);
                 }
             }
                                     onError:^(NSError* error)
             {
                 
             }]; 
        }
        
        [self.subscriptionProducts setObject:product forKey:productId];
    }
}

#pragma mark In-App purchases callbacks
// In most cases you don't have to touch these methods
-(void) provideContent: (NSString*) productIdentifier 
		   forReceipt:(NSData*) receiptData
{
    MKSKSubscriptionProduct *subscriptionProduct = [self.subscriptionProducts objectForKey:productIdentifier];
    if(subscriptionProduct)
    {                
        subscriptionProduct.receipt = receiptData;
        [subscriptionProduct verifyReceiptOnComplete:^(NSNumber* isActive)
         {
             [MKStoreManager setObject:receiptData forKey:productIdentifier];             
         }
                                             onError:^(NSError* error)
         {
             
         }];
    }        
    else
    {
        if(ownServer != nil && SERVER_PRODUCT_MODEL)
        {
            // ping server and get response before serializing the product
            // this is a blocking call to post receipt data to your server
            // it should normally take a couple of seconds on a good 3G connection
            if(![self verifyReceipt:receiptData]) return;
        }

        NSRange range = [productIdentifier rangeOfString:kConsumableBaseFeatureId];		
        int quantityPurchased = 0;
        
        if(range.location != NSNotFound)
        {
            NSString *countText = [productIdentifier substringFromIndex:range.location+[kConsumableBaseFeatureId length]];	
            quantityPurchased = [countText intValue];
        }
        if(quantityPurchased != 0)
        {		
            int oldCount = [[MKStoreManager numberForKey:productIdentifier] intValue];
            oldCount += quantityPurchased;	
            
            [MKStoreManager setObject:[NSNumber numberWithInt:oldCount] forKey:productIdentifier];		
        }
        else 
        {
            [MKStoreManager setObject:[NSNumber numberWithBool:YES] forKey:productIdentifier];		
        }
    }

    if(self.onTransactionCompleted)
        self.onTransactionCompleted(productIdentifier);
}

- (void) transactionCanceled: (SKPaymentTransaction *)transaction
{

#ifndef NDEBUG
	NSLog(@"User cancelled transaction: %@", [transaction description]);
    NSLog(@"error: %@", transaction.error);
#endif
        
    if(self.onTransactionCancelled)
        self.onTransactionCancelled();
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction
{
    
#ifndef NDEBUG
    NSLog(@"Failed transaction: %@", [transaction description]);
    NSLog(@"error: %@", transaction.error);    
#endif
	
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[transaction.error localizedFailureReason] 
													message:[transaction.error localizedRecoverySuggestion]
												   delegate:self 
										  cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
										  otherButtonTitles: nil];
	[alert show];
	[alert release];
    
    if(self.onTransactionCancelled)
        self.onTransactionCancelled();
}



#pragma mark In-App purchases promo codes support
// This function is only used if you want to enable in-app purchases for free for reviewers
// Read my blog post http://mk.sg/31
- (BOOL) canCurrentDeviceUseFeature: (NSString*) featureID
{
	NSString *uniqueID = [[UIDevice currentDevice] uniqueIdentifier];
	// check udid and featureid with developer's server
	
	if(ownServer == nil) return NO; // sanity check
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", ownServer, @"featureCheck.php"]];
	
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url 
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                                          timeoutInterval:60];
	
	[theRequest setHTTPMethod:@"POST"];		
	[theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	
	NSString *postData = [NSString stringWithFormat:@"productid=%@&udid=%@", featureID, uniqueID];
	
	NSString *length = [NSString stringWithFormat:@"%d", [postData length]];	
	[theRequest setValue:length forHTTPHeaderField:@"Content-Length"];	
	
	[theRequest setHTTPBody:[postData dataUsingEncoding:NSASCIIStringEncoding]];
	
	NSHTTPURLResponse* urlResponse = nil;
	NSError *error = [[[NSError alloc] init] autorelease];  
	
	NSData *responseData = [NSURLConnection sendSynchronousRequest:theRequest
												 returningResponse:&urlResponse 
															 error:&error];  
	
	NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding];
	
	BOOL retVal = NO;
	if([responseString isEqualToString:@"YES"])		
	{
		retVal = YES;
	}
	
	[responseString release];
	return retVal;
}

// This function is only used if you want to enable in-app purchases for free for reviewers
// Read my blog post http://mk.sg/

-(BOOL) verifyReceipt:(NSData*) receiptData
{
	if(ownServer == nil) return NO; // sanity check
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", ownServer, @"verifyProduct.php"]];
	
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url 
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                                          timeoutInterval:60];
	
	[theRequest setHTTPMethod:@"POST"];		
	[theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	
	NSString *receiptDataString = [[NSString alloc] initWithData:receiptData encoding:NSASCIIStringEncoding];
	NSString *postData = [NSString stringWithFormat:@"receiptdata=%@", receiptDataString];
	[receiptDataString release];
	
	NSString *length = [NSString stringWithFormat:@"%d", [postData length]];	
	[theRequest setValue:length forHTTPHeaderField:@"Content-Length"];	
	
	[theRequest setHTTPBody:[postData dataUsingEncoding:NSASCIIStringEncoding]];
	
	NSHTTPURLResponse* urlResponse = nil;
	NSError *error = [[[NSError alloc] init] autorelease];  
	
	NSData *responseData = [NSURLConnection sendSynchronousRequest:theRequest
												 returningResponse:&urlResponse 
															 error:&error];  
	
	NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding];
	
	BOOL retVal = NO;
	if([responseString isEqualToString:@"YES"])		
	{
		retVal = YES;
	}
	
	[responseString release];
	return retVal;
}
@end
