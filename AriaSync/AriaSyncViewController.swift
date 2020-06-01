//  ViewController.swift
//  AriaSync
//
//  Created by Steve Cochran on 10/12/18

import UIKit
import HealthKit
import OAuth2

struct hk {
  // Healthkit quasi-constants
  static let bodyFatType = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!
  static let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
  static let bodyMassIndexType = HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!
  static let leanBodyMassType = HKObjectType.quantityType(forIdentifier: .leanBodyMass)!
  static let allTypes = Set([bodyFatType, bodyMassType, bodyMassIndexType, leanBodyMassType])
}

class AriaSyncViewController: UIViewController, FitbitAPIManagerDelegate {

  @IBOutlet weak var lastSyncDateLabel: UILabel!
  @IBOutlet weak var lastSyncStatusLabel: UILabel!
  @IBOutlet weak var statusTextView: UITextView!
  @IBOutlet weak var syncButton: UIButton!
  
  lazy var healthStore = HKHealthStore()
  var fitbit = FitbitAPIManager()
  let format = DateFormatter()
  private var _syncStartDate = Date()
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // FitbitAPIManager init
    fitbit.delegate = self
    
    // Healthkit check
    if !(HKHealthStore.isHealthDataAvailable()) {
      // display confirmation alert
      let message = "This device does not support HealthKit, which is required for this app to function."
      let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
      self.present(alert, animated: false)
      //ANIMATE self.present(alert, animated: true, completion: nil)
      
      // disable sync button
      syncButton.isEnabled = false
      print("No Healthkit support")
      // don't auto quit app, bad UI
    }
    
    // set up dateFormatter with display and API format
    format.dateFormat = "yyyy-MM-dd"
    
    // check for healthKit access and request if nessisary
    checkHealthKitRequestStatus()
    
    // update lastSync* labels and reset _syncStartDate
    updateLastSyncLabelsAndStartDate()
  }
  
  //
  // checkHealthKitRequestStatus
  // - check if app needs to request authorization from healthkit
  // - handles both initial app launch and if user reset privacy warnings
  // - can call HK.requestAuthorization repeatedly without UI problems, but
  //   this way we can display a info alert before that call without displaying
  //   when not needed
  func checkHealthKitRequestStatus() {
    healthStore.getRequestStatusForAuthorization(toShare: hk.allTypes, read: Set([]), completion:  { (requestStatus, error) in
      if requestStatus == .shouldRequest {
        self.doHealthKitRequest()
      } else if let errorString = error?.localizedDescription {
        // error occured
        log?.error(.UI, "getRequestStatusForAuthorization error: \(errorString)")
      }
    })
  }
  
  //
  // Handles the UI and actual Health Kit authorization request
  //
  func doHealthKitRequest() {
    let message = "AriaSync is a simple app to copy data from Fitbit's Aria scale to Apple's Healthkit.\n\nFor AriaSync to work, you will be prompted to grant it permissions to add data to HealthKit."
    let alert = UIAlertController(title: "Welcome to AriaSync", message: message, preferredStyle: .alert)
    let continueAction = UIAlertAction(title: "Continue", style: .default, handler: { action in
      self.requestHealthKitAccess()
    })
    alert.addAction(continueAction)
    
    // display alert and request access
    self.present(alert, animated: false)
    //ANIMATE self.present(alert, animated: true, completion: nil)
  }
  
  
  //
  // Do healthkit authorization request
  //
  func requestHealthKitAccess() {
    healthStore.requestAuthorization(toShare: hk.allTypes, read: nil) { (success, error) in
      // this returns success even if grant view is not displayed on repetative calls
      // or user denies all access
      if !success {
        if let errorString = error?.localizedDescription {
          log?.error(.UI, "HKrequestAuthorization error: \(errorString)")
        }
      } else {
        log?.debug(.UI, "HKrequestAuthorization success")
      }
    }
  }
  
  
  //
  // Check HealthKit Permissions
  // - entry point for sync button press
  // - type specific checks before beginning sync
  // - calls doFitbitSync to continue
  @IBAction func checkHealthKitAccess() {
    let settingsManager = (UIApplication.shared.delegate as! AppDelegate).settingsManager
    
    var deniedTypes = ""
    
    if healthStore.authorizationStatus(for: hk.bodyFatType) != .sharingAuthorized {deniedTypes += "Body Fat Percentage\n"}
    if healthStore.authorizationStatus(for: hk.bodyMassType) != .sharingAuthorized {deniedTypes += "Weight\n"}
    if healthStore.authorizationStatus(for: hk.bodyMassIndexType) != .sharingAuthorized {deniedTypes += "Body Mass Index\n"}
    if healthStore.authorizationStatus(for: hk.leanBodyMassType) != .sharingAuthorized {deniedTypes += "Lean Body Mass\n"}
    
    // check if anything is denied
    if (deniedTypes != "") {
      
      if (settingsManager.enableHealthKitAccessWarnings()) {
        // display modal warning
        let message = "AriaSync currently does not have permission to access the following:\n\n" + deniedTypes + "\nThis setting can be changed in the Settings under Privacy."
        let alert = UIAlertController(title: "Healthkit Access", message: message, preferredStyle: .alert)
        
        // set up action to open the Settings app. App will open to last screen,
        // doesn't seem to be a way to specify a path any more
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (alertAction) in
          if let privacySettings = URL(string: "App-prefs:root=Privacy") {
            UIApplication.shared.open(privacySettings, options: [:], completionHandler: nil)
          }
        }
        alert.addAction(settingsAction)
        alert.preferredAction = settingsAction
        
        // action to disable future warnings and continue with sync
        alert.addAction(UIAlertAction(title:"Disable Warning & Continue", style: .cancel, handler: { action in
          settingsManager.setEnableHealthKitAccessWarnings(value:false)
          self.doFitbitSync()
          log?.info(.UI, "Healthkit access warnings Disabled")
        }))
        
        self.present(alert, animated: false)
        //ANIMATE self.present(alert, animated: true, completion: nil)
        
      } else {
        // user has suppresed warning messages, just log
        deniedTypes = deniedTypes.replacingOccurrences(of: "\n", with: " ")
        log?.debug(.UI, "Healthkit denied access for\(deniedTypes) and warnings disabled")
      }
    }
    self.doFitbitSync()
  }
  
  // _syncStartDate getters and setters
  func getSyncStartDate() -> Date {
    return _syncStartDate
  }
  func setSyncStartDate(start: Date) {
    _syncStartDate = start
  }
  
  func updateLastSyncLabelsAndStartDate() {
    let settingsManager = (UIApplication.shared.delegate as! AppDelegate).settingsManager
    
    if let lastSyncDate = settingsManager.lastSyncDate() {
      format.dateFormat = "MMM dd 'at' h:mm a"
      lastSyncDateLabel.text = "Last Sync: \(format.string(from:lastSyncDate))"
      format.dateFormat = "yyyy-MM-dd"
      
      _syncStartDate = lastSyncDate
    } else {
      lastSyncDateLabel.text = "Last Sync: Never"
      
      _syncStartDate = Calendar.current.date(byAdding: DateComponents(month: -1), to: Date())!
    }
    
    self.lastSyncStatusLabel.text = settingsManager.lastSyncStatus()
  }
  
  
  //
  //  Begin data sync
  //
  func doFitbitSync() {
    // Update UI to show sync in progress
    statusTextView.text = "Syncing data from Fitbit...\n"
    
    fitbit.beginSync(type: "weight", start: _syncStartDate, end: nil)
  }

  
  //
  // FitbitAPIManager Delegate functions
  //
  func postFitbitSync(succeeded: Bool, saved: Int, status: String) {
    
    if succeeded {
      
      // display confirmation alert
      let message = "Aria data synced successfully.\n\n\(saved) records added"
      let alert = UIAlertController(title: "Sync Complete", message: message, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
      self.present(alert, animated: false)
      //ANIMATE self.present(alert, animated: true, completion: nil)
      
      // TODO: move textView to debug log from settings page
      self.statusTextView.text = self.statusTextView.text! + "Sync Complete: \(status)\n"
      log?.debug(.UI, "Sync Complete: \(status)")
      
      // update UI
      updateLastSyncLabelsAndStartDate()
    
    } else {
      format.dateFormat = "MMM dd 'at' h:mm a"
      self.lastSyncStatusLabel.text = "attempted sync failed at \(format.string(from:Date()))"
      format.dateFormat = "yyyy-MM-dd"
    }
  }
}

