//
//  VirtualCurrencyManagerTests.m
//  VirtualCurrencyManagerTests
//
//  Created by Carlos Sessa on 12/20/11.
//  Copyright (c) 2011 NASA Trained Monkeys. All rights reserved.
//

#import "VirtualCurrencyManagerTests.h"
#import "VirtualCurrencyManager.h"

@implementation VirtualCurrencyManagerTests

static NSDictionary *goods;

- (void)setUp
{
    [super setUp];
    
    NSDictionary *consumableFuel = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"Fuel", @"name",
                                    [NSNumber numberWithInt:100], @"price",
                                    @"Fuel for your car", @"desc",
                                    [NSNumber numberWithBool:YES], @"consumable",
                                    [NSNumber numberWithInt:500], @"amount",
                                    nil];
    
    NSDictionary *carUpgrade1 = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"Car Upgrade 1", @"name",
                                 [NSNumber numberWithInt:200], @"price",
                                 @"Car upgrade 1 with more speed", @"desc", 
                                 [NSNumber numberWithBool:NO], @"consumable",
                                 [NSNumber numberWithInt:1], @"amount",
                                 nil];
    
    goods = [NSDictionary dictionaryWithObjectsAndKeys:
             consumableFuel, @"com.nasatrainedmonkeys.fuel",
             carUpgrade1, @"com.nasatrainedmonkeys.car.upgrade1",
             nil];
}

- (void)tearDown
{
    VirtualCurrencyManager *manager = [VirtualCurrencyManager sharedManager];
    manager.currency = 0;
    [manager removeAllKeychainData];
    
    [super tearDown];
}

- (void)testBuyVirtualGoods {
    
    VirtualCurrencyManager *manager = [VirtualCurrencyManager sharedManager];
    [manager setVirtualGoods:goods];
    
    manager.currency = 101;
    [manager buyVirtualGood:@"com.nasatrainedmonkeys.fuel"
                 onComplete:^(NSString *virtualGoodId) {
                     STAssertEquals(1, [VirtualCurrencyManager sharedManager].currency, @"After buying the concurrency isn't 1.");
                     
                 }
     
                     onFail:^(void) {
                         STFail(@"Couldn't buy fuel");
                     }];
    
    [manager buyVirtualGood:@"com.nasatrainedmonkeys.fuel"
                 onComplete:^(NSString *virtualGoodId) {
                     STFail(@"Shouldn't be able to buy fuel");
                 }
     
                     onFail:^(void) {
                         STAssertEquals(1, [VirtualCurrencyManager sharedManager].currency, @"Currency should be 1.");
                     }];
}

- (void)testIsVirtualGoodAvailable {
    
    VirtualCurrencyManager *manager = [VirtualCurrencyManager sharedManager];
    [manager setVirtualGoods:goods];
    manager.currency = 100;
    
    STAssertFalse([manager isVirtualGoodAvailable:@"com.nasatrainedmonkeys.fuel"], @"Item shouldn't be available before buying it");
    [manager buyVirtualGood:@"com.nasatrainedmonkeys.fuel" onComplete:^(NSString *var){} onFail:^(void){}];
    STAssertTrue([manager isVirtualGoodAvailable:@"com.nasatrainedmonkeys.fuel"], @"Item should be available after buying it");
    
}

- (void)testIsVirtualGoodPurchased {
    VirtualCurrencyManager *manager = [VirtualCurrencyManager sharedManager];
    [manager setVirtualGoods:goods];
    manager.currency = 200;
    
    STAssertFalse([manager isVirtualGoodPurchased:@"com.nasatrainedmonkeys.car.upgrade1"],
                  @"Item shouldn't be purchased before buying it");
    [manager buyVirtualGood:@"com.nasatrainedmonkeys.car.upgrade1" onComplete:^(NSString *var){} onFail:^(void){}];
    STAssertTrue([manager isVirtualGoodPurchased:@"com.nasatrainedmonkeys.car.upgrade1"],
                 @"Item should be purchased after buying it");
}

- (void)testCanConsumeVirtualGood {
    VirtualCurrencyManager *manager = [VirtualCurrencyManager sharedManager];
    [manager setVirtualGoods:goods];
    manager.currency = 200;
    
    STAssertFalse([manager canConsumeVirtualGood:@"com.nasatrainedmonkeys.fuel" quantity: 10],
                  @"Item shouldn't be consumable before buying it");
    [manager buyVirtualGood:@"com.nasatrainedmonkeys.fuel" onComplete:^(NSString *var){} onFail:^(void){}];
    STAssertTrue([manager canConsumeVirtualGood:@"com.nasatrainedmonkeys.fuel" quantity: 10],
                 @"Item should be consumable after buying it");
    
}

- (void)testConsumeVirtualGood {
    VirtualCurrencyManager *manager = [VirtualCurrencyManager sharedManager];
    [manager setVirtualGoods:goods];
    manager.currency = 200;
    
    [manager buyVirtualGood:@"com.nasatrainedmonkeys.fuel" onComplete:^(NSString *var){} onFail:^(void){}];
    STAssertTrue([manager consumeVirtualGood:@"com.nasatrainedmonkeys.fuel" quantity: 400],
                 @"Item should be consumable after buying it");
    
    STAssertFalse([manager consumeVirtualGood:@"com.nasatrainedmonkeys.fuel" quantity: 150],
                  @"Item shouldn't be consumable");
}

@end
