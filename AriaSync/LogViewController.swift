//
//  LogViewController.swift
//  AriaSync
//
//  Created by Steve Cochran on 1/17/19.
//

import UIKit

class LogViewController: UIViewController {

  @IBOutlet weak var logTextView: UITextView!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    let settingsManager = (UIApplication.shared.delegate as! AppDelegate).settingsManager
  
    logTextView.text = settingsManager.logString()
  
  // scroll to bottom of textView
    if logTextView.text.count > 0 {
      let range = NSMakeRange((logTextView.text as NSString).length - 1, 1);
      logTextView.scrollRangeToVisible(range)
    }
  }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
