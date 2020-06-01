import UIKit
import Foundation


let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

let now = Date()
let expiry = dateFormatter.date(from: "2018-10-18 14:37:38 +0000")

print("now:    \(dateFormatter.string(from: now))")
print("expiry: \(dateFormatter.string(from: expiry!))")


if (.orderedDescending == expiry!.compare(Date())) {
  print("valid token")
}

if (now < expiry!) { print("valid token") }
