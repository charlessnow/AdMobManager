//
//  AdMobManager.swift
//  AdMobManager
//
//  Created by Trịnh Xuân Minh on 25/03/2022.
//

import UIKit
import FirebaseRemoteConfig
import GoogleMobileAds
import Combine

/// An ad management structure. It supports setting InterstitialAd, RewardedAd, RewardedInterstitialAd, AppOpenAd, NativeAd, BannerAd.
/// ```
/// import AdMobManager
/// ```
/// - Warning: Available for Swift 5.3, Xcode 12.5 (macOS Big Sur). Support from iOS 13.0 or newer.
public class AdMobManager {
  public static var shared = AdMobManager()
  
  public enum OnceUsed: String {
    case native
    case banner
  }
  
  public enum Reuse: String {
    case splash
    case appOpen
    case interstitial
    case rewarded
    case rewardedInterstitial
  }
  
  public enum AdType {
    case onceUsed(_ type: OnceUsed)
    case reuse(_ type: Reuse)
  }
  
  private let remoteConfig = RemoteConfig.remoteConfig()
  private var retryAttempt = 0
  private var subscriptions = [AnyCancellable]()
  private var remoteKey: String?
  private var defaultData: Data?
  private var configValue: ((RemoteConfig) -> Void)?
  private var actions = [Handler]()
  private var isPremium = false
  private var adMobConfig: AdMobConfig?
  private var listAds: [String: AdProtocol] = [:]
  
  public func upgradePremium() {
    self.isPremium = true
  }
  
  public func addActionConfigValue(_ handler: @escaping ((RemoteConfig) -> Void)) {
    self.configValue = handler
  }
  
  public func register(remoteKey: String, defaultData: Data) {
    if isPremium {
      print("AdMobManager: Premium!")
      runActions()
    }
    guard self.remoteKey == nil else {
      return
    }
    self.remoteKey = remoteKey
    self.defaultData = defaultData
    
    fetchCache()
    
    NetworkAdMob.shared.$isConnected.sink { [weak self] isConnected in
      guard let self = self else {
        return
      }
      if isConnected, self.retryAttempt == 0 {
        self.fetchRemote()
      }
    }.store(in: &subscriptions)
  }
  
  public func addActionSuccessRegister(_ handler: @escaping Handler) {
    if adMobConfig == nil, !isPremium {
      actions.append(handler)
    } else {
      handler()
    }
  }

  public func status(type: AdType, name: String) -> Bool? {
    guard !isPremium else {
      print("AdMobManager: Premium!")
      return nil
    }
    guard let adMobConfig = adMobConfig else {
      print("AdMobManager: Not yet registered!")
      return nil
    }
    guard adMobConfig.status else {
      return false
    }
    guard let adConfig = getAd(type: type, name: name) as? AdConfigProtocol else {
      print("AdMobManager: Ads don't exist!")
      return nil
    }
    return adConfig.status
  }

  public func load(type: Reuse, name: String) {
    switch status(type: .reuse(type), name: name) {
    case false:
      print("AdMobManager: Ads are not allowed to show!")
      return
    case true:
      break
    default:
      return
    }
    guard let adConfig = getAd(type: .reuse(type), name: name) as? AdConfigProtocol else {
      print("AdMobManager: Ads don't exist!")
      return
    }
    guard listAds[type.rawValue + adConfig.id] == nil else {
      return
    }
    
    let adProtocol: AdProtocol!
    switch type {
    case .splash:
      guard let splash = adConfig as? Splash else {
        print("AdMobManager: Format conversion error!")
        return
      }
      let splashAd = SplashAd()
      splashAd.config(timeout: splash.timeout)
      adProtocol = splashAd
    case .appOpen:
      adProtocol = AppOpenAd()
    case .interstitial:
      adProtocol = InterstitialAd()
    case .rewarded:
      adProtocol = RewardedAd()
    case .rewardedInterstitial:
      adProtocol = RewardedInterstitialAd()
    }
    adProtocol.config(id: adConfig.id)
    self.listAds[type.rawValue + adConfig.id] = adProtocol
  }

  public func show(type: Reuse,
                   name: String,
                   rootViewController: UIViewController,
                   didFail: Handler?,
                   didEarnReward: Handler? = nil,
                   didHide: Handler?
  ) {
    switch status(type: .reuse(type), name: name) {
    case false:
      print("AdMobManager: Ads are not allowed to show!")
      didFail?()
      return
    case true:
      break
    default:
      didFail?()
      return
    }
    guard let adConfig = getAd(type: .reuse(type), name: name) as? AdConfigProtocol else {
      print("AdMobManager: Ads don't exist!")
      didFail?()
      return
    }
    guard let ad = listAds[type.rawValue + adConfig.id] else {
      print("AdMobManager: Ads do not exist!")
      didFail?()
      return
    }
    guard !checkIsPresent() else {
      print("AdMobManager: Ads display failure - other ads is showing!")
      didFail?()
      return
    }
    guard checkFrequency(adConfig: adConfig, ad: ad) else {
      print("AdMobManager: Ads hasn't been displayed yet!")
      didFail?()
      return
    }
    ad.show(rootViewController: rootViewController,
            didFail: didFail,
            didEarnReward: didEarnReward,
            didHide: didHide)
  }
}

extension AdMobManager {
  func getAd(type: AdType, name: String) -> Any? {
    guard let adMobConfig = adMobConfig else {
      return nil
    }
    switch type {
    case .onceUsed(let type):
      switch type {
      case .banner:
        return adMobConfig.banners?.first(where: { $0.name == name })
      case .native:
        return adMobConfig.natives?.first(where: { $0.name == name })
      }
    case .reuse(let type):
      switch type {
      case .splash:
        guard
          let splash = adMobConfig.splash,
          splash.name == name
        else {
          return nil
        }
        return adMobConfig.splash
      case .appOpen:
        guard
          let appOpen = adMobConfig.appOpen,
          appOpen.name == name
        else {
          return nil
        }
        return adMobConfig.appOpen
      case .interstitial:
        return adMobConfig.interstitials?.first(where: { $0.name == name })
      case .rewarded:
        return adMobConfig.rewardeds?.first(where: { $0.name == name })
      case .rewardedInterstitial:
        return adMobConfig.rewardedInterstitials?.first(where: { $0.name == name })
      }
    }
  }
}

extension AdMobManager {
  private func checkIsPresent() -> Bool {
    for ad in listAds where ad.value.isPresent() {
      return true
    }
    return false
  }
  
  private func updateCache() {
    guard let remoteKey = remoteKey else {
      return
    }
    guard let adMobConfig = adMobConfig else {
      return
    }
    guard let data = try? JSONEncoder().encode(adMobConfig) else {
      return
    }
    UserDefaults.standard.set(data, forKey: remoteKey)
  }
  
  private func decoding(adMobData: Data) {
    guard let adMobConfig = try? JSONDecoder().decode(AdMobConfig.self, from: adMobData) else {
      print("AdMobManager: Invalid format!")
      return
    }
    self.adMobConfig = adMobConfig
    updateCache()
    runActions()
  }
  
  private func fetchCache() {
    guard let remoteKey = remoteKey else {
      return
    }
    guard let cacheData = UserDefaults.standard.data(forKey: remoteKey) else {
      return
    }
    decoding(adMobData: cacheData)
  }
  
  private func fetchDefault() {
    guard let defaultData = defaultData else {
      return
    }
    decoding(adMobData: defaultData)
  }
  
  private func retryFetchRemote() {
    if retryAttempt == 1 {
      logErrorFetchRemote()
      DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: fetchRemote)
    } else if adMobConfig == nil {
      fetchDefault()
    }
  }
  
  private func fetchRemote() {
    self.retryAttempt += 1
    guard retryAttempt <= 2 else {
      return
    }
    guard let remoteKey = remoteKey else {
      return
    }
    remoteConfig.fetch(withExpirationDuration: 0) { [weak self] _, error in
      guard let self = self else {
        return
      }
      guard error == nil else {
        self.retryFetchRemote()
        return
      }
      self.remoteConfig.activate()
      self.configValue?(self.remoteConfig)
      let adMobData = remoteConfig.configValue(forKey: remoteKey).dataValue
      guard !adMobData.isEmpty else {
        self.retryFetchRemote()
        return
      }
      self.decoding(adMobData: adMobData)
    }
  }
  
  private func logErrorFetchRemote() {
    let key = "AdMobManager_First_Open"
    if UserDefaults.standard.bool(forKey: key) {
      LogEventManager.shared.log(event: .remoteConfigLoadFailLaunchApp)
    } else {
      LogEventManager.shared.log(event: .remoteConfigLoadFailFirstOpen)
      UserDefaults.standard.set(true, forKey: key)
    }
  }
  
  private func runActions() {
    actions.forEach { $0() }
    actions.removeAll()
  }
  
  private func checkFrequency(adConfig: AdConfigProtocol, ad: AdProtocol) -> Bool {
    guard
      let interstitial = adConfig as? Interstitial,
      let start = interstitial.start,
      let frequency = interstitial.frequency
    else {
      return true
    }
    let countClick = FrequencyManager.shared.getCount(name: adConfig.name) + 1
    guard countClick >= start else {
      FrequencyManager.shared.increaseCount(name: adConfig.name)
      return false
    }
    let isShow = (countClick - start) % frequency == 0
    if !isShow || ad.isExist() {
      FrequencyManager.shared.increaseCount(name: adConfig.name)
    }
    return isShow
  }
}
