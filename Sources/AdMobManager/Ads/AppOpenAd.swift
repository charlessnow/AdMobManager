//
//  OpenAppAds.swift
//  MovieIOS7
//
//  Created by Trịnh Xuân Minh on 21/02/2022.
//

import Foundation
import UIKit
import GoogleMobileAds

class AppOpenAd: NSObject {
    
    fileprivate var adUnit_ID: String?
    fileprivate var appOpenAd: GADAppOpenAd?
    fileprivate var loadTimeOpenApp: Date = Date()
    fileprivate var timeBetween: Double = 5
    fileprivate var isLoading: Bool = false
    fileprivate var willPresent: (() -> ())?
    fileprivate var willDismiss: (() -> ())?
    fileprivate var didDismiss: (() -> ())?
    
    func load() {
        if self.isLoading {
            return
        }
        
        guard let adUnit_ID = self.adUnit_ID else {
            print("No AppOpenAd ID!")
            return
        }
        
        self.isLoading = true
        
        let request = GADRequest()
        GADAppOpenAd.load(withAdUnitID: adUnit_ID,
                          request: request,
                          orientation: UIInterfaceOrientation.portrait) { (ad, error) in
            if let _ = error {
                print("OpenAppAds download error, trying again!")
                self.isLoading = false
                self.load()
                return
            }
            self.appOpenAd = ad
            self.appOpenAd?.fullScreenContentDelegate = self
            self.isLoading = false
        }
    }
    
    func isExist() -> Bool {
        return self.appOpenAd != nil
    }
    
    func isReady() -> Bool {
        return self.isExist() && self.wasLoadTimeLessThanNHoursAgo()
    }
    
    func show(willPresent: (() -> ())?, willDismiss: (() -> ())?, didDismiss: (() -> ())?) {
        if !self.isReady() {
            print("OpenAppAds are not ready to show!")
            return
        }
        guard let topViewController = UIApplication.topStackViewController() else {
            print("Can't find RootViewController!")
            return
        }
        self.willPresent = willPresent
        self.willDismiss = willDismiss
        self.didDismiss = didDismiss
        self.appOpenAd?.present(fromRootViewController: topViewController)
    }
}

extension AppOpenAd: GADFullScreenContentDelegate {
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content.")
        self.didDismiss?()
    }
    
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        self.willPresent?()
    }
    
    func adWillDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        self.willDismiss?()
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did dismiss full screen content.")
        self.didDismiss?()
        self.appOpenAd = nil
        self.load()
        self.loadTimeOpenApp = Date()
    }
    
    func wasLoadTimeLessThanNHoursAgo() -> Bool {
        let now = Date()
        let timeIntervalBetweenNowAndLoadTime = now.timeIntervalSince(self.loadTimeOpenApp)
        return timeIntervalBetweenNowAndLoadTime > self.timeBetween
    }
    
    func setTimeBetween(time: Double) {
        self.timeBetween = time
    }
    
    func setAdUnitID(ID: String) {
        self.adUnit_ID = ID
    }
}
