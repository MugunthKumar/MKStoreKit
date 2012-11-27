//
//  MKStoreKitConfigs.h
//  MKStoreKit (Version 5.0)
//
//	File created using Singleton XCode Template by Mugunth Kumar (http://mugunthkumar.com
//  Permission granted to do anything, commercial/non-commercial with this file apart from removing the line/URL above
//  Read my blog post at http://mk.sg/1m on how to use this code

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

// To avoid making mistakes map plist entries to macroses as below and use them
// instead of keys itself.
//
// #define kConsumableBaseFeatureId @"com.mycompany.myapp."
// #define kFeatureAId @"com.mugunthkumar.caltasks.propack"
// #define kConsumableFeatureBId @"com.mycompany.myapp.005"
// #define FishBasket @"FishBasket"

#ifndef SERVER_PRODUCT_MODEL
    #define SERVER_PRODUCT_MODEL 0
#endif

#ifndef OWN_SERVER
    #define OWN_SERVER nil
#endif

#ifndef REVIEW_ALLOWED
    #define REVIEW_ALLOWED 0
#endif

#warning Shared Secret Missing Ignore this warning if you don't use auto-renewable subscriptions
#ifndef kSharedSecret
    #define kSharedSecret @"<FILL IN YOUR SHARED SECRET HERE>"
#endif
