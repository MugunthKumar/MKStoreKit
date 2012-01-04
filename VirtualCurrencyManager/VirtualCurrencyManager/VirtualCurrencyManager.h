//
//  VirtualCurrencyManager.h
//  VirtualCurrencyManager
//
//  Created by Carlos Sessa on 12/20/11.
//  Copyright (c) 2011 NASA Trained Monkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


#ifndef NDEBUG
#    define VCLog(...) NSLog(__VA_ARGS__)
#else
#    define VCLog(...) /* */
#endif


@interface VirtualCurrencyManager : NSObject

@property(nonatomic, assign)NSInteger currency;

+ (VirtualCurrencyManager*)sharedManager;

- (NSDictionary *)getVirtualGood:(NSString *)virtualGoodId;
- (void)setVirtualGoods:(NSDictionary *)virtualGoods;

- (void)buyVirtualGood:(NSString *)virtualGoodId
            onComplete:(void (^)(NSString *)) completionBlock         
                onFail:(void (^)(void)) failBlock;

- (BOOL)isVirtualGoodPurchased:(NSString *)virtualGoodId;
- (BOOL)isVirtualGoodAvailable:(NSString *)virtualGoodId;
- (NSInteger)getAmount:(NSString *)virtualGoodId;

- (BOOL)canConsumeVirtualGood:(NSString*)virtualGoodId quantity:(NSInteger)quantity;
- (BOOL)consumeVirtualGood:(NSString*)virtualGoodId quantity:(NSInteger)quantity;

- (void)forceVirtualGoodIncrease:(NSString *)virtualGoodId byAmount:(NSInteger)amount;

//for testing proposes you can use this method to remove all the saved keychain data (saved purchases, etc.)
- (BOOL)removeAllKeychainData;

@end
