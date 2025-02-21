//
//  File.swift
//  
//
//  Created by Trịnh Xuân Minh on 31/05/2023.
//

import Foundation

public typealias Handler = (() -> Void)

public typealias ErrorHadler = ((_ error: Error?) -> Void)

public enum AdMobMError: LocalizedError, Sendable {
    case notAllow
    case notReady
    case notExist
    case otherAdsShowing
    case displayNotYet
    case notPreloaded
    case beingDisplayed
    
    public var errorDescription: String? {
        switch self {
        case .notReady:
            return "not ready to show!"
        case .beingDisplayed:
            return "ads are being displayed!"
        case .notAllow:
            return "Ads are not allowed to show"
        case .notExist:
            return "Ads don't exist!"
        case .otherAdsShowing:
            return "Ads display failure - other ads is showing!"
        case .displayNotYet:
            return "Ads hasn't been displayed yet"
        case .notPreloaded:
            return "Ads are not preloaded"
            
        }
    }
}
