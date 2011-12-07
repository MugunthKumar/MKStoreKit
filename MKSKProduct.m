//
//  MKSKProduct.m
//  MKStoreKitDemo
//  Version 4.1
//
//  Created by Mugunth on 04/07/11.
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

#import "MKSKProduct.h"

static void (^onReviewRequestVerificationSucceeded)();
static void (^onReviewRequestVerificationFailed)();
static NSURLConnection *sConnection;
static NSMutableData *sDataFromConnection;

@implementation MKSKProduct
@synthesize onReceiptVerificationFailed;
@synthesize onReceiptVerificationSucceeded;
@synthesize receipt;
@synthesize productId;
@synthesize theConnection;
@synthesize dataFromConnection;

+(NSString*) deviceId {
    
#if TARGET_OS_IPHONE
    UIDevice *dev = [UIDevice currentDevice];
    NSString *uniqueID;
    if ([dev respondsToSelector:@selector(uniqueIdentifier)])
        uniqueID = [dev valueForKey:@"uniqueIdentifier"];
    else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        id uuid = [defaults objectForKey:@"uniqueID"];
        if (uuid)
            uniqueID = (NSString *)uuid;
        else {
            CFStringRef cfUuid = CFUUIDCreateString(NULL, CFUUIDCreate(NULL));
            uniqueID = (__bridge NSString *)cfUuid;
            CFRelease(cfUuid);
            [defaults setObject:uniqueID forKey:@"uniqueID"];
        }
    }
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
	
	NSString *receiptDataString = [[NSString alloc] initWithData:self.receipt 
                                                        encoding:NSASCIIStringEncoding];
    
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
