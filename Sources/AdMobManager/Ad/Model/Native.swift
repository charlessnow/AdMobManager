//
//  Native.swift
//  
//
//  Created by Trịnh Xuân Minh on 23/08/2023.
//

import Foundation

struct Native: AdConfigProtocol {
  let placementID: String
  let status: Bool
  let name: String
  let id: String
  let isAuto: Bool?
  let description: String?
  let isFullScreen: Bool?
  let isPreload: Bool?
  let timeout: Double?
}
