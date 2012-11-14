#import "VerificationController.h"

static VerificationController *singleton;


@implementation VerificationController

+ (VerificationController *)sharedInstance
{
	if (singleton == nil)
    {
		singleton = [[VerificationController alloc] init];
	}
	return singleton;
}


- (id)init
{
	self = [super init];
	if (self != nil)
    {
        transactionsReceiptStorageDictionary = [[NSMutableDictionary alloc] init];
	}
	return self;
}


- (NSDictionary *)dictionaryFromPlistData:(NSData *)data
{
    NSError *error;
    NSDictionary *dictionaryParsed = [NSPropertyListSerialization propertyListWithData:data
                                                                               options:NSPropertyListImmutable
                                                                                format:nil
                                                                                 error:&error];
    if (!dictionaryParsed)
    {
        if (error)
        {
#warning Handle the error here.
        }
        return nil;
    }
    return dictionaryParsed;
}


- (NSDictionary *)dictionaryFromJSONData:(NSData *)data
{
    NSError *error;
    NSDictionary *dictionaryParsed = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:0
                                                                       error:&error];
    if (!dictionaryParsed)
    {
        if (error)
        {
#warning Handle the error here.
        }
        return nil;
    }
    return dictionaryParsed;
}


#pragma mark Receipt Verification

// This method should be called once a transaction gets to the SKPaymentTransactionStatePurchased or SKPaymentTransactionStateRestored state
// Call it with the SKPaymentTransaction.transactionReceipt
- (BOOL)verifyPurchase:(SKPaymentTransaction *)transaction
{
    BOOL isOk = [self isTransactionAndItsReceiptValid:transaction];
    if (!isOk)
    {
        // There was something wrong with the transaction we got back, so no need to call verifyReceipt.
        return isOk;
    }
    
    // The transaction looks ok, so start the verify process.
    
    // Encode the receiptData for the itms receipt verification POST request.
    NSString *jsonObjectString = [self encodeBase64:(uint8_t *)transaction.transactionReceipt.bytes
                                             length:transaction.transactionReceipt.length];
    
    // Create the POST request payload.
    NSString *payload = [NSString stringWithFormat:@"{\"receipt-data\" : \"%@\", \"password\" : \"%@\"}",
                         jsonObjectString, ITC_CONTENT_PROVIDER_SHARED_SECRET];
    
    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];
    
#warning Check for the correct itms verify receipt URL
    // Use ITMS_SANDBOX_VERIFY_RECEIPT_URL while testing against the sandbox.
    NSString *serverURL = ITMS_PROD_VERIFY_RECEIPT_URL;
    
    // Create the POST request to the server.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:serverURL]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:payloadData];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    [conn start];
    
    // The transation receipt has not been validated yet.  That is done from the NSURLConnection callback.
    return isOk;
}


// Check the validity of the receipt.  If it checks out then also ensure the transaction is something
// we haven't seen before and then decode and save the purchaseInfo from the receipt for later receipt validation.
- (BOOL)isTransactionAndItsReceiptValid:(SKPaymentTransaction *)transaction
{
    if (!(transaction && transaction.transactionReceipt && [transaction.transactionReceipt length] > 0))
    {
        // Transaction is not valid.
        return NO;
    }
    
    // Pull the purchase-info out of the transaction receipt, decode it, and save it for later so
    // it can be cross checked with the verifyReceipt.
    NSDictionary *receiptDict       = [self dictionaryFromPlistData:transaction.transactionReceipt];
    NSString *transactionPurchaseInfo = [receiptDict objectForKey:@"purchase-info"];
    NSString *decodedPurchaseInfo   = [self decodeBase64:transactionPurchaseInfo length:nil];
    NSDictionary *purchaseInfoDict  = [self dictionaryFromPlistData:[decodedPurchaseInfo dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *transactionId         = [purchaseInfoDict objectForKey:@"transaction-id"];
    NSString *purchaseDateString    = [purchaseInfoDict objectForKey:@"purchase-date"];
    NSString *signature             = [receiptDict objectForKey:@"signature"];
    
    // Convert the string into a date
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss z"];
    
    NSDate *purchaseDate = [dateFormat dateFromString:[purchaseDateString stringByReplacingOccurrencesOfString:@"Etc/" withString:@""]];
    
    
    if (![self isTransactionIdUnique:transactionId])
    {
        // We've seen this transaction before.
        // Had [transactionsReceiptStorageDictionary objectForKey:transactionId]
        // Got purchaseInfoDict
        return NO;
    }
    
    // Check the authenticity of the receipt response/signature etc.

    BOOL result = checkReceiptSecurity(transactionPurchaseInfo, signature,
                                       (__bridge CFDateRef)(purchaseDate));
    
    if (!result)
    {
        return NO;
    }
    
    // Ensure the transaction itself is legit
    if (![self doTransactionDetailsMatchPurchaseInfo:transaction withPurchaseInfo:purchaseInfoDict])
    {
        return NO;
    }
    
    // Make a note of the fact that we've seen the transaction id already
    [self saveTransactionId:transactionId];
    
    // Save the transaction receipt's purchaseInfo in the transactionsReceiptStorageDictionary.
    [transactionsReceiptStorageDictionary setObject:purchaseInfoDict forKey:transactionId];
    
    return YES;
}

// Make sure the transaction details actually match the purchase info
- (BOOL)doTransactionDetailsMatchPurchaseInfo:(SKPaymentTransaction *)transaction withPurchaseInfo:(NSDictionary *)purchaseInfoDict

{
    if (!transaction || !purchaseInfoDict)
    {
        return NO;
    }
    
    int failCount = 0;
    
    if (![transaction.payment.productIdentifier isEqualToString:[purchaseInfoDict objectForKey:@"product-id"]])
    {
        
        failCount++;
    }
    
    if (transaction.payment.quantity != [[purchaseInfoDict objectForKey:@"quantity"] intValue])
    {
        failCount++;
    }
    
    if (![transaction.transactionIdentifier isEqualToString:[purchaseInfoDict objectForKey:@"transaction-id"]])
    {
        failCount++;
    }
    
    // Optionally check the bid and bvrs match this app's current bundle ID and bundle version.
    // Optionally check the requestData.
    // Optionally check the dates.
    
    if (failCount != 0)
    {
        return NO;
    }
    
    // The transaction and its signed content seem ok.
    return YES;
}



- (BOOL)isTransactionIdUnique:(NSString *)transactionId
{
    NSString *transactionDictionary = KNOWN_TRANSACTIONS_KEY;
    // Save the transactionId to the standardUserDefaults so we can check against that later
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    if (![defaults objectForKey:transactionDictionary])
    {
        [defaults setObject:[[NSMutableDictionary alloc] init] forKey:transactionDictionary];
        [defaults synchronize];
    }
    
    if (![[defaults objectForKey:transactionDictionary] objectForKey:transactionId])
    {
        return YES;
    }
    // The transaction already exists in the defaults.
    return NO;
}


- (void)saveTransactionId:(NSString *)transactionId
{
    // Save the transactionId to the standardUserDefaults so we can check against that later
    // If dictionary exists already then retrieve it and add new transactionID
    // Regardless save transactionID to dictionary which gets saved to NSUserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *transactionDictionary = KNOWN_TRANSACTIONS_KEY;
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:
                                       [defaults objectForKey:transactionDictionary]];
    if (!dictionary)
    {
        dictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:1], transactionId, nil];
    } else {
        [dictionary setObject:[NSNumber numberWithInt:1] forKey:transactionId];
    }
    [defaults setObject:dictionary forKey:transactionDictionary];
    [defaults synchronize];
    
}


- (BOOL)doesTransactionInfoMatchReceipt:(NSString*) receiptString
{
    // Convert the responseString into a dictionary and pull out the receipt data.
    NSDictionary *verifiedReceiptDictionary = [self dictionaryFromJSONData:[receiptString dataUsingEncoding:NSUTF8StringEncoding]];
    
    // Check the status of the verifyReceipt call
    id status = [verifiedReceiptDictionary objectForKey:@"status"];
    if (!status)
    {
        return NO;
    }
    int verifyReceiptStatus = [status integerValue];
    // 21006 = This receipt is valid but the subscription has expired.
    if (0 != verifyReceiptStatus && 21006 != verifyReceiptStatus)
    {
        return NO;
    }
    
    // The receipt is valid, so checked the receipt specifics now.
    
    NSDictionary *verifiedReceiptReceiptDictionary  = [verifiedReceiptDictionary objectForKey:@"receipt"];
    NSString *verifiedReceiptUniqueIdentifier       = [verifiedReceiptReceiptDictionary objectForKey:@"unique_identifier"];
    NSString *transactionIdFromVerifiedReceipt      = [verifiedReceiptReceiptDictionary objectForKey:@"transaction_id"];
    
    // Get the transaction's receipt data from the transactionsReceiptStorageDictionary
    NSDictionary *purchaseInfoFromTransaction = [transactionsReceiptStorageDictionary objectForKey:transactionIdFromVerifiedReceipt];
    
    if (!purchaseInfoFromTransaction)
    {
        // We didn't find a receipt for this transaction.
        return NO;
    }
    
    
    // NOTE: Instead of counting errors you could just return early.
    int failCount = 0;
    
    // Verify all the receipt specifics to ensure everything matches up as expected
    if (![[verifiedReceiptReceiptDictionary objectForKey:@"bid"]
          isEqualToString:[purchaseInfoFromTransaction objectForKey:@"bid"]])
    {
        failCount++;
    }
    
    if (![[verifiedReceiptReceiptDictionary objectForKey:@"product_id"]
          isEqualToString:[purchaseInfoFromTransaction objectForKey:@"product-id"]])
    {
        failCount++;
    }
    
    if (![[verifiedReceiptReceiptDictionary objectForKey:@"quantity"]
          isEqualToString:[purchaseInfoFromTransaction objectForKey:@"quantity"]])
    {
        failCount++;
    }
    
    if (![[verifiedReceiptReceiptDictionary objectForKey:@"item_id"]
          isEqualToString:[purchaseInfoFromTransaction objectForKey:@"item-id"]])
    {
        failCount++;
    }
    
    if ([[UIDevice currentDevice] respondsToSelector:NSSelectorFromString(@"identifierForVendor")]) // iOS 6?
    {
#if IS_IOS6_AWARE
        // iOS 6 (or later)
        NSString *localIdentifier                   = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        NSString *purchaseInfoUniqueVendorId        = [purchaseInfoFromTransaction objectForKey:@"unique-vendor-identifier"];
        NSString *verifiedReceiptVendorIdentifier   = [verifiedReceiptReceiptDictionary objectForKey:@"unique_vendor_identifier"];
        
        
        if(verifiedReceiptVendorIdentifier)
        {
            if (![purchaseInfoUniqueVendorId isEqualToString:verifiedReceiptVendorIdentifier]
                || ![purchaseInfoUniqueVendorId isEqualToString:localIdentifier])
            {
                // Comment this line out to test in the Simulator.
                failCount++;
            }
        }
#endif
    } else {
        // Pre iOS 6 
        NSString *localIdentifier           = [UIDevice currentDevice].uniqueIdentifier;
        NSString *purchaseInfoUniqueId      = [purchaseInfoFromTransaction objectForKey:@"unique-identifier"];

        
        if (![purchaseInfoUniqueId isEqualToString:verifiedReceiptUniqueIdentifier]
            || ![purchaseInfoUniqueId isEqualToString:localIdentifier])
        {
            // Comment this line out to test in the Simulator.
            failCount++;
        }        
    }
    
    
    // Do addition time checks for the transaction and receipt.
    
    if(failCount != 0)
    {
        return NO;
    }
    
    return YES;
}


#pragma mark NSURLConnectionDelegate (for the verifyReceipt connection)

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // So we got some receipt data. Now does it all check out?
    BOOL isOk = [self doesTransactionInfoMatchReceipt:responseString];
    
    if (isOk)
    {
        //Validation suceeded. Unlock content here.
#warning Validation suceeded. Unlock content here.

    }
}


- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([[[challenge protectionSpace] authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        SecTrustRef trust = [[challenge protectionSpace] serverTrust];
        NSError *error = nil;
        BOOL didUseCredential = NO;
        BOOL isTrusted = [self validateTrust:trust error:&error];
        if (isTrusted)
        {
            NSURLCredential *trust_credential = [NSURLCredential credentialForTrust:trust];
            if (trust_credential)
            {
                [[challenge sender] useCredential:trust_credential forAuthenticationChallenge:challenge];
                didUseCredential = YES;
            }
        }
        if (!didUseCredential)
        {
            [[challenge sender] cancelAuthenticationChallenge:challenge];
        }
    } else {
        [[challenge sender] performDefaultHandlingForAuthenticationChallenge:challenge];
    }
}

// NOTE: These are needed for 4.x (as willSendRequestForAuthenticationChallenge: is not supported)
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [[protectionSpace authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust];
}


- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([[[challenge protectionSpace] authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        SecTrustRef trust = [[challenge protectionSpace] serverTrust];
        NSError *error = nil;
        BOOL didUseCredential = NO;
        BOOL isTrusted = [self validateTrust:trust error:&error];
        if (isTrusted)
        {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:trust];
            if (credential)
            {
                [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
                didUseCredential = YES;
            }
		}
        if (! didUseCredential) {
            [[challenge sender] cancelAuthenticationChallenge:challenge];
        }
    } else {
        [[challenge sender] performDefaultHandlingForAuthenticationChallenge:challenge];
    }
}


#pragma mark
#pragma mark NSURLConnection - Trust validation

- (BOOL)validateTrust:(SecTrustRef)trust error:(NSError **)error
{
    
    // Include some Security framework SPIs
    extern CFStringRef kSecTrustInfoExtendedValidationKey;
    extern CFDictionaryRef SecTrustCopyInfo(SecTrustRef trust);
    
    BOOL trusted = NO;
    SecTrustResultType trust_result;
    if ((noErr == SecTrustEvaluate(trust, &trust_result)) && (trust_result == kSecTrustResultUnspecified))
    {
        NSDictionary *trust_info = (__bridge_transfer NSDictionary *)SecTrustCopyInfo(trust);
        id hasEV = [trust_info objectForKey:(__bridge NSString *)kSecTrustInfoExtendedValidationKey];
        trusted =  [hasEV isKindOfClass:[NSValue class]] && [hasEV boolValue];
    }
    
    if (trust)
    {
        if (!trusted && error)
        {
            *error = [NSError errorWithDomain:@"kSecTrustError" code:(NSInteger)trust_result userInfo:nil];
        }
        return trusted;
    }
    return NO;
}


#pragma mark
#pragma mark Check Receipt signature

#include <CommonCrypto/CommonDigest.h>
#include <Security/Security.h>
#include <AssertMacros.h>
unsigned int iTS_intermediate_der_len = 1039;

unsigned char iTS_intermediate_der[] = {
    0x30, 0x82, 0x04, 0x0b, 0x30, 0x82, 0x02, 0xf3, 0xa0, 0x03, 0x02, 0x01,
    0x02, 0x02, 0x01, 0x1a, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
    0xf7, 0x0d, 0x01, 0x01, 0x05, 0x05, 0x00, 0x30, 0x62, 0x31, 0x0b, 0x30,
    0x09, 0x06, 0x03, 0x55, 0x04, 0x06, 0x13, 0x02, 0x55, 0x53, 0x31, 0x13,
    0x30, 0x11, 0x06, 0x03, 0x55, 0x04, 0x0a, 0x13, 0x0a, 0x41, 0x70, 0x70,
    0x6c, 0x65, 0x20, 0x49, 0x6e, 0x63, 0x2e, 0x31, 0x26, 0x30, 0x24, 0x06,
    0x03, 0x55, 0x04, 0x0b, 0x13, 0x1d, 0x41, 0x70, 0x70, 0x6c, 0x65, 0x20,
    0x43, 0x65, 0x72, 0x74, 0x69, 0x66, 0x69, 0x63, 0x61, 0x74, 0x69, 0x6f,
    0x6e, 0x20, 0x41, 0x75, 0x74, 0x68, 0x6f, 0x72, 0x69, 0x74, 0x79, 0x31,
    0x16, 0x30, 0x14, 0x06, 0x03, 0x55, 0x04, 0x03, 0x13, 0x0d, 0x41, 0x70,
    0x70, 0x6c, 0x65, 0x20, 0x52, 0x6f, 0x6f, 0x74, 0x20, 0x43, 0x41, 0x30,
    0x1e, 0x17, 0x0d, 0x30, 0x39, 0x30, 0x35, 0x31, 0x39, 0x31, 0x38, 0x33,
    0x31, 0x33, 0x30, 0x5a, 0x17, 0x0d, 0x31, 0x36, 0x30, 0x35, 0x31, 0x38,
    0x31, 0x38, 0x33, 0x31, 0x33, 0x30, 0x5a, 0x30, 0x7f, 0x31, 0x0b, 0x30,
    0x09, 0x06, 0x03, 0x55, 0x04, 0x06, 0x13, 0x02, 0x55, 0x53, 0x31, 0x13,
    0x30, 0x11, 0x06, 0x03, 0x55, 0x04, 0x0a, 0x0c, 0x0a, 0x41, 0x70, 0x70,
    0x6c, 0x65, 0x20, 0x49, 0x6e, 0x63, 0x2e, 0x31, 0x26, 0x30, 0x24, 0x06,
    0x03, 0x55, 0x04, 0x0b, 0x0c, 0x1d, 0x41, 0x70, 0x70, 0x6c, 0x65, 0x20,
    0x43, 0x65, 0x72, 0x74, 0x69, 0x66, 0x69, 0x63, 0x61, 0x74, 0x69, 0x6f,
    0x6e, 0x20, 0x41, 0x75, 0x74, 0x68, 0x6f, 0x72, 0x69, 0x74, 0x79, 0x31,
    0x33, 0x30, 0x31, 0x06, 0x03, 0x55, 0x04, 0x03, 0x0c, 0x2a, 0x41, 0x70,
    0x70, 0x6c, 0x65, 0x20, 0x69, 0x54, 0x75, 0x6e, 0x65, 0x73, 0x20, 0x53,
    0x74, 0x6f, 0x72, 0x65, 0x20, 0x43, 0x65, 0x72, 0x74, 0x69, 0x66, 0x69,
    0x63, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x20, 0x41, 0x75, 0x74, 0x68, 0x6f,
    0x72, 0x69, 0x74, 0x79, 0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09,
    0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03,
    0x82, 0x01, 0x0f, 0x00, 0x30, 0x82, 0x01, 0x0a, 0x02, 0x82, 0x01, 0x01,
    0x00, 0xa4, 0xbc, 0xaf, 0x32, 0x94, 0x43, 0x3e, 0x0b, 0xbc, 0x37, 0x87,
    0xcd, 0x63, 0x89, 0xf2, 0xcc, 0xd9, 0xbe, 0x20, 0x4d, 0x5a, 0xb4, 0xfe,
    0x87, 0x67, 0xd2, 0x9a, 0xde, 0x1a, 0x54, 0x9d, 0xa2, 0xf3, 0xdf, 0x87,
    0xe4, 0x4c, 0xcb, 0x93, 0x11, 0x78, 0xa0, 0x30, 0x8f, 0x34, 0x41, 0xc1,
    0xd3, 0xbe, 0x66, 0x6d, 0x47, 0x6c, 0x98, 0xb8, 0xec, 0x7a, 0xd5, 0xc9,
    0xdd, 0xa5, 0xe4, 0xea, 0xc6, 0x70, 0xf4, 0x35, 0xd0, 0x91, 0xf7, 0xb3,
    0xd8, 0x0a, 0x11, 0x99, 0xab, 0x3a, 0x62, 0x3a, 0xbd, 0x7b, 0xf4, 0x56,
    0x4f, 0xdb, 0x9f, 0x24, 0x93, 0x51, 0x50, 0x7c, 0x20, 0xd5, 0x66, 0x4d,
    0x66, 0xf3, 0x18, 0xa4, 0x13, 0x96, 0x22, 0x16, 0xfd, 0x31, 0xa7, 0xf4,
    0x39, 0x66, 0x9b, 0xfb, 0x62, 0x69, 0x5c, 0x4b, 0x9f, 0x94, 0xa8, 0x4b,
    0xe8, 0xec, 0x5b, 0x64, 0x5a, 0x18, 0x79, 0x8a, 0x16, 0x75, 0x63, 0x42,
    0xa4, 0x49, 0xd9, 0x8c, 0x33, 0xde, 0xad, 0x7b, 0xd6, 0x39, 0x04, 0xf4,
    0xe2, 0x9d, 0x0a, 0x69, 0x8c, 0xeb, 0x4b, 0x12, 0x28, 0x4b, 0x34, 0x48,
    0x07, 0x9b, 0x0e, 0x59, 0xf9, 0x1f, 0x62, 0xb0, 0x03, 0x9f, 0x36, 0xb8,
    0x4e, 0xa3, 0xd3, 0x75, 0x59, 0xd4, 0xf3, 0x3a, 0x05, 0xca, 0xc5, 0x33,
    0x3b, 0xf8, 0xc0, 0x06, 0x09, 0x08, 0x93, 0xdb, 0xe7, 0x4d, 0xbf, 0x11,
    0xf3, 0x52, 0x2c, 0xa5, 0x16, 0x35, 0x15, 0xf3, 0x41, 0x02, 0xcd, 0x02,
    0xd1, 0xfc, 0xf5, 0xf8, 0xc5, 0x84, 0xbd, 0x63, 0x6a, 0x86, 0xd6, 0xb6,
    0x99, 0xf6, 0x86, 0xae, 0x5f, 0xfd, 0x03, 0xd4, 0x28, 0x8a, 0x5a, 0x5d,
    0xaf, 0xbc, 0x65, 0x74, 0xd1, 0xf7, 0x1a, 0xc3, 0x92, 0x08, 0xf4, 0x1c,
    0xad, 0x69, 0xe8, 0x02, 0x4c, 0x0e, 0x95, 0x15, 0x07, 0xbc, 0xbe, 0x6a,
    0x6f, 0xc1, 0xb3, 0xad, 0xa1, 0x02, 0x03, 0x01, 0x00, 0x01, 0xa3, 0x81,
    0xae, 0x30, 0x81, 0xab, 0x30, 0x0e, 0x06, 0x03, 0x55, 0x1d, 0x0f, 0x01,
    0x01, 0xff, 0x04, 0x04, 0x03, 0x02, 0x01, 0x86, 0x30, 0x0f, 0x06, 0x03,
    0x55, 0x1d, 0x13, 0x01, 0x01, 0xff, 0x04, 0x05, 0x30, 0x03, 0x01, 0x01,
    0xff, 0x30, 0x1d, 0x06, 0x03, 0x55, 0x1d, 0x0e, 0x04, 0x16, 0x04, 0x14,
    0x36, 0x1d, 0xe8, 0xe2, 0x9d, 0x82, 0xd2, 0x01, 0x18, 0xb5, 0x32, 0x6b,
    0x0e, 0xd7, 0x43, 0x0b, 0x91, 0x58, 0x43, 0x3a, 0x30, 0x1f, 0x06, 0x03,
    0x55, 0x1d, 0x23, 0x04, 0x18, 0x30, 0x16, 0x80, 0x14, 0x2b, 0xd0, 0x69,
    0x47, 0x94, 0x76, 0x09, 0xfe, 0xf4, 0x6b, 0x8d, 0x2e, 0x40, 0xa6, 0xf7,
    0x47, 0x4d, 0x7f, 0x08, 0x5e, 0x30, 0x36, 0x06, 0x03, 0x55, 0x1d, 0x1f,
    0x04, 0x2f, 0x30, 0x2d, 0x30, 0x2b, 0xa0, 0x29, 0xa0, 0x27, 0x86, 0x25,
    0x68, 0x74, 0x74, 0x70, 0x3a, 0x2f, 0x2f, 0x77, 0x77, 0x77, 0x2e, 0x61,
    0x70, 0x70, 0x6c, 0x65, 0x2e, 0x63, 0x6f, 0x6d, 0x2f, 0x61, 0x70, 0x70,
    0x6c, 0x65, 0x63, 0x61, 0x2f, 0x72, 0x6f, 0x6f, 0x74, 0x2e, 0x63, 0x72,
    0x6c, 0x30, 0x10, 0x06, 0x0a, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x63, 0x64,
    0x06, 0x02, 0x02, 0x04, 0x02, 0x05, 0x00, 0x30, 0x0d, 0x06, 0x09, 0x2a,
    0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x05, 0x05, 0x00, 0x03, 0x82,
    0x01, 0x01, 0x00, 0x75, 0xa6, 0x90, 0xe6, 0x9a, 0xa7, 0xdb, 0x65, 0x70,
    0xa6, 0x09, 0x93, 0x6f, 0x08, 0xdf, 0x2c, 0xdb, 0xe9, 0x28, 0x8d, 0x40,
    0x1b, 0x57, 0x5e, 0xa0, 0xea, 0xf4, 0xec, 0x13, 0x65, 0x1b, 0x71, 0x4a,
    0x4d, 0xdc, 0x80, 0x48, 0x4f, 0xf2, 0xe5, 0xa9, 0xfb, 0x85, 0x6c, 0xb7,
    0x1e, 0x9d, 0xdb, 0xf4, 0x18, 0x48, 0x10, 0x79, 0x17, 0xea, 0xc3, 0x3d,
    0x87, 0xd8, 0xb4, 0x79, 0x6d, 0x14, 0x50, 0xad, 0xd2, 0xbf, 0x3d, 0x4e,
    0xfc, 0x0d, 0xe2, 0xc5, 0x03, 0x94, 0x75, 0x80, 0x73, 0x4d, 0xa5, 0xa1,
    0x91, 0xfe, 0x1c, 0xde, 0x15, 0x17, 0xac, 0x89, 0x71, 0x2a, 0x6f, 0x0f,
    0x67, 0x0a, 0xd3, 0x9c, 0x30, 0xa1, 0x68, 0xfb, 0xcf, 0x70, 0x17, 0xca,
    0xd9, 0x40, 0xfc, 0xf8, 0x1b, 0xbf, 0xce, 0xb0, 0xc4, 0xae, 0xf4, 0x4a,
    0x2d, 0xa9, 0x99, 0x87, 0x06, 0x42, 0x09, 0x86, 0x22, 0x6a, 0x84, 0x40,
    0x39, 0xf4, 0xbb, 0xac, 0x56, 0x18, 0xf7, 0x9a, 0x1c, 0x01, 0x81, 0x5c,
    0x8c, 0x6e, 0x41, 0xf2, 0x5d, 0x19, 0x2c, 0x17, 0x1c, 0x49, 0x46, 0xd9,
    0x1c, 0x7e, 0x93, 0x12, 0x13, 0xc8, 0x67, 0x99, 0xc2, 0xea, 0x83, 0xe3,
    0xa2, 0x8c, 0x0e, 0xb8, 0x3b, 0x2a, 0xdf, 0x1c, 0xbf, 0x4b, 0x8b, 0x6f,
    0x1a, 0xb8, 0xee, 0x97, 0x67, 0x4a, 0xd8, 0xab, 0xaf, 0x8b, 0xa4, 0xda,
    0x5c, 0x87, 0x1e, 0x20, 0xb8, 0xc5, 0xf3, 0xb1, 0xc4, 0x98, 0xa2, 0x37,
    0xf8, 0x9e, 0xc6, 0x9a, 0x6b, 0xa5, 0xad, 0xf6, 0x78, 0x96, 0x0e, 0x82,
    0x8f, 0x04, 0x46, 0x1c, 0xb2, 0xa5, 0xfd, 0x9a, 0x30, 0x51, 0x28, 0xfd,
    0x52, 0x04, 0x15, 0x03, 0xd5, 0x3c, 0xad, 0xfe, 0xf6, 0x78, 0xe0, 0xea,
    0x35, 0xef, 0x65, 0xb5, 0x21, 0x76, 0xdb, 0xa4, 0xef, 0xcb, 0x72, 0xef,
    0x54, 0x6b, 0x01, 0x0d, 0xc7, 0xdd, 0x1a
};


BOOL checkReceiptSecurity(NSString *purchase_info_string, NSString *signature_string, CFDateRef purchaseDate)
{
    BOOL valid = NO;
    SecCertificateRef leaf = NULL, intermediate = NULL;
    SecTrustRef trust = NULL;
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    
    NSData *certificate_data;
    NSArray *anchors;
    
    /*
     Parse inputs:
     purchase_info_string and signature_string are base64 encoded JSON blobs that need to
     be decoded.
     */
    
    require([purchase_info_string canBeConvertedToEncoding:NSASCIIStringEncoding] &&
            [signature_string canBeConvertedToEncoding:NSASCIIStringEncoding], outLabel);
    
    size_t purchase_info_length;
    uint8_t *purchase_info_bytes = base64_decode([purchase_info_string cStringUsingEncoding:NSASCIIStringEncoding],
                                                 &purchase_info_length);
    
    size_t signature_length;
    uint8_t *signature_bytes = base64_decode([signature_string cStringUsingEncoding:NSASCIIStringEncoding],
                                             &signature_length);
    
    require(purchase_info_bytes && signature_bytes, outLabel);
    
    /*
     Binary format looks as follows:
     
     RECEIPTVERSION | SIGNATURE | CERTIFICATE SIZE | CERTIFICATE
     1 byte           128         4 bytes
     big endian
     
     Extract version, signature and certificate(s).
     Check receipt version == 2.
     Sanity check that signature is 128 bytes.
     Sanity check certificate size <= remaining payload data.
     */
    
#pragma pack(push, 1)
    struct signature_blob {
        uint8_t version;
        uint8_t signature[128];
        uint32_t cert_len;
        uint8_t certificate[];
    } *signature_blob_ptr = (struct signature_blob *)signature_bytes;
#pragma pack(pop)
    uint32_t certificate_len;
    
    /*
     Make sure the signature blob is long enough to safely extract the version and
     cert_len fields, then perform a sanity check on the fields.
     */
    require(signature_length > offsetof(struct signature_blob, certificate), outLabel);
    require(signature_blob_ptr->version == 2, outLabel);
    certificate_len = ntohl(signature_blob_ptr->cert_len);
    
    require(signature_length - offsetof(struct signature_blob, certificate) >= certificate_len, outLabel);
    
    /*
     Validate certificate chains back to valid receipt signer; policy approximation for now
     set intermediate as a trust anchor; current intermediate lapses in 2016.
     */
    
    certificate_data = [NSData dataWithBytes:signature_blob_ptr->certificate length:certificate_len];
    require(leaf = SecCertificateCreateWithData(NULL, (__bridge CFDataRef) certificate_data), outLabel);
    
    certificate_data = [NSData dataWithBytes:iTS_intermediate_der length:iTS_intermediate_der_len];
    require(intermediate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef) certificate_data), outLabel);
    
    anchors = [NSArray arrayWithObject:(__bridge id)intermediate];
    require(anchors, outLabel);
    
    require_noerr(SecTrustCreateWithCertificates(leaf, policy, &trust), outLabel);
    require_noerr(SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef) anchors), outLabel);
    
    if (purchaseDate)
    {
        require_noerr(SecTrustSetVerifyDate(trust, purchaseDate), outLabel);
    }
    
    SecTrustResultType trust_result;
    require_noerr(SecTrustEvaluate(trust, &trust_result), outLabel);
    require(trust_result == kSecTrustResultUnspecified, outLabel);
    
    require(2 == SecTrustGetCertificateCount(trust), outLabel);
    
    /*
     Chain is valid, use leaf key to verify signature on receipt by
     calculating SHA1(version|purchaseInfo)
     */
    
    CC_SHA1_CTX sha1_ctx;
    uint8_t to_be_verified_data[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1_Init(&sha1_ctx);
    CC_SHA1_Update(&sha1_ctx, &signature_blob_ptr->version, sizeof(signature_blob_ptr->version));
    CC_SHA1_Update(&sha1_ctx, purchase_info_bytes, purchase_info_length);
    CC_SHA1_Final(to_be_verified_data, &sha1_ctx);
    
    SecKeyRef receipt_signing_key = SecTrustCopyPublicKey(trust);
    require(receipt_signing_key, outLabel);
    require_noerr(SecKeyRawVerify(receipt_signing_key, kSecPaddingPKCS1SHA1,
                                  to_be_verified_data, sizeof(to_be_verified_data),
                                  signature_blob_ptr->signature, sizeof(signature_blob_ptr->signature)),
                  outLabel);
    
    /*
     Optional:  Verify that the receipt certificate has the 1.2.840.113635.100.6.5.1 Null OID
     
     The signature is a 1024-bit RSA signature.
     */
    
    valid = YES;
    
outLabel:
    if (leaf) CFRelease(leaf);
    if (intermediate) CFRelease(intermediate);
    if (trust) CFRelease(trust);
    if (policy) CFRelease(policy);
    
    return valid;
}




#pragma mark
#pragma mark Base 64 encoding



- (NSString *)encodeBase64:(const uint8_t *)input length:(NSInteger)length
{
#warning Replace this method.
    return nil;
}


- (NSString *)decodeBase64:(NSString *)input length:(NSInteger *)length
{
#warning Replace this method.
    return nil;
}

#warning Implement this function.
char* base64_encode(const void* buf, size_t size)
{ return NULL; }

#warning Implement this function.
void * base64_decode(const char* s, size_t * data_len)
{ return NULL; }


@end
