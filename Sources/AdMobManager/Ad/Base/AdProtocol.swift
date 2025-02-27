//
//  AdProtocol.swift
//  
//
//  Created by Trịnh Xuân Minh on 23/06/2022.
//

import UIKit

@objc protocol AdProtocol {
  func config(id: String)
  func isPresent() -> Bool
  @objc optional func isExist() -> Bool
  func show(rootViewController: UIViewController,
            didFail: ErrorHadler?,
            didEarnReward: Handler?,
            didHide: Handler?)
    
   
    func config(didFail: Handler?, didSuccess: Handler?)
}

extension AdProtocol {
    func config(timeout: Double){}
}
