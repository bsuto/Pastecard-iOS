//
//  InterfaceController.swift
//  WatchApp Extension
//
//  Created by Brian Sutorius on 10/17/19.
//  Copyright © 2019 Brian Sutorius. All rights reserved.
//

import WatchKit
import WatchConnectivity
import Foundation

class InterfaceController: WKInterfaceController {
    
    // MARK: Variables and Outlets
    var session : WCSession!
    let cardfile = "pastecard.txt"
    let userfile = "pastecarduser.txt"
    private var item: DispatchWorkItem?
    @IBOutlet weak var cardLabel: WKInterfaceLabel!
    
    @objc func errorAlert(message: String) {
        let ok = WKAlertAction(title: "OK", style: WKAlertActionStyle.default, handler: { return })
         
        presentAlert(withTitle: "Sorry", message: message, preferredStyle: WKAlertControllerStyle.alert, actions: [ok])
    }
    
    func getUsername() -> String {
        var username = ""
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(self.userfile)
            do {
                let userText = try String(contentsOf: fileURL, encoding: .utf8)
                username = userText
            } catch {}
        }
        return username
    }
    
    // MARK: - Load Functions
    
    func loadRemote() {
        // check for logged-in user
        let username = getUsername()
        if username == "" {
            errorAlert(message: "Please log in from the iPhone app first.")
        } else {
            
            // assemble the GET request
            let path = "https://pastecard.net/api/db/"
            let textExtension = ".txt"
            let url = URL(string: path + username + textExtension)
            
            // set a five second timeout before showing error
            item = DispatchWorkItem { [weak self] in
                self?.errorAlert(message: "Unable to load from the server. Please try again later.")
                self?.item = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: item!)
            
            // fire the GET request
            let task = URLSession.shared.downloadTask(with:url!) { localUrl, response, error in
                // if an error, cancel
                if error != nil {
                    self.item?.cancel()
                    self.errorAlert(message: "Error connecting to the Internet. Please try again later.")
                    return
                }
                
                if let localUrl = localUrl {
                    if let remoteText = try? String(contentsOf: localUrl, encoding: .utf8) {
                        // save the text locally and put it in the card
                        DispatchQueue.main.async() {
                            self.saveLocal(text: remoteText)
                            self.cardLabel.setText(remoteText)
                            self.item?.cancel()
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    func loadLocal() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(self.cardfile)
            do {
                let localText = try String(contentsOf: fileURL, encoding: .utf8)
                cardLabel.setText(localText)
            } catch {}
        }
    }
    
    // MARK: - Save Functions
    func saveText(text: String) {
        let username = getUsername()
        
        // prepare the request
        let postData = ("user=" + username + "&text=" + text).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        guard let url = URL(string: "https://pastecard.net/api/bm.php") else {return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postData?.data(using: String.Encoding.utf8)
        
        // set a five second timeout before showing error
        item = DispatchWorkItem { [weak self] in
            self?.errorAlert(message: "Unable to send to the server. Please try again later.")
            self?.item?.cancel()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: item!)
        
        // fire the POST request
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                return
            }
            
            // cancel the timeout
            self.item?.cancel()
            
            // refresh the text
            self.loadRemote()
        }
        task.resume()
    }
    
    func saveLocal(text: String) {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(self.cardfile)
            do {
                try text.write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {}
        }
    }
    
    // MARK: - App Life Cycle
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // start WCSession
        session = WCSession.default
        session.delegate = self
        session.activate()
        
        // refresh card
        // loadRemote()
    }
    
    @IBAction func addText() {
        // check for logged-in user
        let username = getUsername()
        if username == "" {
            errorAlert(message: "Please log in from the iPhone app first.")
        } else {
        presentTextInputController(withSuggestions: [], allowedInputMode: WKTextInputMode.allowEmoji, completion: {(results) -> Void in
                  let aResult = results?[0] as? String
            self.saveText(text: aResult!)})
        }
    }
    
    @IBAction func refresh() {
        loadRemote()
    }
    
    override func willActivate() {
        super.willActivate()
    }
    
    override func didDeactivate() {
        super.didDeactivate()
        
        // cancel any timeouts that may still be running
        self.item?.cancel()
    }
    
}
    // MARK: - WCSessionDelegate
extension InterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("\(applicationContext)")
        
        // set logged-in user from phone
        let loggedIn = applicationContext["username"] as! String
        DispatchQueue.main.async() {
//            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
//                let fileURL = dir.appendingPathComponent(self.userfile)
//                do {
//                    try loggedIn.write(to: fileURL, atomically: false, encoding: .utf8)
//                }
//                catch {}
//            }
            print("\(loggedIn)")
        }
    }
}
