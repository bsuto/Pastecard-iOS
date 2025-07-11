//
//  ShareViewController.swift
//  PCShareExt
//
//  Created by Brian Sutorius on 4/18/23.
//

import SwiftUI
import PastecardCore

@objc(ShareViewController)
class ShareViewController: UIViewController {
    private let core = PastecardCore.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        self.modalPresentationStyle = .fullScreen
        
        if core.isSignedIn {
            showView()
            shareText()
        } else {
            extensionContext?.cancelRequest(withError: NSError())
        }
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
                        Task {
                            do { try await self.core.append(sharedText) }
                            catch { return }
                        }
                    }
                })
            } else if attachment.hasItemConformingToTypeIdentifier(urlType) {
                attachment.loadItem(forTypeIdentifier: urlType, options: nil, completionHandler: { (data, error) in
                    if let sharedURL = data as! URL? {
                        Task {
                            do { try await self.core.append(sharedURL.absoluteString) }
                            catch { return }
                        }
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
        
        // pause a moment so the Saving message is readable
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(750)) {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}
