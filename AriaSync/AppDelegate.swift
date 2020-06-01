//
//  AppDelegate.swift
//  AriaSync
//
//  Created by Steve Cochran on 10/12/18.
//

import UIKit
import os

#if DEBUG
let log: Log? = Log()
#else
let log: Log? = nil
#endif

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  
  // share one instance of settingsManager so caches values available throughout app
  // avoids some async issues where new values available in separate functions accessing through
  // new instance of AriaSyncOptionsManager
  let settingsManager = AriaSyncOptionsManager()
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // set appearance defaults
    UINavigationBar.appearance().barTintColor = UIColor(red:0.11, green:0.11, blue:0.12, alpha:1.0)
    UINavigationBar.appearance().tintColor = .white
    UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    UINavigationBar.appearance().isTranslucent = false
    
    // Prepare for background fetch
    // This could be 6 or 12 hours...best practice is to weigh oneself at a consistant time every day
    var logString = settingsManager.logString()
    if UIApplication.shared.backgroundRefreshStatus == UIBackgroundRefreshStatus.available {
      log?.info(.BackgroundFetch, "Background Fetch Available")
      logString += "Background fetch Available\n"
    } else {
      // TODO - display warning to user?
      log?.error(.BackgroundFetch, "Background Fetch Unavailable")
      logString += "Background fetch Unavailable\n"
    }
    settingsManager.setLogString(value: logString)
    UIApplication.shared.setMinimumBackgroundFetchInterval(3600)
    
    // trim log string length to 1000? chars
    if logString.count > 1000 {
      let trimmedLog = String(logString.suffix(1000))
      settingsManager.setLogString(value: trimmedLog)
    }
    
    // Override point for customization after application launch.
    return true
  }
  
  func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
    // Note: Fitbit always returns lower case callbackURL, no matter whats entered when registering app
    if "com.ariasync.ariasync" == url.scheme {
      if let navController = window?.rootViewController as! UINavigationController? {
        if let vc = navController.viewControllers[0] as? AriaSyncViewController {
          log?.info(.FitbitManager, "received OAuth Callback URL")
          vc.fitbit.oauth2.handleRedirectURL(url)
          return true
        }
      }
    }
    return false
  }


  // Support for background fetch
  func application(_ application: UIApplication,
                   performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    
    var logString = settingsManager.logString()
    logString += "Background fetch launched at \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))\n"
    settingsManager.setLogString(value: logString)
    
    let fitbit = FitbitAPIManager()
    
    // get either lastSyncDate or create a new date one month in the past
    let startDate = settingsManager.lastSyncDate() ?? Calendar.current.date(byAdding: DateComponents(month: -1), to: Date())!
    
    // call beginSync and pass completionHandler down the chain until all async calls finish
    fitbit.beginSync(type: "weight", start: startDate, end: nil, completion: completionHandler)

    // log details
    log?.info(.BackgroundFetch, "beginning backgroundFetch with start: \(startDate)", access: .pub)
  }

  
  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // refresh UI for potential background fetches
    if let navController = window?.rootViewController as! UINavigationController? {
      if let vc = navController.viewControllers[0] as? AriaSyncViewController {
       vc.updateLastSyncLabelsAndStartDate()
      }
    }
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
}
