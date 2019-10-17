//
//  ShareViewController.swift
//  TextExtension
//
//  Created by Brian Sutorius on 10/17/19.
//  Copyright © 2019 Brian Sutorius. All rights reserved.
//

import UIKit

class ShareViewController: UIViewController {
    
    let shareDefaults = UserDefaults(suiteName: "group.net.pastecard")
    
    // hide the dialog and kill the extension
    @objc func cleanUp() {
        self.view.viewWithTag(1)?.isHidden = true
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    func saveToServer(user: String, text: String) {
        // show the saving dialog
        self.view.viewWithTag(1)?.isHidden = false
        
        // prepare the request
        let postData = ("user=" + user + "&text=" + text).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        guard let url = URL(string: "https://pastecard.net/api/bm.php") else {return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postData?.data(using: String.Encoding.utf8)
        
        // set a five second timeout and attempt to write the text to the server
        let timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.cleanUp), userInfo: nil, repeats: false)
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                self.cleanUp()
                return
            }
            
            // on success, pause a little bit so the Saving message is actually readable
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                
                // cancel the timer and clean up
                timer.invalidate()
                self.cleanUp()
            }
        }
        task.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get the logged-in user from the main app
        if let username = shareDefaults!.string(forKey: "username"), !username.isEmpty {
            
            if let item = extensionContext?.inputItems.first as? NSExtensionItem {
                if let attachments = item.attachments {
                    for attachment: NSItemProvider in attachments {
                        if attachment.hasItemConformingToTypeIdentifier("public.text") {
                            attachment.loadItem(forTypeIdentifier: "public.text", options: nil, completionHandler: { (results, error) in
                                var shareText = results as! String
                                    
                                    // remove protocol
                                    shareText = shareText.replacingOccurrences(of: "https://", with: "", options: .literal, range: nil)
                                    shareText = shareText.replacingOccurrences(of: "http://", with: "", options: .literal, range: nil)
                                    
                                    self.saveToServer(user: username, text: shareText )

                            })
                        }
                    }
                }
            }
        } else {
            // if no logged in user, clean up
            self.cleanUp()
        }
    }
    
}
