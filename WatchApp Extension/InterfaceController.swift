//
//  InterfaceController.swift
//  WatchApp Extension
//
//  Created by Brian Sutorius on 10/17/19.
//  Copyright © 2019 Brian Sutorius. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    
    // MARK: Variables and Outlets
    let shareDefaults = UserDefaults(suiteName: "group.net.pastecard")
    var username = ""
    let file = "pastecard.txt"
    var emergencyText = ""

    // MARK: Load Functions
    
    // check if username is nil, set label to something
    // check reachabilit
    
    // MARK: Save Functions
    func saveText(text: String) {
        
        
        
//        // prepare the request
//        let postData = ("user=" + username + "&text=" + text).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
//        guard let url = URL(string: "https://pastecard.net/api/bm.php") else {return}
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.httpBody = postData?.data(using: String.Encoding.utf8)
//
//        // set a five second timeout and attempt to write the text to the server
//        let timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector, userInfo: nil, repeats: false)
//        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
//            if error != nil {
//                return
//            }
//
//            // on success, pause a little bit so the Saving message is actually readable
//            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
//
//                // cancel the timer and clean up
//                timer.invalidate()
//            }
//        }
//        task.resume()
    }
    
    // MARK: App Life Cycle
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        self.setTitle("Pastecard")
        
        
        
        // attempt to load
        
    }
    
    @IBAction func addText() {
        presentTextInputController(withSuggestions: [], allowedInputMode: WKTextInputMode.allowEmoji, completion: {(results) -> Void in
                  let aResult = results?[0] as? String
            self.saveText(text: aResult!)})
    }
    
    @IBAction func refresh() {
        // load function
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
