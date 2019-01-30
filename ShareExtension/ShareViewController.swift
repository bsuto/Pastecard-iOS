//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Brian Sutorius on 1/25/19.
//  Copyright © 2019 Brian Sutorius. All rights reserved.
//

import UIKit
import MobileCoreServices

class ShareViewController: UIViewController {

    let shareDefaults = UserDefaults(suiteName: "group.net.pastecard")
    
    @objc func errorFxn() {
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
        let timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.errorFxn), userInfo: nil, repeats: false)
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                self.errorFxn()
                return
            }
            
            // on success, pause a little bit so the Saving message is actually readable
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                // hide the dialog and cancel the timer
                self.view.viewWithTag(1)?.isHidden = true
                timer.invalidate()
                self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
            }
        }
        task.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // draw a border on the dialog
        self.view.viewWithTag(1)?.layer.borderWidth = 2.0
        self.view.viewWithTag(1)?.layer.borderColor = UIColor(red: 0.00, green: 0.25, blue: 0.50, alpha: 1.0).cgColor
        
        // get the logged-in user from the main app
        let username = shareDefaults!.string(forKey: "username")
        
        let extensionItem = extensionContext?.inputItems.first as! NSExtensionItem
        let itemProvider = extensionItem.attachments?.first as! NSItemProvider
        let propertyList = String(kUTTypePropertyList)
        if itemProvider.hasItemConformingToTypeIdentifier(propertyList) {
            itemProvider.loadItem(forTypeIdentifier: propertyList, options: nil, completionHandler: { (item, error) -> Void in
                guard let dictionary = item as? NSDictionary else { return }
                OperationQueue.main.addOperation {
                    if let results = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary {
                        let saveText = results["text"] as? String
                        self.saveToServer(user: username!, text: saveText ?? "")
                    }
                }
            })
        } else {
            print("error")
        }
    }
}
