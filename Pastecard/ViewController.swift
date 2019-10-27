//
//  ViewController.swift
//  Pastecard
//
//  Created by Brian Sutorius on 12/13/17.
//  Copyright © 2017 Brian Sutorius. All rights reserved.
//

import UIKit
import SafariServices

class ViewController: UIViewController, UITextViewDelegate, UIPopoverPresentationControllerDelegate {
    
    // MARK: Variables and Outlets
    let defaults = UserDefaults(suiteName: "group.net.pastecard")
    let file = "pastecard.txt"
    @IBOutlet weak var pasteCard: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    private var item: DispatchWorkItem?
    var tapCard = UITapGestureRecognizer(target: self, action: #selector(tapEdit))
    var swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipeMenu))
    var cancelText = ""
    var emergencyText = ""
    
    // MARK: - Save functions
    @IBAction func saveAction(_ sender: UIButton) {
        cleanUp()
        emergencyText = pasteCard.text
        pasteCard.text = "Saving…"
        
        // assemble the POST request
        let user = defaults!.string(forKey: "username")!
        let text = deSymbol(text: emergencyText)
        let postData = ("u=" + user + "&pc=" + text).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        guard let url = URL(string: "https://pastecard.net/api/write.php") else {return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postData?.data(using: String.Encoding.utf8)
        
        // set a five second timeout before going to save failure
        item = DispatchWorkItem { [weak self] in
            self?.saveFailure()
            self?.item = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: item!)
        
        // fire the POST request
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            // if an error, revert the card to what it was before
            if error != nil {
                self.item?.cancel()
                self.pasteCard.text = self.cancelText
                return
            }
            
            let responseData = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))?.removingPercentEncoding
            
            // pause a little bit so the Saving message is actually readable
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
                // save the text locally and put it in the card
                self.saveLocal(text: responseData!)
                self.pasteCard.text = responseData
                self.tapCard.isEnabled = true
                self.item?.cancel()
            }
        }
        task.resume()
    }
    
    func saveFailure() {
        let alert = UIAlertController(title: "😳", message: "Sorry, there was a problem saving your text.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: { _ in
            self.pasteCard.text = self.cancelText
        }))
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertAction.Style.default, handler: { _ in
            self.pasteCard.text = self.emergencyText
            self.makeEditable()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func saveLocal(text: String) {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(self.file)
            do {
                try text.write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {}
        }
    }
    
    // MARK: - Load functions
    @objc func loadAction(notification: Notification?) {
        if (Reachability.isConnectedToNetwork()) {
            loadRemote()
        } else {
            loadLocal()
        }
    }
    
    func loadRemote() {
        // assemble the GET request
        let path = "https://pastecard.net/api/db/"
        let user = defaults!.string(forKey: "username")
        let textExtension = ".txt"
        let url = URL(string: path + user! + textExtension)!
        
        // set a five second timeout before going to load failure
        item = DispatchWorkItem { [weak self] in
            self?.loadFailure()
            self?.item = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: item!)

        // fire the GET request
        let task = URLSession.shared.downloadTask(with:url) { localUrl, response, error in
            // if an error, go immediately to load failure
            if error != nil {
                self.item?.cancel()
                self.loadFailure()
                return
            }
            
            if let localUrl = localUrl {
                if let remoteText = try? String(contentsOf: localUrl, encoding: .utf8) {
                    // save the text locally and put it in the card
                    DispatchQueue.main.async() {
                        self.saveLocal(text: remoteText)
                        self.pasteCard.text = remoteText
                        self.item?.cancel()
                    }
                    self.tapCard.isEnabled = true // unlock the card in case it'd been locked before
                }
            }
        }
        task.resume()
    }
    
    func loadFailure() {
        let alert = UIAlertController(title: "😳", message: "Sorry, there was a problem loading your text.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: { _ in
            if self.pasteCard.text == "Loading…" {
                self.loadLocal()
                self.tapCard.isEnabled = false // lock the card, you're likely offline
            }
        }))
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertAction.Style.default, handler: { _ in
            self.loadAction(notification: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func loadLocal() {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(self.file)
            do {
                let localText = try String(contentsOf: fileURL, encoding: .utf8)
                pasteCard.text = localText
            } catch {}
        }
    }
    
    // MARK: - Other functions
    
    // the Done button above the keyboard
    func addDoneButton() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.barStyle = .default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonAction))
        let items = [flexSpace, done]
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        pasteCard.inputAccessoryView = doneToolbar
    }
    @objc func doneButtonAction() {
        pasteCard.resignFirstResponder()
    }
    
    // tap gesture
    @objc func tapEdit(_ sender: UITapGestureRecognizer) -> Void {
        if sender.state == .ended {
            // if the app is loading or saving, don't attempt to edit the card
            if (self.pasteCard.text == "Saving…" || self.pasteCard.text == "Loading…") {
                return
            }
            
            if (pasteCard.isEditable == false && Reachability.isConnectedToNetwork()) {
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
                makeEditable()
            }
        }
    }
    
    // swipe gesture
    @objc func swipeMenu(_ sender: UISwipeGestureRecognizer) -> Void {
        let popoverMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // assemble the menu
        let helpAction: UIAlertAction = UIAlertAction(title: "Help", style: .default) { action -> Void in
            let url = URL(string: "https://pastecard.net/help/")
            let svc = SFSafariViewController(url: url!)
            self.present(svc, animated: true, completion: nil)
        }
        let shareAction: UIAlertAction = UIAlertAction(title: "Share…", style: .default) { action -> Void in
            let text = [ self.pasteCard.text ]
            let avc = UIActivityViewController(activityItems: text as [Any], applicationActivities: nil)
            avc.popoverPresentationController?.sourceView = self.view
            avc.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY, width: 0, height: 0)
            avc.popoverPresentationController?.permittedArrowDirections = []
            self.present(avc, animated: true, completion: nil)
        }
        let refreshAction: UIAlertAction = UIAlertAction(title: "Refresh", style: .default) { action -> Void in
            if (Reachability.isConnectedToNetwork()) {
                self.loadRemote()
            } else {
                let alert = UIAlertController(title: "😉", message: "You must have a WiFi or cellular connection to refresh.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default))
                self.present(alert, animated: true)
            }
        }
        let signOutAction: UIAlertAction = UIAlertAction(title: "Sign Out", style: .destructive) { action -> Void in
            self.signOut()
        }
        let cancelAction: UIAlertAction = UIAlertAction(title: "OK", style: .cancel) { action -> Void in }
        
        popoverMenu.addAction(refreshAction)
        popoverMenu.addAction(shareAction)
        popoverMenu.addAction(helpAction)
        popoverMenu.addAction(signOutAction)
        popoverMenu.addAction(cancelAction)
        
        // turn action sheet into popover on iPad
        popoverMenu.popoverPresentationController?.sourceView = self.pasteCard
        popoverMenu.popoverPresentationController?.sourceRect = CGRect(x: self.pasteCard.bounds.midX, y: self.pasteCard.bounds.maxY, width: 0, height: -240)
        popoverMenu.popoverPresentationController?.permittedArrowDirections = []
        
        present(popoverMenu, animated: true)
    }
    
    func signOut() {
        // sign out user
        defaults!.setValue(nil, forKey: "username")
        defaults!.synchronize()
        
        // clear contents of local save file
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(self.file)
            do {
                let empty = ""
                try empty.write(to: fileURL, atomically: false, encoding: .utf8)
            }
            catch {}
        }
        
        // show sign in
        performSegue(withIdentifier: "showSignIn", sender: Any?.self)
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        pasteCard.text = cancelText
        cleanUp()
    }
    
    func cleanUp() {
        cancelButton.isHidden = true
        saveButton.isHidden = true
        pasteCard.isEditable = false
        pasteCard.inputAccessoryView = nil
        tapCard.isEnabled = true
        swipeUp.isEnabled = true
    }
    
    func deSymbol(text: String) -> String {
        var returnString = text
        returnString = returnString.replacingOccurrences(of: "http://", with: "")
        returnString = returnString.replacingOccurrences(of: "https://", with: "")
        returnString = returnString.replacingOccurrences(of: "+", with: "%2B")
        returnString = returnString.replacingOccurrences(of: "&", with: "%26")
        return returnString
    }
    
    func makeEditable() {
        cancelButton.isHidden = false
        saveButton.isHidden = false
        cancelText = pasteCard.text
        pasteCard.isEditable = true
        if UIDevice.current.userInterfaceIdiom == .phone {
            addDoneButton()
        }
        pasteCard.becomeFirstResponder()
        tapCard.isEnabled = false
        swipeUp.isEnabled = false
    }
    
    // limit the text view to 1034 characters
    func textView(_ pasteCard: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = pasteCard.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let changedText = currentText.replacingCharacters(in: stringRange, with: text)
        return changedText.count <= 1034
    }
    
    // scroll to the text cursor when the keyboard shows
    @objc func keyboardWillShow(notification: Notification) {
        let userInfo: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardInfo = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue
        let keyboardSize = keyboardInfo.cgRectValue.size
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        pasteCard.contentInset = contentInsets
        pasteCard.scrollIndicatorInsets = contentInsets
    }
    @objc func keyboardWillHide(notification: Notification) {
        pasteCard.contentInset = .zero
        pasteCard.scrollIndicatorInsets = .zero
    }

    // MARK: - App Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        pasteCard.delegate = self
        
        // start listening for gestures
        swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipeMenu))
        swipeUp.direction = .up
        self.pasteCard.addGestureRecognizer(swipeUp)
        tapCard = UITapGestureRecognizer(target: self, action: #selector(tapEdit))
        self.pasteCard.addGestureRecognizer(tapCard)
        
        // add border to the card
        pasteCard.layer.borderWidth = 0.5
        pasteCard.layer.borderColor = UIColor(red: 0.67, green: 0.67, blue: 0.67, alpha: 1.0).cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerNotifications()
        cleanUp()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (defaults?.string(forKey: "username") == nil) {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "showSignIn", sender: self)
            }
        } else {
            DispatchQueue.main.async { self.loadAction(notification: nil) }
        }
    }

    // coming back from Sign In
    @IBAction func unwindAction (_ sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? SignInController {
            defaults!.set(sourceViewController.username, forKey: "username")
            defaults!.synchronize()
            DispatchQueue.main.async { self.loadRemote() } // skip to remote because user has to be online
        }
    }
    
    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isBeingDismissed { NotificationCenter.default.removeObserver(self) }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
