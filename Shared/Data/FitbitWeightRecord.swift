//
//  FitbitWeightRecord.swift
//  AriaSync
//
//  Created by Steve Cochran on 10/16/18.
//

import Foundation

// Data structures for Fitbit Weight Body Measurements API
// https://api.fitbit.com/1/user/-/body/log/weight/date/
// Notes
//  - body fat percentage record is occasionally missing
//  - body fat percentage record is not officially listed in
//    weight record documentation, but is included. If ever
//    removed, separate endpoint is available.
//
//  Sample record included at end

public struct FitbitWeightRecord: Decodable, CustomStringConvertible {
  let bmi: Double
  let date: Date
  let fat: Double?
  let logId: Int
  let weight: Double
  let source: String?
  
  enum CodingKeys: String, CodingKey {
    case bmi
    case date
    case fat
    case logId
    case weight
    case source
    case time
  }
  
  public var description: String {
    return "\n{\n  \"bmi\":\(bmi),\n  \"date\":\(date),\n  \"fat\":\(String(describing: fat)),\n  \"logId\":\(logId),\n  \"source\":\(String(describing: source)),\n  \"weight\":\(weight)\n}"
  }
  
  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    bmi = try values.decode(Double.self, forKey: .bmi)
    logId = try values.decode(Int.self, forKey: .logId)
    weight = try values.decode(Double.self, forKey: .weight)

    source = try values.decodeIfPresent(String.self, forKey: .source)
      
    // convert to percent
    let tempFat = try values.decodeIfPresent(Double.self, forKey: .fat)
    fat = tempFat?.divide(by: 100.0)
    
    // customize date fields
    let dateStr = try values.decode(String.self, forKey: .date)
    let timeStr = try values.decode(String.self, forKey: .time)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    formatter.timeZone = TimeZone.current
    formatter.locale = Locale.current
    date = formatter.date(from:(dateStr + "T" + timeStr))!
  }
}

struct AllRecords : Decodable {
  let weight: [FitbitWeightRecord]
}

/*
 {
 "weight": [
 {
 "bmi": 23.96,
 "date": "2018-10-11",
 "fat": 20.882999420166016,
 "logId": 1539272693000,
 "source": "Aria",
 "time": "15:44:53",
 "weight": 176.7
 },
 {
 "bmi": 24.37,
 "date": "2018-10-11",
 "fat": 20.979999542236328,
 "logId": 1539276557000,
 "source": "Aria",
 "time": "16:49:17",
 "weight": 179.7
 }
 ]
 }
 */
