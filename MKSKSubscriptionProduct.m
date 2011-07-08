//
//  MKSKSubscriptionProduct.m
//  MKStoreKitDemo
//  Version 4.0
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


#import "MKSKSubscriptionProduct.h"
#import "NSData+Base64.h"

@implementation MKSKSubscriptionProduct
@synthesize onSubscriptionVerificationFailed;
@synthesize onSubscriptionVerificationCompleted;
@synthesize receipt;
@synthesize subscriptionDays;
@synthesize theConnection;
@synthesize dataFromConnection;
@synthesize productId;
@synthesize verifiedReceiptDictionary;

-(id) initWithProductId:(NSString*) aProductId subscriptionDays:(int) days
{
    if((self = [super init]))
    {
        self.productId = aProductId;
        self.subscriptionDays = days;
    }
    
    return self;
}

- (void) verifyReceiptOnComplete:(void (^)(NSNumber*)) completionBlock
                         onError:(void (^)(NSError*)) errorBlock
{        
    self.onSubscriptionVerificationCompleted = completionBlock;
    self.onSubscriptionVerificationFailed = errorBlock;
    
    NSURL *url = [NSURL URLWithString:kReceiptValidationURL];
	
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url 
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                                          timeoutInterval:60];
	
	[theRequest setHTTPMethod:@"POST"];		
	[theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	
    NSString *receiptString = [NSString stringWithFormat:@"{\"receipt-data\":\"%@\" \"password\":\"%@\"}", [self.receipt base64EncodedString], kSharedSecret];        
    
	NSString *length = [NSString stringWithFormat:@"%d", [receiptString length]];	
	[theRequest setValue:length forHTTPHeaderField:@"Content-Length"];	
	
	[theRequest setHTTPBody:[receiptString dataUsingEncoding:NSUTF8StringEncoding]];
	
    self.theConnection = [NSURLConnection connectionWithRequest:theRequest delegate:self];    
    [self.theConnection start];    
}

-(BOOL) isSubscriptionActive
{
    NSString *purchasedDateString = [[self.verifiedReceiptDictionary objectForKey:@"receipt"] objectForKey:@"purchase_date"];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];

    //2011-07-03 05:31:55 Etc/GMT
    purchasedDateString = [purchasedDateString stringByReplacingOccurrencesOfString:@" Etc/GMT" withString:@""];    
    NSLocale *POSIXLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
    [df setLocale:POSIXLocale];
    [df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];    
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDate *purchasedDate = [df dateFromString: purchasedDateString];
    [df release];
    
    int numberOfDays = [purchasedDate timeIntervalSinceNow] / (-86400.0);    
    return (self.subscriptionDays > numberOfDays);
}


#pragma mark -
#pragma mark NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{	
    self.dataFromConnection = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data
{
	[self.dataFromConnection appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.verifiedReceiptDictionary = [[[self.dataFromConnection copy] autorelease] objectFromJSONData];                                              
    if(self.onSubscriptionVerificationCompleted)
    {
        self.onSubscriptionVerificationCompleted([NSNumber numberWithBool:[self isSubscriptionActive]]);
        self.dataFromConnection = nil;
    }
    
    self.onSubscriptionVerificationCompleted = nil;
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    self.dataFromConnection = nil;
    if(self.onSubscriptionVerificationFailed)
        self.onSubscriptionVerificationFailed(error);
    
    self.onSubscriptionVerificationFailed = nil;
}

@end
