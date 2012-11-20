//
//  MKSKProduct.m
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

#import "MKSKProduct.h"

#import "NSData+MKBase64.h"

#if ! __has_feature(objc_arc)
#error MKStoreKit is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#ifndef __IPHONE_5_0
#error "MKStoreKit uses features (NSJSONSerialization) only available in iOS SDK  and later."
#endif

static void (^onReviewRequestVerificationSucceeded)();
static void (^onReviewRequestVerificationFailed)();
static NSURLConnection *sConnection;
static NSMutableData *sDataFromConnection;

@implementation MKSKProduct

+(NSString*) deviceId {
  
#if TARGET_OS_IPHONE
  NSString *uniqueID;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  id uuid = [defaults objectForKey:@"uniqueID"];
  if (uuid)
    uniqueID = (NSString *)uuid;
  else {
    CFUUIDRef cfUuid = CFUUIDCreate(NULL);
    CFStringRef cfUuidString = CFUUIDCreateString(NULL, cfUuid);
    CFRelease(cfUuid);
    uniqueID = (__bridge NSString *)cfUuidString;
    [defaults setObject:uniqueID forKey:@"uniqueID"];
    CFRelease(cfUuidString);
  }
  
  return uniqueID;
#elif TARGET_OS_MAC 
  
  kern_return_t			 kernResult;
	mach_port_t			   master_port;
	CFMutableDictionaryRef	matchingDict;
	io_iterator_t			 iterator;
	io_object_t			   service;
	CFDataRef				 macAddress = nil;
  
	kernResult = IOMasterPort(MACH_PORT_NULL, &master_port);
	if (kernResult != KERN_SUCCESS) {
		printf("IOMasterPort returned %d\n", kernResult);
		return nil;
	}
  
	matchingDict = IOBSDNameMatching(master_port, 0, "en0");
	if(!matchingDict) {
		printf("IOBSDNameMatching returned empty dictionary\n");
		return nil;
	}
  
	kernResult = IOServiceGetMatchingServices(master_port, matchingDict, &iterator);
	if (kernResult != KERN_SUCCESS) {
		printf("IOServiceGetMatchingServices returned %d\n", kernResult);
		return nil;
	}
  
	while((service = IOIteratorNext(iterator)) != 0)
	{
		io_object_t		parentService;
    
		kernResult = IORegistryEntryGetParentEntry(service, kIOServicePlane, &parentService);
		if(kernResult == KERN_SUCCESS)
		{
      if(macAddress)
        CFRelease(macAddress);
			macAddress = IORegistryEntryCreateCFProperty(parentService, CFSTR("IOMACAddress"), kCFAllocatorDefault, 0);
			IOObjectRelease(parentService);
		}
		else {
			printf("IORegistryEntryGetParentEntry returned %d\n", kernResult);
		}
    
		IOObjectRelease(service);
	}
  
	return [[NSString alloc] initWithData:(__bridge NSData*) macAddress encoding:NSASCIIStringEncoding];
#endif
}

-(id) initWithProductId:(NSString*) aProductId receiptData:(NSData*) aReceipt
{
  if((self = [super init]))
  {
    self.productId = aProductId;
    self.receipt = aReceipt;
  }
  return self;
}

#pragma mark -
#pragma mark In-App purchases promo codes support
// This function is only used if you want to enable in-app purchases for free for reviewers
// Read my blog post http://mk.sg/31

+(void) verifyProductForReviewAccess:(NSString*) productId
                          onComplete:(void (^)(NSNumber*)) completionBlock
                             onError:(void (^)(NSError*)) errorBlock
{
  if(REVIEW_ALLOWED)
  {
    onReviewRequestVerificationSucceeded = [completionBlock copy];
    onReviewRequestVerificationFailed = [errorBlock copy];
    
    NSString *uniqueID = [self deviceId];
    // check udid and featureid with developer's server
		
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", OWN_SERVER, @"featureCheck.php"]];
    
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url 
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                                          timeoutInterval:60];
    
    [theRequest setHTTPMethod:@"POST"];		
    [theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSString *postData = [NSString stringWithFormat:@"productid=%@&udid=%@", productId, uniqueID];
    
    NSString *length = [NSString stringWithFormat:@"%d", [postData length]];	
    [theRequest setValue:length forHTTPHeaderField:@"Content-Length"];	
    
    [theRequest setHTTPBody:[postData dataUsingEncoding:NSASCIIStringEncoding]];
    
    sConnection = [NSURLConnection connectionWithRequest:theRequest delegate:self];    
    [sConnection start];	
  }
  else
  {
    completionBlock([NSNumber numberWithBool:NO]);
  }
}

- (void) verifyReceiptOnComplete:(void (^)(void)) completionBlock
                         onError:(void (^)(NSError*)) errorBlock
{
  self.onReceiptVerificationSucceeded = completionBlock;
  self.onReceiptVerificationFailed = errorBlock;
  
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", OWN_SERVER, @"verifyProduct.php"]];
	
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url 
                                                            cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                                        timeoutInterval:60];
	
	[theRequest setHTTPMethod:@"POST"];		
	[theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	
	NSString *receiptDataString = [self.receipt base64EncodedString];
  
	NSString *postData = [NSString stringWithFormat:@"receiptdata=%@", receiptDataString];
	
	NSString *length = [NSString stringWithFormat:@"%d", [postData length]];	
	[theRequest setValue:length forHTTPHeaderField:@"Content-Length"];	
	
	[theRequest setHTTPBody:[postData dataUsingEncoding:NSASCIIStringEncoding]];
	
  self.theConnection = [NSURLConnection connectionWithRequest:theRequest delegate:self];    
  [self.theConnection start];	
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
  NSString *responseString = [[NSString alloc] initWithData:self.dataFromConnection 
                                                   encoding:NSASCIIStringEncoding];
  responseString = [responseString stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  self.dataFromConnection = nil;
	if([responseString isEqualToString:@"YES"])		
	{
    if(self.onReceiptVerificationSucceeded)
    {
      self.onReceiptVerificationSucceeded();
      self.onReceiptVerificationSucceeded = nil;
    }
	}
  else
  {
    if(self.onReceiptVerificationFailed)
    {
      self.onReceiptVerificationFailed(nil);
      self.onReceiptVerificationFailed = nil;
    }
  }
	
  
}


- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
  
  self.dataFromConnection = nil;
  if(self.onReceiptVerificationFailed)
  {
    self.onReceiptVerificationFailed(nil);
    self.onReceiptVerificationFailed = nil;
  }
}



+ (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{	
  sDataFromConnection = [[NSMutableData alloc] init];
}

+ (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data
{
	[sDataFromConnection appendData:data];
}

+ (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  NSString *responseString = [[NSString alloc] initWithData:sDataFromConnection 
                                                   encoding:NSASCIIStringEncoding];
  responseString = [responseString stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  sDataFromConnection = nil;
  
	if([responseString isEqualToString:@"YES"])		
	{
    if(onReviewRequestVerificationSucceeded)
    {
      onReviewRequestVerificationSucceeded();
      onReviewRequestVerificationFailed = nil;
    }
	}
  else
  {
    if(onReviewRequestVerificationFailed)
      onReviewRequestVerificationFailed(nil);
    
    onReviewRequestVerificationFailed = nil;
  }
	
  
}

+ (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
  sDataFromConnection = nil;
  
  if(onReviewRequestVerificationFailed)
  {
    onReviewRequestVerificationFailed(nil);    
    onReviewRequestVerificationFailed = nil;
  }
}
@end
