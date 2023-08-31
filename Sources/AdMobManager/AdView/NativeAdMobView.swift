//
//  NativeAdMobView.swift
//  
//
//  Created by Trịnh Xuân Minh on 11/07/2023.
//

import UIKit
import GoogleMobileAds

/// This class returns a UIView that loads NativeAd.
/// ```
/// import AdMobManager
/// ```
/// Inherit this class with custom layout
/// Loading ads is automatic.
/// - Warning: NativeAd will not load without adding ID.
open class NativeAdMobView: UIView, AdMobViewProtocol, GADVideoControllerDelegate {
  private var nativeAdView: GADNativeAdView?
  private var nativeAd: NativeAd?
  private var didReceive: Handler?
  
  open override func awakeFromNib() {
    super.awakeFromNib()
    addComponents()
    setConstraints()
    setProperties()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    addComponents()
    setConstraints()
    setProperties()
  }

  required public init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  public override func removeFromSuperview() {
    self.nativeAd = nil
    super.removeFromSuperview()
  }
  
  open override func draw(_ rect: CGRect) {
    super.draw(rect)
    setColor()
  }
  
  open func addComponents() {}
  
  open func setConstraints() {}
  
  open func setProperties() {}
  
  open func setColor() {}
  
  public func load(name: String, rootViewController: UIViewController?) {
    if let nativeAd = nativeAd {
      config(ad: nativeAd.getAd())
      return
    }
    guard let ad = AdMobManager.shared.getAd(type: .onceUsed(.native), name: name) as? Native else {
      return
    }
    guard ad.status else {
      return
    }
    let nativeAd = NativeAd()
    nativeAd.config(ad: ad, rootViewController: rootViewController)
    nativeAd.setBinding { [weak self] in
      guard let self = self else {
        return
      }
      self.config(ad: nativeAd.getAd())
    }
    self.nativeAd = nativeAd
  }
  
  public func binding(nativeAdView: GADNativeAdView, didReceive: @escaping Handler) {
    self.nativeAdView = nativeAdView
    self.didReceive = didReceive
  }
}

extension NativeAdMobView {
  private func config(ad: GADNativeAd?) {
    guard
      let nativeAd = ad,
      let nativeAdView = nativeAdView
    else {
      return
    }
    (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
    
    nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
    
    if let mediaView = nativeAdView.mediaView, nativeAd.mediaContent.aspectRatio > 0 {
      let heightConstraint = NSLayoutConstraint(
        item: mediaView,
        attribute: .height,
        relatedBy: .equal,
        toItem: mediaView,
        attribute: .width,
        multiplier: CGFloat(1 / nativeAd.mediaContent.aspectRatio),
        constant: 0)
      heightConstraint.isActive = true
    }
    
    (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
    nativeAdView.bodyView?.isHidden = nativeAd.body == nil
    
    (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
    nativeAdView.callToActionView?.isHidden = nativeAd.callToAction == nil
    nativeAdView.callToActionView?.isUserInteractionEnabled = false
    
    (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
    nativeAdView.iconView?.isHidden = nativeAd.icon == nil
    
    (nativeAdView.starRatingView as? UIImageView)?.image = imageOfStars(from: nativeAd.starRating)
    nativeAdView.starRatingView?.isHidden = nativeAd.starRating == nil
    
    (nativeAdView.storeView as? UILabel)?.text = nativeAd.store
    nativeAdView.storeView?.isHidden = nativeAd.store == nil
    
    (nativeAdView.priceView as? UILabel)?.text = nativeAd.price
    nativeAdView.priceView?.isHidden = nativeAd.price == nil
    
    (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
    nativeAdView.advertiserView?.isHidden = nativeAd.advertiser == nil
    
    nativeAdView.nativeAd = nativeAd
    
    didReceive?()
  }
  
  private func imageOfStars(from starRating: NSDecimalNumber?) -> UIImage? {
    guard let rating = starRating?.doubleValue else {
      return nil
    }
    guard let image = UIImage(named: "\(Int(rating))_star", in: Bundle.module, compatibleWith: nil) else {
      return nil
    }
    return image
  }
}
