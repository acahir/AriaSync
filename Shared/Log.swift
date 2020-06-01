//
//  Log.swift


import Foundation
import os.log

// os_log wrapper clas
//
// To use
// 1. Define LogCategory enums for your project, leaving the default 'App'
// 2. Set includeFileInfo boolean to control output formatting
// 3. Create an instance of the Log class. ex:
//      #if DEBUG
//        let log: Log? = Log()
//      #endif
//    Note: Yes this could be permenantly unwrapped if you want.
// 4. Call from your code. ex:
//      log?.info(.UI, "This is an info log in the UI category")
// 5. Can optionally include an access type to control output in non-development envs
//    See function defs below.


public class Log: NSObject {
  
  // MARK: - Public enums and functions
  
  public enum LogCategory: String, CaseIterable {
    case App                // default - used for print, dump, and trace functions
    case HealthKitManager
    case FitbitManager
    case UI
    case BackgroundFetch
  }
  
  public enum AccessLevel: String {
    case pub
    case priv
  }
  
  
  // Convenience functions for differet log levels
  public func info(_ category: Log.LogCategory, _ message: String, access: Log.AccessLevel = Log.AccessLevel.priv, fileName: String = #file, lineNumber: Int = #line, functionName: String = #function) {
    log(category, message, access, OSLogType.info, fileName, lineNumber, functionName)
  }
  
  public func debug(_ category: Log.LogCategory, _ message: String, access: Log.AccessLevel = Log.AccessLevel.priv, fileName: String = #file, lineNumber: Int = #line, functionName: String = #function) {
    log(category, message, access, OSLogType.debug, fileName, lineNumber, functionName)
  }
  
  public func error(_ category: Log.LogCategory, _ message: String, access: Log.AccessLevel = Log.AccessLevel.priv, fileName: String = #file, lineNumber: Int = #line, functionName: String = #function) {
    log(category, message, access, OSLogType.error, fileName, lineNumber, functionName)
  }
  
  public func fault(_ category: Log.LogCategory, _ message: String, access: Log.AccessLevel = Log.AccessLevel.priv, fileName: String = #file, lineNumber: Int = #line, functionName: String = #function) {
    log(category, message, access, OSLogType.fault, fileName, lineNumber, functionName)
  }
  
  // The following three use default App category
  public func print(_ value: @autoclosure () -> Any) {
    if let logObj = logs[.App] {
      guard logObj.isEnabled(type: .debug) else { return }
      
      os_log("%{public}@", log: logObj, type: .debug, String(describing: value()))
    }
  }
  
  public func dump(_ value: @autoclosure () -> Any) {
    if let logObj = logs[.App] {
      guard logObj.isEnabled(type: .debug) else { return }
      
      var string = String()
      Swift.dump(value(), to: &string)
      os_log("%{public}@", log: logObj, type: .debug, string)
    }
  }
  
  public func trace(file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    if let logObj = logs[.App] {
      guard logObj.isEnabled(type: .debug) else { return }
      
      let file = URL(fileURLWithPath: String(describing: file)).deletingPathExtension().lastPathComponent
      var function = String(describing: function)
      function.removeSubrange(function.firstIndex(of: "(")!...function.lastIndex(of: ")")!)
      os_log("%{public}@.%{public}@():%ld", log: logObj, type: .debug, file, function, line)
    }
  }
  
  // MARK: - Private functions
  
  // optionally include the filename, line number, and function name at the end of log message
  // in format " [filename.ext:12 theFunction()]"
  private var includeFileInfo = true
  
  
  private var logs: [LogCategory:OSLog] = [:]
  
  
  // create OSLog objects for each category defined
  override init() {
    let subsys = Bundle.main.bundleIdentifier ?? "AriaSync"
    
    for cat in LogCategory.allCases {
      logs[cat] = OSLog(subsystem: subsys, category: cat.rawValue)
    }
  }
  
  
  //
  // wrapper function with defaults:
  //  - private
  //  - debug
  internal func log(_ category: Log.LogCategory, _ message: String, _ access: Log.AccessLevel, _ type: OSLogType, _ fileName: String, _ lineNumber: Int, _ functionName: String) {
    if let logObj = logs[category] {
      
      var msg = message
      if includeFileInfo {
        let file = (fileName as NSString).lastPathComponent
        msg += " [\(file):\(lineNumber) \(functionName)]"
      }
        
      switch access {
      case .priv:
        os_log("%{private}@", log: logObj, type: type, msg)
        
      case .pub:
        os_log("%{public}@", log: logObj, type: type, msg)
      }
    }
  }
  
  

  
}
