//
//  ShareViewController.swift
//  URLExtension
//
//  Created by Brian Sutorius on 1/25/19.
//  Copyright © 2019 Brian Sutorius. All rights reserved.
//

import UIKit

class ShareViewController: UIViewController {

    let shareDefaults = UserDefaults(suiteName: "group.net.pastecard")
    private var workItem: DispatchWorkItem?
    
    // hide the dialog and kill the extension
    func cleanUp() {
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
        
        // set a five second timeout
        workItem = DispatchWorkItem { [weak self] in
            self?.cleanUp()
            self?.workItem = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem!)
        
        // attempt to write the text to the server
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                self.cleanUp()
                return
            }
            
            // on success, pause a little bit so the Saving message is actually readable
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                
                // cancel the timeout and clean up
                self.workItem = nil
                self.cleanUp()
            }
        }
        task.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get the logged-in user from the main app
        if let username = shareDefaults!.string(forKey: "username"), !username.isEmpty {
            
            // https://stackoverflow.com/a/39296032
            if let item = extensionContext?.inputItems.first as? NSExtensionItem {
                if let attachments = item.attachments {
                    for attachment: NSItemProvider in attachments {
                        if attachment.hasItemConformingToTypeIdentifier("public.url") {
                            attachment.loadItem(forTypeIdentifier: "public.url", options: nil, completionHandler: { (url, error) in
                                if let shareURL = url as? NSURL {
                                    var shareText: String = shareURL.absoluteString!
                                    shareText = shareText.replacingOccurrences(of: #"https?\:\/\/"#, with: "", options: .regularExpression) // remove protocols
                                    self.saveToServer(user: username, text: shareText )
                                }
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
