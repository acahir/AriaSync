//
//  AriaSyncOptionsManager.swift
//  AriaSync
//
//  Created by Steve Cochran on 10/23/18.
//

import Foundation

public class AriaSyncOptionsManager: DataManager<AriaSyncOptions> {
  
  private static let defaultOptions = AriaSyncOptions(saveLeanMass: true, limitSourceToAria: true, lastSyncDate: nil, lastSyncStatus: "", enableHealthKitAccessWarnings: true, logString: "")
  
  public convenience init() {
    let storageInfo = UserDefaultsStorageDescriptor(key: UserDefaults.StorageKeys.ariaSyncOptions.rawValue,
                                                    keyPath: \UserDefaults.options)

    self.init(storageDescriptor: storageInfo)
  }
  
  // load default settings
  override func deployInitialData() {
    dataAccessQueue.sync {
      managedData = AriaSyncOptionsManager.defaultOptions
    }
  }
}


// Access methods for 'customers'
extension AriaSyncOptionsManager {
  
  public func saveLeanMass() -> Bool {
    return dataAccessQueue.sync {
      return managedData.saveLeanMass
    }
  }
  
  public func limitSourceToAria() -> Bool {
    return dataAccessQueue.sync {
      return managedData.limitSourceToAria
    }
  }
  
  public func lastSyncDate() -> Date? {
    return dataAccessQueue.sync {
      return managedData.lastSyncDate
    }
  }
  
  public func lastSyncStatus() -> String {
    return dataAccessQueue.sync {
      return managedData.lastSyncStatus
    }
  }
  
  public func enableHealthKitAccessWarnings() -> Bool {
    return dataAccessQueue.sync {
      return managedData.enableHealthKitAccessWarnings
    }
  }
  
  public func logString() -> String {
    return dataAccessQueue.sync {
      return managedData.logString
    }
  }

  
  //  Access to UserDefaults is gated behind a seperate access queue.
  public func setSaveLeanMass(value: Bool) {
    dataAccessQueue.sync {
      managedData.saveLeanMass = value
    }
    writeData()
  }
  
  public func setLimitSourceToAria(value: Bool) {
    dataAccessQueue.sync {
      managedData.limitSourceToAria = value
    }
    writeData()
  }
  
  public func setLastSyncDate(date: Date?) {
    dataAccessQueue.sync {
      managedData.lastSyncDate = date
    }
    writeData()
  }
  
  public func setLastSyncStatus(status: String) {
    dataAccessQueue.sync {
      managedData.lastSyncStatus = status
    }
    writeData()
  }
  
  public func setEnableHealthKitAccessWarnings(value: Bool) {
    dataAccessQueue.sync {
      managedData.enableHealthKitAccessWarnings = value
    }
    writeData()
  }
  
  public func setLogString(value: String) {
    dataAccessQueue.sync {
      managedData.logString = value
    }
    writeData()
  }
  
  
  // Save
  // can use default writeData() method from DataManager class
}


// Enable observation of 'UserDefaults' for AriaSyncOptions key
private extension UserDefaults {
  
  @objc var options: Data? {
    return data(forKey: StorageKeys.ariaSyncOptions.rawValue)
  }
}
