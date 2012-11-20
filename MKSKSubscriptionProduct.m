//
//  MKSKSubscriptionProduct.m
//  MKStoreKit (Version 5.0)
//
//  Created by Mugunth Kumar (@mugunthkumar) on 04/07/11.
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


#import "MKSKSubscriptionProduct.h"
#import "NSData+MKBase64.h"
#if ! __has_feature(objc_arc)
#error MKStoreKit is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#ifndef __IPHONE_5_0
#error "MKStoreKit uses features (NSJSONSerialization) only available in iOS SDK  and later."
#endif

@implementation MKSKSubscriptionProduct

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
  if(!self.receipt) return NO;
  if([[self.verifiedReceiptDictionary objectForKey:@"receipt"] objectForKey:@"expires_date"]){
    
    NSTimeInterval expiresDate = [[[self.verifiedReceiptDictionary objectForKey:@"receipt"] objectForKey:@"expires_date"] doubleValue]/1000.0;        
    return expiresDate > [[NSDate date] timeIntervalSince1970];
    
	}else{
    
    NSString *purchasedDateString = [[self.verifiedReceiptDictionary objectForKey:@"receipt"] objectForKey:@"purchase_date"];        
    if(!purchasedDateString) {
      NSLog(@"Receipt Dictionary from Apple Server is invalid: %@", self.verifiedReceiptDictionary);
      return NO;
    }
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    //2011-07-03 05:31:55 Etc/GMT
    purchasedDateString = [purchasedDateString stringByReplacingOccurrencesOfString:@" Etc/GMT" withString:@""];    
    NSLocale *POSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [df setLocale:POSIXLocale];        
    [df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];            
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *purchasedDate = [df dateFromString: purchasedDateString];        
    int numberOfDays = [purchasedDate timeIntervalSinceNow] / (-86400.0);            
    return (self.subscriptionDays > numberOfDays);        
  }
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

-(NSDictionary*) verifiedReceiptDictionary {
  
  return [NSJSONSerialization JSONObjectWithData:self.receipt options:NSJSONReadingAllowFragments error:nil];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  self.receipt = [self.dataFromConnection copy];
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
