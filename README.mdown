This is version 3.0 of MKStoreKit

The source code, MKStoreKit, contains four objective c files. MKStoreManager.h/m and MKStoreObserver.h/m and five server side files. The MKStoreManager is a singleton class that takes care of *everything*. Just include StoreKit framework into your product and drag these four files into the project. You then have to initialize it by calling [MKStoreManager sharedManager] in your applicationDidFinishLaunching. From then on, it does the magic. The MKStoreKit automatically activates/deactivates features using your userDefaults. When a feature is purchased, it automagically records it into NSUserDefaults. For checking whether the user has purchased the feature, you can call a function like,

if([MKStoreManager isFeaturePurchased:kFeatureID])
{
//unlock it
}

To purchase a feature, just call

[[MKStoreManager sharedManager] buyFeature:kFeatureID];

It’s that simple with my MKStoreKit. As always, all my source code can be used royalty-free into your app. Just make sure that you don’t remove the copyright notice from the source code if you make your app open source. You don’t have to attribute me in your app, although I would be glad if you do so.

What's new in Version 3
Support for Server Product Model
MKStoreKit can automatically post the receipt data to your server
and "remember" the purchases only when your server returns.
The server code for the same in PHP is also available within MKStoreKit

What's new in Version 2

In Version 2, support for pinging the developer server for checking review requests is added. If you want to use this feature, you have to fill in "ownServer" variable to the location where you copy the server file featureCheck.php

The database required can be created from the sql file attached.

The code that you need for setting up your server is present in the ServerCode folder. 

Copy all the files to some location like
http://api.mycompany.com/inapp/

The URL which you should copy to "ownServer" variable in MKStoreManager.m is http://api.mycompany.com/inapp/featureCheck.php
Copy this URL to ownServer parameter in MKStoreManager.m

It should all work. If it doesn't, hire me for debugging it! :)

