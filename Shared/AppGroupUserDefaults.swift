//
//  AppGroupUserDefaults.swift
//  AriaSync
//
//  Created by Steve Cochran on 10/23/18.
//

// Convenience utility for working with UserDefaults

import Foundation

extension UserDefaults {
  
  /// - Tag: app_group
  // Note: This project does not share data between iOS and watchOS. Orders placed on the watch will not display in the iOS order history.
  private static let AppGroup = "group.com.ariasync.AriaSync"
  
  enum StorageKeys: String {
    case ariaSyncOptions
  }

  static let dataSuite = { () -> UserDefaults in
    guard let dataSuite = UserDefaults(suiteName: AppGroup) else {
      fatalError("Could not load UserDefaults for app group \(AppGroup)")
    }
    
    return dataSuite
  }()
}
