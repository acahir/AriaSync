//
//  SettingsTableViewController.swift
//  AriaSync
//
//  Created by Steve Cochran on 10/23/18.
//

import UIKit
import SafariServices

class SettingsTableViewController: UITableViewController, SFSafariViewControllerDelegate {

  @IBOutlet weak var leanMassSwitch: UISwitch!
  @IBOutlet weak var sourceSwitch: UISwitch!
  @IBOutlet weak var enableHealthKitAccessWarningsSwitch: UISwitch!
  @IBOutlet weak var settingsTableView: UITableView!
  @IBOutlet weak var startDateLabel: UILabel!
  @IBOutlet weak var startDatePicker: UIDatePicker!
  let format = DateFormatter()
  let settingsManager = (UIApplication.shared.delegate as! AppDelegate).settingsManager
  
  
  var datePickerIsVisibile = false
  var parentAriaSyncVC: AriaSyncViewController?
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Hack - should probably be a delegate
    if let navController = self.navigationController {
      parentAriaSyncVC = navController.viewControllers[0] as? AriaSyncViewController
    }
    
    // load settings from UserDefaults
    leanMassSwitch.isOn = settingsManager.saveLeanMass()
    sourceSwitch.isOn = settingsManager.limitSourceToAria()
    sourceSwitch.isOn = settingsManager.limitSourceToAria()
    enableHealthKitAccessWarningsSwitch.isOn = settingsManager.enableHealthKitAccessWarnings()
    
    format.dateFormat = "yyyy-MM-dd"
    startDatePicker.minimumDate = format.date(from: "2010-01-01")
    startDatePicker.maximumDate = Date()
    
    
    if parentAriaSyncVC != nil {
        startDateLabel.text = format.string(from:parentAriaSyncVC!.getSyncStartDate())
    }
  }

  
  @IBAction func leanMassSwitchChanged(_ sender: UISwitch) {
    settingsManager.setSaveLeanMass(value: sender.isOn)
  }
  
  @IBAction func sourceSwitchChanged(_ sender: UISwitch) {
    settingsManager.setLimitSourceToAria(value: sender.isOn)
  }

  @IBAction func enableHealthKitAccessWarningsSwitchChanged(_ sender: UISwitch) {
    settingsManager.setEnableHealthKitAccessWarnings(value: sender.isOn)
  }
  
  //
  // Clear local auth tokens and open Fitbit logout URL
  //
  @IBAction func logout(_ sender: UIButton) {
    clearOauthTokensAction(sender)
    
    let urlString = "https://www.fitbit.com/logout"
    
    if let url = URL(string: urlString) {
      let vc = SFSafariViewController(url: url)
      vc.delegate = self
      
        present(vc, animated: false)
      //ANIMATE present(vc, animated: true)
    }
  }
  
  func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
    dismiss(animated: false)
    //ANIMATE dismiss(animated: true)
  }
  
  
  @IBAction func resetLastSyncDateAction(_ sender: UIButton) {
    settingsManager.setLastSyncDate(date: nil)
    settingsManager.setLastSyncStatus(status: "")
    
    // update startDateLabel
    if let newStartDate = Calendar.current.date(byAdding: DateComponents(month: -1), to: Date()) {
      startDateLabel.text = format.string(from:newStartDate)
    }
    
    // update lastSync* labels and _syncStartDate
    if parentAriaSyncVC != nil {
      parentAriaSyncVC!.updateLastSyncLabelsAndStartDate()
    }
  }
  
  
  // Clear out OAuth tokens
  @IBAction func clearOauthTokensAction(_ sender: UIButton) {
    if parentAriaSyncVC != nil {
      parentAriaSyncVC!.fitbit.oauth2.forgetTokens()
    }
  }
  
  
  //
  //  User completed selecting date and clicked Done in toolbar
  //
  @IBAction func datePickerDoneAction(_ sender: Any) {
    
    // update label
    startDateLabel.text = format.string(from: startDatePicker.date)
    
    if parentAriaSyncVC != nil {
      parentAriaSyncVC!.setSyncStartDate(start: startDatePicker.date)
    }
    
    // hide date picker
    toggleDatePicker()
  }
  
  
  func toggleDatePicker() {
    // set date picker to current value of label
    // TODO - check if needed. Date picker might default to last used,
    // but not if new app launch
    // startDatePicker.date = format.date(from: self.startDateLabel.text!)!
    
    // toggle flag for row height
    datePickerIsVisibile = !datePickerIsVisibile
    
    // Update table display
    let datePickerIndexPath = IndexPath(row: 1, section: 2)
    
    tableView.beginUpdates()
    tableView.reloadRows(at: [datePickerIndexPath], with: .none)
    tableView.endUpdates()
  }
  
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
      return 3
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch section {
      case 0: return 3
      case 1: return 1
      case 2: return 5
      default: return 0
    }
  }
  
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if (indexPath.section == 2 && indexPath.row == 0) {
      toggleDatePicker()
    }
  }
  
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
  {
    if (indexPath.section == 2 && indexPath.row == 1 && datePickerIsVisibile) {
      // date picker row height
      return 160
    } else if (indexPath.section == 2 && indexPath.row == 1 && !datePickerIsVisibile) {
      // date picker row height when hidden
      return 0
    }
    // standard row height
    return 44
  }
}
