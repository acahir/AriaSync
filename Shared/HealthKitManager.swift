//
//  HealthKitManager.swift
//  AriaSync
//
//  Created by Steve Cochran on 10/17/18.
//

import Foundation
import HealthKit

public class HealthKitManager {
  private let subsystem = "com.ariasync.AriaSync.HealthKitManager"
  
  private var savedCount = 0
  private var skippedCount = 0
  private var errorCount = 0
  private lazy var healthStore = HKHealthStore()
  
  // TODO: Figure out how to guard these but keep as class properties
  private let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
  private let bodyMassIndexType = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!
  private let bodyFatPercentageType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
  private let leanBodyMassType = HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!

  
  init() {
    
  }
  
  func reset() {
    (savedCount, skippedCount, errorCount) = (0, 0, 0)
  }

  func getResults() -> (Int, Int, Int) {
    return (savedCount, skippedCount, errorCount)
  }


  func saveRecords (allRecords: AllRecords, group: DispatchGroup?, doLeanMass: Bool, doLimitSourceToAria: Bool) {
    // set up dispatch group if one not provided
    let asyncGroup = group ?? DispatchGroup()
    
    let records = allRecords.weight
    
    // loop through each record and add to HealthKit
    for currRecord in records {
      
      // optionally exclude records not from Aria
      if (doLimitSourceToAria  && currRecord.source != "Aria") {
        skippedCount += 1
        continue
      }
      
      var currSamples = [HKQuantitySample]()
      
      // set up sync keys
      // this allows multiple runs without duplicating data
      let metadata = [HKMetadataKeySyncIdentifier:String(currRecord.logId),
                      HKMetadataKeySyncVersion:1.0,
                      HKMetadataKeyExternalUUID:String(currRecord.logId)] as [String : Any]
      
      // body mass
      if healthStore.authorizationStatus(for: bodyMassType) == .sharingAuthorized {
        let bodyMassQuantity = HKQuantity(unit: HKUnit.pound(), doubleValue:currRecord.weight)
        currSamples.append(HKQuantitySample(type: bodyMassType,
                                            quantity: bodyMassQuantity,
                                            start: currRecord.date,
                                            end: currRecord.date,
                                            metadata: metadata))
      } else {
        log?.info(.HealthKitManager, "body mass not authorized")
      }
      
      
      // body mass index
      if healthStore.authorizationStatus(for: bodyMassIndexType) == .sharingAuthorized {
        let bodyMassIndexQuantity = HKQuantity(unit: HKUnit.count(), doubleValue:currRecord.bmi)
        currSamples.append(HKQuantitySample(type: bodyMassIndexType,
                                            quantity: bodyMassIndexQuantity,
                                            start: currRecord.date,
                                            end: currRecord.date,
                                            metadata: metadata))
      } else {
        log?.info(.HealthKitManager, "body mass index not authorized")
      }
      
      // body fat percentage
      if (currRecord.fat != nil) && healthStore.authorizationStatus(for: bodyFatPercentageType) == .sharingAuthorized {
        let bodyFatPercentageQuantity = HKQuantity(unit: HKUnit.percent(), doubleValue:currRecord.fat!)
        currSamples.append(HKQuantitySample(type: bodyFatPercentageType,
                                            quantity: bodyFatPercentageQuantity,
                                            start: currRecord.date,
                                            end: currRecord.date,
                                            metadata: metadata))
      } else {
        if currRecord.fat == nil {
          log?.debug(.HealthKitManager, "body fat percentage not found")
        } else {
          log?.info(.HealthKitManager, "body fat percentage not authorized")
        }
      }
      
      // lean body mass percentage
      if (doLeanMass && currRecord.fat != nil) &&
        (healthStore.authorizationStatus(for: leanBodyMassType) == .sharingAuthorized) {
        
        // calculate lean mass
        let leanSample = currRecord.weight - (currRecord.weight * currRecord.fat!)
        
        let leanBodyMassQuantity = HKQuantity(unit: HKUnit.pound(), doubleValue:leanSample)
        currSamples.append(HKQuantitySample(type: leanBodyMassType,
                                            quantity: leanBodyMassQuantity,
                                            start: currRecord.date,
                                            end: currRecord.date,
                                            metadata: metadata))
      } else {
        if currRecord.fat == nil {
          log?.debug(.HealthKitManager, "lean body mass not found")
        } else {
          log?.info(.HealthKitManager, "lean body mass not authorized")
        }
      }
    
      // HealthKit saves are async
      // use GCD group to notify when all saves complete
      asyncGroup.enter()
      healthStore.save(currSamples) { (success, error) in
        if let error = error {
          self.errorCount += 1
          let msg = "Error saving Healthkit Sample: \(error.localizedDescription)"
          log?.error(.HealthKitManager, msg)
        } else {
          self.savedCount += 1
          log?.debug(.HealthKitManager, "Successfully saved samples")
        }
        asyncGroup.leave()
      }
    }
  }

} // HealthkitManager
