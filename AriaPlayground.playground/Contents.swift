import UIKit

let format = DateFormatter()
format.dateFormat = "yyyy-MM-dd"


let startYear = "2012"
var dateComponent = DateComponents()
dateComponent.year = Int(startYear)

let today = Date()

if let startYearDate = Calendar.current.date(from: dateComponent) {
  print(format.string(from:startYearDate))
  
  
  var currMonthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: startYearDate)))!
  var currMonthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: currMonthStart)!
  print(format.string(from:currMonthStart))
  print(format.string(from:currMonthEnd))
  
  repeat  {
    currMonthStart = Calendar.current.date(byAdding: DateComponents(month: 1), to: currMonthStart)!
    currMonthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: currMonthStart)!
    
    if (currMonthEnd < today) {
      print(format.string(from:currMonthStart))
      print(format.string(from:currMonthEnd))
    } else {
      
      print(format.string(from:currMonthStart))
      print(format.string(from:today))
    }
  } while currMonthEnd < today
  

}



format.dateFormat = "yyyy"
let testDate = format.date(from: "2012")
