//
//  AriaSyncOptions.swift
//  AriaSync
//
//  Created by Steve Cochran on 10/23/18.
//

import Foundation


public struct AriaSyncOptions: Codable {
  public var saveLeanMass: Bool
  public var limitSourceToAria: Bool
  public var lastSyncDate: Date?
  public var lastSyncStatus: String
  public var enableHealthKitAccessWarnings: Bool
  public var logString: String
}
