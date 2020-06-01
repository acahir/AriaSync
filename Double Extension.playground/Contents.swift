import UIKit

extension Double {
  func divide(by: Double) -> Double {
    return (self/by)
  }
}

var optDouble: Double? = nil
var result = optDouble?.divide(by: 100.0)

optDouble = 20.25
result = optDouble?.divide(by: 100.0)

result = optDouble?.divide(by:0.0)

20.25/0.0

