//
//  ViewController.swift
//  MKStoreKitDemo
//
//  Created by Mugunth Kumar on 4/11/15.
//  Copyright © 2015 Steinlogic Consulting and Training Pte Ltd. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    NSNotificationCenter.defaultCenter().addObserverForName(kMKStoreKitProductPurchasedNotification,
      object: nil, queue: NSOperationQueue.mainQueue()) { (note) -> Void in
        print ("Purchased product: \(note.object)")
    }

    NSNotificationCenter.defaultCenter().addObserverForName(kMKStoreKitDownloadCompletedNotification,
      object: nil, queue: NSOperationQueue.mainQueue()) { (note) -> Void in
        print ("Downloaded product: \(note.userInfo)")
    }

    NSNotificationCenter.defaultCenter().addObserverForName(kMKStoreKitDownloadProgressNotification,
      object: nil, queue: NSOperationQueue.mainQueue()) { (note) -> Void in
        print ("Downloading product: \(note.userInfo)")
    }

  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }


  @IBAction func buyConsumable(sender: AnyObject) {
    MKStoreKit.sharedKit().initiatePaymentRequestForProductWithIdentifier("com.steinlogic.iapdemo.consumable")
  }

  @IBAction func buyNonConsumable(sender: AnyObject) {
    MKStoreKit.sharedKit().initiatePaymentRequestForProductWithIdentifier("com.steinlogic.iapdemo.nonconsumablenocontent")
  }

  @IBAction func buySubscriptionWithContent(sender: AnyObject) {
    MKStoreKit.sharedKit().initiatePaymentRequestForProductWithIdentifier("com.steinlogic.iapdemo.quarterly")
  }

  @IBAction func buyNonConsumableWithoutContent(sender: AnyObject) {
    MKStoreKit.sharedKit().initiatePaymentRequestForProductWithIdentifier("com.steinlogic.iapdemo.nonconsumablewithcontent")
  }
}

