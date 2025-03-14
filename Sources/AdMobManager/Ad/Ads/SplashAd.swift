//
//  SplashAd.swift
//  
//
//  Created by Trịnh Xuân Minh on 06/09/2023.
//

import UIKit
import GoogleMobileAds
//import AppsFlyerAdRevenue

class SplashAd: NSObject, AdProtocol {
    func config(didFail: Handler?, didSuccess: Handler?) {
        
    }
    
  private var splashAd: GADInterstitialAd?
  private var adUnitID: String?
  private var presentState = false
  private weak var rootViewController: UIViewController?
  private var isLoading = false
  private var timeout: Double?
  private var time = 0.0
  private var timer: Timer?
  private var timeInterval = 0.1
  private var didFail: ErrorHadler?
  private var didEarnReward: Handler?
  private var didHide: Handler?
  
  func config(id: String) {
    self.adUnitID = id
  }
  
  func config(timeout: Double) {
    self.timeout = timeout
  }
  
  func isPresent() -> Bool {
    return presentState
  }
  
  func show(rootViewController: UIViewController,
            didFail: ErrorHadler?,
            didEarnReward: Handler?,
            didHide: Handler?
  ) {
    guard !presentState else {
      print("[AdMobManager] SplashAd display failure - ads are being displayed!")
        didFail?(AdMobMError.beingDisplayed)
      return
    }
    print("[AdMobManager] SplashAd requested to show!")
    self.didFail = didFail
    self.didHide = didHide
    self.didEarnReward = didEarnReward
    self.rootViewController = rootViewController
    load()
  }
}

extension SplashAd: GADFullScreenContentDelegate {
  func ad(_ ad: GADFullScreenPresentingAd,
          didFailToPresentFullScreenContentWithError error: Error
  ) {
    print("[AdMobManager] SplashAd did fail to show content!")
    didFail?(nil)
    self.splashAd = nil
  }
  
  func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    print("[AdMobManager] SplashAd will display!")
    self.presentState = true
  }
  
  func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    print("[AdMobManager] SplashAd did hide!")
    didHide?()
    self.presentState = false
    self.splashAd = nil
  }
}

extension SplashAd {
  private func load() {
    guard !isLoading else {
      return
    }
    
    guard let adUnitID = adUnitID else {
      print("[AdMobManager] SplashAd failed to load - not initialized yet! Please install ID.")
      didFail?(nil)
      return
    }
    
    guard let rootViewController = rootViewController else {
      print("[AdMobManager] SplashAd display failure - can't find RootViewController!")
      didFail?(nil)
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        return
      }
      
      self.isLoading = true
      self.fire()
      print("[AdMobManager] SplashAd start load!")
      
      let request = GADRequest()
      GADInterstitialAd.load(
        withAdUnitID: adUnitID,
        request: request
      ) { [weak self] (ad, error) in
        guard let self = self else {
          return
        }
        guard let timeout = self.timeout, self.time < timeout else {
          return
        }
        self.invalidate()
        guard error == nil, let ad = ad else {
          print("[AdMobManager] SplashAd load fail - \(String(describing: error))!")
          self.didFail?(nil)
          return
        }
        print("[AdMobManager] SplashAd did load!")
        self.splashAd = ad
        self.splashAd?.fullScreenContentDelegate = self
        self.splashAd?.present(fromRootViewController: rootViewController)
        
        ad.paidEventHandler = { adValue in
//          let adRevenueParams: [AnyHashable: Any] = [
//            kAppsFlyerAdRevenueCountry: "US",
//            kAppsFlyerAdRevenueAdUnit: adUnitID as Any,
//            kAppsFlyerAdRevenueAdType: "Interstitial_Splash"
//          ]
//          
//          AppsFlyerAdRevenue.shared().logAdRevenue(
//            monetizationNetwork: "admob",
//            mediationNetwork: MediationNetworkType.googleAdMob,
//            eventRevenue: adValue.value,
//            revenueCurrency: adValue.currencyCode,
//            additionalParameters: adRevenueParams)
        }
      }
    }
  }
  
  private func fire() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        return
      }
      self.timer = Timer.scheduledTimer(timeInterval: self.timeInterval,
                                        target: self,
                                        selector: #selector(self.isReady),
                                        userInfo: nil,
                                        repeats: true)
    }
  }
  
  private func invalidate() {
    self.timer?.invalidate()
    self.timer = nil
    self.adUnitID = nil
  }
  
  @objc private func isReady() {
    self.time += timeInterval
    
    if let timeout = timeout, time < timeout {
      return
    }
    invalidate()
    didFail?(nil)
  }
}
