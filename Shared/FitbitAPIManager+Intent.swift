//
//  FitbitAPIManager+Intent.swift
//  AriaSync
//
//  Created by Steve Cochran on 10/17/18.
//

import Foundation
import UIKit
import OAuth2

struct dateRange {
  var start: Date
  var end: Date
}

//
// Protocol for callers of FitbitAPIManager class
// - provides connection back to 'owner' for status, completion notifications etc
//
protocol FitbitAPIManagerDelegate: class {
  func postFitbitSync(succeeded: Bool, saved: Int, status: String)
}

public class FitbitAPIManager {

  // delegate is used for UI status update after sync completion
  // not used for backgroundFetch
  weak var delegate: FitbitAPIManagerDelegate?
  
  var requestBaseDict: [String:String]
  var loader: OAuth2DataLoader?
  var oauth2: OAuth2CodeGrant

  private let subsystem = "com.ariasync.AriaSync.FitbitAPIMgr"
 
  let format = DateFormatter()
  
  // keep count of total records across multiple API requests
  // used for UI feedback and verification of HealthKit saves
  var receivedCount = 0
  
  // tracks overall success for a sync attempt
  var syncSuccess = false
  
  let settingsManager = (UIApplication.shared.delegate as! AppDelegate).settingsManager
  
  // Init GCD
  // use one group for network and Healthkit calls
  let asyncGroup = DispatchGroup()
  let hkit = HealthKitManager()
  
  init() {
    // init date formatter
    format.dateFormat = "yyyy-MM-dd"
    
    // get api keys from xcconfig files to keep them secret
    let fitbitAPIClientID = Bundle.main.object(forInfoDictionaryKey: "FITBIT_API_CLIENT_ID")
    let fitbitAPIClientSecret = Bundle.main.object(forInfoDictionaryKey: "FITBIT_API_CLIENT_SECRET")
    
    let clientID = fitbitAPIClientID ?? ""
    let secret = fitbitAPIClientSecret ?? ""
    // TODO - handle unavailable API settings here?
    // one option is to configure a failable initializer and return nil if settings missing
    
    // init and configure oauth2
    oauth2 = OAuth2CodeGrant(settings: [
      "client_id": clientID,
      "client_secret": secret,
      "authorize_uri": "https://www.fitbit.com/oauth2/authorize",
      "token_uri": "https://api.fitbit.com/oauth2/token",
      "redirect_uris": ["com.ariasync.ariasync://oauth/callback"],
      "scope": "weight",
      "secret_in_body": false,
      "keychain": true,
      "keychain_access_group": "group.com.ariasync.AriaSync",
      "verbose": true,
      ] as OAuth2JSON)
    
    oauth2.authConfig.authorizeEmbedded = true

    // dict of
    requestBaseDict = ["weight":"https://api.fitbit.com/1/user/-/body/log/weight/date/"]
  }

  
  func beginSync(type: String, start: Date, end: Date?, completion: @escaping ((UIBackgroundFetchResult) -> Void) = {_ in }) {
    
    let settingsManager = (UIApplication.shared.delegate as! AppDelegate).settingsManager
    var logString = settingsManager.logString()
    
    let beginString = delegate != nil ? "Beginning sync from" : "Background sync from"
    if end != nil {
      logString += "\(beginString) \(format.string(from:start)) till \(format.string(from:end!))\n"
    } else {
      logString += "\(beginString) \(format.string(from:start))\n"
    }
    settingsManager.setLogString(value: logString)
    
    
    // reset per sync status vars
    receivedCount = 0
    syncSuccess = false
    
    // make sure we have a valid context
    // can't happen in init because VC not created when this obj is
    oauth2.authConfig.authorizeContext = delegate
    
    // sanity checks
    if (end != nil) && (start >= end!) {
      log?.error(.FitbitManager, "start date is after end date")
      
      // call completion with failed status
      completion(.failed)
      return
    }
    
    if let typeBase = requestBaseDict[type] {
      let requestArray = createRequestArray(start: start, end: end)
      
      // pass array to be built into urls to request
      getData(base: typeBase, requests: requestArray, completion: completion)
    } else {
      log?.error(.FitbitManager, "unknown type for fitbit API request: \(type)")
    }
  }
  
  
  //
  // Creates an array of date ranges, from the start date through current date
  // - each range is limited to a max of 31 days, by using month ranges
  // - results are formatted "yyyy-MM-dd" for use in URL
  //
  func createRequestArray(start: Date, end: Date?) -> [dateRange] {

    var requestDates = [dateRange]()
    let endDate = end ?? Date()
    
    // beginning from start, loop through each month until today
    var currMonthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: start)))!
    var currMonthEnd: Date
    
    repeat {
      currMonthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: currMonthStart)!
      
      if ((currMonthStart < start) && (currMonthEnd > endDate)) {
        // only one range, in same month
        requestDates.append(dateRange(start: start, end: endDate))
      } else if (currMonthStart < start) {
        // first range
        requestDates.append(dateRange(start: start, end: currMonthEnd))
      } else if (currMonthEnd > endDate) {
        // last range
        requestDates.append(dateRange(start: currMonthStart, end: endDate))
      } else {
        requestDates.append(dateRange(start: currMonthStart, end: currMonthEnd))
      }
      
      currMonthStart = Calendar.current.date(byAdding: DateComponents(month: 1), to: currMonthStart)!
    } while currMonthEnd < endDate
    
    
    #if DEBUG
      var ranges = ""
      for currPair in requestDates {
        ranges += "\n    \(format.string(from:currPair.start)) to \(format.string(from:currPair.end))"
      }
      log?.debug(.FitbitManager, "date Ranges: \(ranges)")
    #endif
    
    return requestDates
  }


  //
  // Loops through array of dateRange to create and send API URL requests
  // Calls parseData with each response
  //
  func getData(base: String, requests: [dateRange], completion: @escaping ((UIBackgroundFetchResult) -> Void) = {_ in }) {
    // This is probably unnessisary, was in example app
    if oauth2.isAuthorizing {
      oauth2.abortAuthorization()
      log?.error(.FitbitManager, "OAuth still authorizing; cancelling sync")
      return
    }
    
    let loader = OAuth2DataLoader(oauth2: oauth2)
    self.loader = loader
    
    for currPair in requests {
      let startString = format.string(from:currPair.start)
      let endString = format.string(from:currPair.end)
      let urlString = base + startString + "/" + endString + ".json"
      let url = URL(string: urlString)
      
      if url == nil {
        log?.error(.FitbitManager, "error creating url from: \(currPair)")
        continue
      }
      
      log?.info(.FitbitManager, "built url for request: \(url!)")
      
      // create request
      // Note: this will also add Auth headers if tokens found
      var request = oauth2.request(forURL: url!)
      request.setValue("en_US", forHTTPHeaderField: "Accept-Language")
    
      // each month of data requested is a separate API fetch
      // using asyncGroup to manage completion
      asyncGroup.enter()
      loader.perform(request: request) { response in
        do {
          // response, try to parse
          let raw = try response.responseData()
          self.parseData(data: raw, loader: loader)
        }
        catch let error {
          switch error {
          case OAuth2Error.noTokenType:
            log?.error(.FitbitManager, "OAuth error no tokens received. Clearing local tokens: \(error)")
            // clear tokens and try again
            self.oauth2.forgetTokens()
          default:
            log?.error(.FitbitManager, "error on API request: \(error)")
          }
        }
        self.asyncGroup.leave()
      }
    }
    
    // async completion block
    // this is executed after all fitbit API and healthkit saves are complete
    //
    // How to measure for success
    // This app makes multiple async calls to both fitbit API and healthkit, so success
    // isn't as clear as true/false.
    //
    // Coded as one or more API responses with valid 'weight' array.
    // This means:
    //  - success even if no actual records are returned (empty array)
    //  - partial failures potentially harder to recover from and troubleshoot
    asyncGroup.notify(queue: .main) {
      
      if self.syncSuccess {
        // do any success completions here
        
        // get saved count and build string w/ correct grammer
        let (saved, skipped, errors) = self.hkit.getResults()
        let savedString = (saved == 1 ? "\(saved) record" : "\(saved) records")
        
        // update lastSync records

        self.settingsManager.setLastSyncDate(date: requests.last?.end)
        self.settingsManager.setLastSyncStatus(status: "\(savedString) added")
        
        // update log record
        var logString = self.settingsManager.logString()
        logString += "Sync complete with\n    \(saved) saved, \(skipped) skipped, and \(errors) errors\n"
        self.settingsManager.setLogString(value: logString)
        
        log?.info(.FitbitManager, "successful sync: received \(self.receivedCount), saved \(savedString)")
        
        // update UI
        if self.delegate != nil {
          self.delegate?.postFitbitSync(succeeded: true, saved: saved, status: "Received \(self.receivedCount), saved \(saved)")
        } else {
          // if no delegate, launched via backgroundFetch...hopefully
          self.settingsManager.setLastSyncStatus(status: "\(savedString) added via backgroundFetch")
        }
        
        // ensure changes persisted, mostly for background fetch runs
        UserDefaults.dataSuite.synchronize()

        // run completion handler for background fetch
        self.receivedCount > 0 ? completion(.newData) : completion(.noData)
      } else {
        // no succesful data responses from Fitbit
        // do any failure completions here
        
        // run completion handler for background fetch
        completion(.failed)
        
        log?.error(.FitbitManager, "Sync failed with no valid responses from API")
        
        // update UI
        if self.delegate != nil {
          self.delegate?.postFitbitSync(succeeded: false, saved: 0, status: "Sync failed with no valid responses from API")
        }
      }
      
      // reset hkKit vars
      self.hkit.reset()
    }
  }


  //
  // Takes response from API call and parses the data into data model
  // Calls HealthKitManager.saveRecords with results
  //
  func parseData(data: Data, loader: OAuth2DataLoader?) {
    do {
      let decoder = JSONDecoder()
      let records = try decoder.decode(AllRecords.self, from: data)
      
      // if that try worked, we had a valid response even if 0 records.
      // that means at least partial success in sync
      syncSuccess = true
      log?.debug(.FitbitManager, "Parsed API response: \(records)")
      
      // if we have any records
      if (records.weight.count > 0) {
        
        // keep total of records from all requests
        receivedCount += records.weight.count
        
        // get options from preferences to pass to HealthKit
        let settingsManager = AriaSyncOptionsManager()
        
        // save data through HealthKitManager
        // includes async call HealthKitStore.save(), shares dispatchgroup
        // with network requests
        hkit.saveRecords(allRecords: records, group: asyncGroup, doLeanMass: settingsManager.saveLeanMass(), doLimitSourceToAria:  settingsManager.limitSourceToAria())
      }
    } catch {
      // error decoding response
      if let dataString = String(data: data, encoding: .utf8) {
        log?.error(.FitbitManager, "Parsing API response choked on: \(dataString)")
      }
    }
  }
}
