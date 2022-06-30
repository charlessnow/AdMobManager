//
//  File.swift
//  
//
//  Created by Trịnh Xuân Minh on 30/06/2022.
//

import UIKit

extension UICollectionView {
  public func registerAds(ofType type: AnyClass, bundle: Bundle? = AdMobManager.bundle) {
    register(UINib(nibName: String(describing: type.self), bundle: bundle),
             forCellWithReuseIdentifier: String(describing: type.self))
  }

  public func dequeueCell<T>(ofType type: T.Type, indexPath: IndexPath) -> T {
    return dequeueReusableCell(withReuseIdentifier: String(describing: T.self), for: indexPath) as! T
  }
}
