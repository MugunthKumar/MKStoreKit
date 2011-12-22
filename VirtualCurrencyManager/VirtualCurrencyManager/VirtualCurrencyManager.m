//
//  VirtualCurrencyManager.m
//  VirtualCurrencyManager
//
//  Created by Carlos Sessa on 12/20/11.
//  Copyright (c) 2011 NASA Trained Monkeys. All rights reserved.
//

#import "VirtualCurrencyManager.h"
#import "SFHFKeychainUtils.h"

static VirtualCurrencyManager *_sharedVirtualCurrencyManager;


@interface VirtualCurrencyManager () //private methods and properties
@property (nonatomic, strong) NSDictionary *purchasableObjects;
@end


@implementation VirtualCurrencyManager

@synthesize purchasableObjects, currency = _currency;


#pragma mark Singleton Methods

+ (VirtualCurrencyManager *)sharedManager
{
	if(!_sharedVirtualCurrencyManager) {
		static dispatch_once_t oncePredicate;
		dispatch_once(&oncePredicate, ^{
			_sharedVirtualCurrencyManager = [[super allocWithZone:nil] init];            
        });
        
        _sharedVirtualCurrencyManager = [[self alloc] init];					        
    }
    
    return _sharedVirtualCurrencyManager;
}

+ (id)allocWithZone:(NSZone *)zone
{	
    return [self sharedManager];
}


- (id)copyWithZone:(NSZone *)zone
{
    return self;	
}

+(id) objectForKey:(NSString*) key
{
    NSError *error = nil;
    NSObject *object = [SFHFKeychainUtils getPasswordForUsername:key 
                                                  andServiceName:@"VirtualCurrencyManager" 
                                                           error:&error];
    if(error) {
        VCLog(@"%@", [error localizedDescription]);
    }
    
    return object;
}

+(NSNumber*) numberForKey:(NSString*) key
{
    return [NSNumber numberWithInt:[[VirtualCurrencyManager objectForKey:key] intValue]];
}

+(void) setObject:(id) object forKey:(NSString*) key
{
    NSString *objectString = nil;
    if([object isKindOfClass:[NSData class]])
    {
        objectString = [[[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding]autorelease];
    }
    
    if([object isKindOfClass:[NSNumber class]])
    {       
        objectString = [(NSNumber*)object stringValue];
    }
    NSError *error = nil;
    [SFHFKeychainUtils storeUsername:key 
                         andPassword:objectString
                      forServiceName:@"VirtualCurrencyManager"
                      updateExisting:YES 
                               error:&error];
    
    if(error) {
        VCLog(@"%@", [error localizedDescription]);
    }
}

- (BOOL)removeAllKeychainData {
    NSError *error;
    
    //loop through all the saved keychain data and remove it    
    for (id key in self.purchasableObjects) {
        [SFHFKeychainUtils deleteItemForUsername:key andServiceName:@"VirtualCurrencyManager" error:&error];
    }
    if (!error) {
        return YES; 
    }
    else {
        return NO;
    }
}

- (void)setVirtualGoods:(NSDictionary *)virtualGoods {
    self.purchasableObjects = virtualGoods;
}

- (NSDictionary *)getVirtualGood:(NSString *)virtualGoodId {
    return [self.purchasableObjects objectForKey:virtualGoodId];
}

- (void)buyVirtualGood:(NSString *)virtualGoodId
            onComplete:(void (^)(NSString*)) completionBlock         
                onFail:(void (^)(void)) failBlock {
    
    VCLog(@"Buying virtualGood: %@", virtualGoodId);
    
    NSDictionary *good = [purchasableObjects objectForKey:virtualGoodId];
    
    if (!good) {
        VCLog(@"Couldn't buy good: %@. The good is not a purchasable object.", virtualGoodId);
        failBlock();
        return;
    }
    
    if ( self.currency < [[good objectForKey:@"price"] intValue] ) {
        VCLog(@"Couldn't buy good: %@. Price was %d and currency %d",
              virtualGoodId,
              [[good objectForKey:@"price"] intValue],
              self.currency);
        failBlock();
        return;
    }
    
    NSInteger count = [[VirtualCurrencyManager numberForKey:virtualGoodId] intValue];
    if ( ![[good objectForKey:@"consumable"] boolValue] &&
        count > 1) {
        VCLog(@"Couldn't buy good: %@. It's not consumable and the user has it",
              virtualGoodId);
        failBlock();
        return;
    }
    
    // If we reach here, we can buy the item.
    [VirtualCurrencyManager setObject:[NSNumber numberWithInt: count + [[good objectForKey:@"amount"] intValue]]
                                 forKey:virtualGoodId];
    self.currency -= [[good objectForKey:@"price"] intValue];
    completionBlock(virtualGoodId);
}

- (BOOL)isVirtualGoodAvailable:(NSString *)virtualGoodId {
    NSDictionary *good = [purchasableObjects objectForKey:virtualGoodId];
    if ( [[good objectForKey:@"price"] intValue] == 0 ) {
        return YES;
    }

    return [[VirtualCurrencyManager objectForKey:virtualGoodId] boolValue];
}

- (BOOL)isVirtualGoodPurchased:(NSString*)virtualGoodId {
    return [[VirtualCurrencyManager objectForKey:virtualGoodId] intValue] > 0;
}

- (BOOL)canConsumeVirtualGood:(NSString*)virtualGoodId quantity:(NSInteger)quantity {
    NSInteger count = [[VirtualCurrencyManager objectForKey:virtualGoodId] intValue];
    return count > quantity;
}

- (BOOL)consumeVirtualGood:(NSString*)virtualGoodId quantity:(NSInteger)quantity {
    if ( ![self canConsumeVirtualGood:virtualGoodId quantity:quantity] ) {
        return NO;
    }
    
    NSInteger count = [[VirtualCurrencyManager objectForKey:virtualGoodId] intValue];
    [VirtualCurrencyManager setObject:[NSNumber numberWithInt: count - quantity]
                                 forKey:virtualGoodId];
    
    return YES;
}

- (NSInteger)getAmount:(NSString *)virtualGoodId {
    return [[VirtualCurrencyManager objectForKey:virtualGoodId] intValue];    
}

- (NSInteger)currency {
    return [[VirtualCurrencyManager numberForKey:@"currency"] intValue];
}

- (void)setCurrency:(NSInteger)value {
    [VirtualCurrencyManager setObject:[NSNumber numberWithInt: value]
                                 forKey:@"currency"];
}

- (void)dealloc {
    purchasableObjects = nil;
}

+ (void) dealloc
{
	_sharedVirtualCurrencyManager = nil;
	[super dealloc];
}


@end
