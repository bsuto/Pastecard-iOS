//
//  ShareViewController.swift
//  PCShareExt
//
//  Created by Brian Sutorius on 4/18/23.
//

import SwiftUI

@objc(ShareViewController)
class ShareViewController: UIViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        self.modalPresentationStyle = .fullScreen
        
        showView()
        shareText()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func shareText() {
        let urlType = "public.url"
        let textType = "public.text"
        
        let extensionItem = extensionContext?.inputItems.first as! NSExtensionItem
        for attachment in extensionItem.attachments! {
            if attachment.hasItemConformingToTypeIdentifier(textType) {
                attachment.loadItem(forTypeIdentifier: textType, options: nil, completionHandler: { (data, error) in
                    if let sharedText = data as! String? {
                        self.append(sharedText)
                    }
                })
            } else if attachment.hasItemConformingToTypeIdentifier(urlType) {
                attachment.loadItem(forTypeIdentifier: urlType, options: nil, completionHandler: { (data, error) in
                    if let sharedURL = data as! URL? {
                        self.append(sharedURL.absoluteString)
                    }
                })
            }
        }
    }
    
    private func showView() {
        let controller = UIHostingController(rootView: SwiftUIView())
        addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        controller.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            controller.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1.0),
            controller.view.heightAnchor.constraint(equalToConstant: 96),
            controller.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func append(_ text: String) {
        let uid = UserDefaults(suiteName: "group.net.pastecard")!.string(forKey: "ID")
        let sendText = text.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        
        if uid == nil {
            self.hideView()
            return
        }
        else {
            let postData = ("user=" + uid! + "&text=" + sendText)
            let url = URL(string: "https://pastecard.net/api/ios-append.php")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = postData.data(using: String.Encoding.utf8)
            // request.timeoutInterval = 5.0
            
            let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                // pause a moment so the Saving message is readable
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                    self.hideView()
                }
            }
            task.resume()
        }
    }
    
    private func hideView() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
