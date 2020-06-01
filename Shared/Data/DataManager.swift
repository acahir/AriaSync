/*
 Copyright © 2018 Apple Inc.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 
 Abstract:
 A data manager that manages data conforming to `Codable` and stores it in `UserDefaults`.
 */

import Foundation

/// Provides storage configuration information to `DataManager`
struct UserDefaultsStorageDescriptor {
  /// A `String` value used as the key name when reading and writing to `UserDefaults`
  let key: String
  
  /// A key path to a property on `UserDefaults` for observing changes
  let keyPath: KeyPath<UserDefaults, Data?>
}

/// Clients of `DataManager` that want to know when the data changes can listen for this notification.
public let dataChangedNotificationKey = NSNotification.Name(rawValue: "DataChangedNotification")



/// `DataManager` is an abstract class manging data conforming to `Codable` that is saved to `UserDefaults`.
public class DataManager<ManagedDataType: Codable> {
  
  /// This sample uses App Groups to share a suite of data between the main app and the different extensions.
  let userDefaults = UserDefaults.dataSuite
  
  /// To prevent data races, all access to `UserDefaults` uses this queue.
  private let userDefaultsAccessQueue = DispatchQueue(label: "User Defaults Access Queue")
  
  /// Storage and observation information.
  private let storageDescriptor: UserDefaultsStorageDescriptor
  
  /// A flag to avoid receiving notifications about data this instance just wrote to `UserDefaults`.
  private var ignoreLocalUserDefaultsChanges = false
  
  /// The observer object handed back after registering to observe a property.
  private var userDefaultsObserver: NSKeyValueObservation?
  
  /// The data managed by this `DataManager`. Only access this via on the `dataAccessQueue`.
  var managedData: ManagedDataType!
  
  /// Access to `managedData` needs to occur on a dedicated queue to avoid data races.
  let dataAccessQueue = DispatchQueue(label: "Data Access Queue")
  
  init(storageDescriptor: UserDefaultsStorageDescriptor) {
    self.storageDescriptor = storageDescriptor
    loadData()
    
    if managedData == nil {
      deployInitialData()
      writeData()
    }
    
    observeChangesInUserDefaults()
  }
  
  /// Subclasses are expected to implement this method and set their own initial data for `managedData`.
  func deployInitialData() {
    
  }
  
  private func observeChangesInUserDefaults() {
    userDefaultsObserver = userDefaults.observe(storageDescriptor.keyPath) { [weak self] (_, _) in
      // Ignore any change notifications coming from data this instance just saved to `UserDefaults`.
      guard self?.ignoreLocalUserDefaultsChanges == false else { return }
      
      // The underlying data changed in `UserDefaults`, so update this instance with the change and notify clients of the change.
      self?.loadData()
      self?.notifyClientsDataChanged()
    }
  }
  
  /// Notifies clients the data changed by posting a `Notification` with the key `dataChangedNotificationKey`
  private func notifyClientsDataChanged() {
    NotificationCenter.default.post(Notification(name: dataChangedNotificationKey, object: self))
  }
  
  /// Loads the data from `UserDefaults`.
  private func loadData() {
    userDefaultsAccessQueue.sync {
      guard let archivedData = userDefaults.data(forKey: storageDescriptor.key) else { return }
      
      do {
        let decoder = PropertyListDecoder()
        managedData = try decoder.decode(ManagedDataType.self, from: archivedData)
      } catch let error as NSError {
        log?.error(.App, "Error decoding data: \(error)")
      }
    }
  }
  
  /// Writes the data to `UserDefaults`.
  func writeData() {
    userDefaultsAccessQueue.async {
      do {
        let encoder = PropertyListEncoder()
        let encodedData = try encoder.encode(self.managedData)
        
        self.ignoreLocalUserDefaultsChanges = true
        self.userDefaults.set(encodedData, forKey: self.storageDescriptor.key)
        self.ignoreLocalUserDefaultsChanges = false
        
        self.notifyClientsDataChanged()
        
      } catch let error as NSError {
        log?.error(.App, "Could not encode data \(error)")
      }
    }
  }
}
