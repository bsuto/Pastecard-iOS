//
//  ViewController.swift
//  Pastecard
//
//  Created by Brian Sutorius on 12/13/17.
//  Copyright © 2017 Brian Sutorius. All rights reserved.
//

import UIKit
import SafariServices

class ViewController: UIViewController, UITextViewDelegate {
    
    // MARK: Variables and Outlets
    let defaults = UserDefaults.standard
    let file = "pastecard.txt"
    @IBOutlet weak var pasteCard: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    var tapCard = UITapGestureRecognizer(target: self, action: #selector(tapEdit))
    var swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipeMenu))
    let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    let haptic = UINotificationFeedbackGenerator()
    var cancelText = ""
    var emergencyText = ""
    
    @IBAction func cancelAction(_ sender: UIButton) {
        pasteCard.text = cancelText
        cleanUp()
    }
    
    // MARK: -
    // MARK: Save functions
    @IBAction func saveAction(_ sender: UIButton) {
        cleanUp()
        cancelText = pasteCard.text
        
        // show progress message and lock the card
        pasteCard.text = "Saving…"
        tapCard.isEnabled = false;
        
        // assemble the POST request
        let user = defaults.string(forKey: "username")!
        let text = deSymbol(text: cancelText)
        let postData = ("u=" + user + "&pc=" + text).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        guard let url = URL(string: "http://pastecard.net/api/write.php") else {return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postData?.data(using: String.Encoding.utf8);
        
        // set a five second timeout and attempt to write the text to the server
        let timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.saveFailure), userInfo: nil, repeats: false)
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {
                self.pasteCard.text = self.cancelText
                return
            }
            
            // on success, save the returned string locally, update the card, and cancel the timeout
            var responseData = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
            responseData = responseData?.removingPercentEncoding
            self.saveLocal(text: responseData!)
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250)) {
                self.pasteCard.text = responseData
                self.tapCard.isEnabled = true;
                timer.invalidate()
            }
        }
        task.resume()
    }
    
    @objc func saveFailure() {
        let alert = UIAlertController(title: "😳", message: "Sorry, there was a problem saving your text.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { _ in
            self.pasteCard.text = self.cancelText
        }))
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.default, handler: { _ in
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
    
    // MARK: -
    // MARK: Load functions
    func loadText() {
        // assemble the GET request
        let path = "http://pastecard.net/api/db/"
        let user = defaults.string(forKey: "username")
        let textExtension = ".txt"
        let url = URL(string: path + user! + textExtension)
        
        // set a five second timeout and attempt to get the text from the server
        let timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.loadFailure), userInfo: nil, repeats: false)
        do {
            let cardContents = try String(contentsOf: url!)
            pasteCard.text = cardContents
            saveLocal(text: cardContents) // save it locally too
            timer.invalidate()
        } catch {}
    }
    
    // most common load function, lock the card while trying
    @objc func foregroundLoad(notification: Notification?) {
        tapCard.isEnabled = false;
        if (Reachability.isConnectedToNetwork()) {
            loadText()
        } else {
            pasteCard.text = loadLocal()
        }
        tapCard.isEnabled = true;
    }
    
    @objc func loadFailure() {
        let alert = UIAlertController(title: "😳", message: "Sorry, there was a problem loading your text.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { _ in
            self.pasteCard.text = self.loadLocal()
        }))
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.default, handler: { _ in
            self.loadText()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func loadLocal() -> String {
        var returnText = ""
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(self.file)
            do {
                returnText = try String(contentsOf: fileURL, encoding: .utf8)
            }
            catch {}
        }
        return returnText
    }
    
    // MARK: -
    // MARK: Other functions
    
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
    
    // functions for gestures
    @objc func tapEdit(_ sender: UITapGestureRecognizer) -> Void {
        if sender.state == .ended {
            if (pasteCard.isEditable == false && Reachability.isConnectedToNetwork()) {
                makeEditable()
            } else {
                haptic.notificationOccurred(.error)
            }
        }
    }
    @objc func swipeMenu(_ sender: UISwipeGestureRecognizer) -> Void {
        present(actionSheetController, animated: true, completion: nil)
    }
    
    func signOut() {
        defaults.setValue(nil, forKey: "username")
        defaults.synchronize()
        performSegue(withIdentifier: "showSignIn", sender: Any?.self)
    }
    
    func cleanUp() {
        cancelButton.isHidden = true
        saveButton.isHidden = true
        pasteCard.isEditable = false
        pasteCard.inputAccessoryView = nil
        tapCard.isEnabled = true;
        swipeUp.isEnabled = true;
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
        addDoneButton()
        pasteCard.becomeFirstResponder()
        tapCard.isEnabled = false;
        swipeUp.isEnabled = false;
    }
    
    // limit the text view to 1034 characters
    func textView(_ pasteCard: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = pasteCard.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let changedText = currentText.replacingCharacters(in: stringRange, with: text)
        return changedText.count <= 1034
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        let userInfo: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardInfo = userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue
        let keyboardSize = keyboardInfo.cgRectValue.size
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        pasteCard.contentInset = contentInsets
        pasteCard.scrollIndicatorInsets = contentInsets
    }
    @objc func keyboardWillHide(notification: Notification) {
        pasteCard.contentInset = .zero
        pasteCard.scrollIndicatorInsets = .zero
    }

    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        pasteCard.delegate = self
        
        // start listening for gestures
        swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipeMenu))
        swipeUp.direction = .up
        self.pasteCard.addGestureRecognizer(swipeUp)
        tapCard = UITapGestureRecognizer(target: self, action: #selector(tapEdit))
        self.pasteCard.addGestureRecognizer(tapCard)
        
        // assemble the swipe menu
        let helpAction: UIAlertAction = UIAlertAction(title: "Help", style: .default) { action -> Void in
            let url = URL (string: "http://pastecard.net/help/")
            let svc = SFSafariViewController(url: url!)
            svc.preferredControlTintColor = UIColor(red: 0.00, green: 0.25, blue: 0.50, alpha: 1.0)
            self.present(svc, animated: true, completion: nil)
        }
        let refreshAction: UIAlertAction = UIAlertAction(title: "Refresh", style: .default) { action -> Void in
            if (Reachability.isConnectedToNetwork()) {
                self.loadText()
            } else {
                self.haptic.notificationOccurred(.error)
            }
        }
        let signOutAction: UIAlertAction = UIAlertAction(title: "Sign Out", style: .destructive) { action -> Void in
            self.signOut()
        }
        let cancelAction: UIAlertAction = UIAlertAction(title: "OK", style: .cancel) { action -> Void in }
        actionSheetController.addAction(refreshAction)
        actionSheetController.addAction(helpAction)
        actionSheetController.addAction(signOutAction)
        actionSheetController.addAction(cancelAction)
        
        // add borders to the card and buttons
        pasteCard.layer.borderWidth = 0.5
        pasteCard.layer.borderColor = UIColor(red: 0.67, green: 0.67, blue: 0.67, alpha: 1.0).cgColor
        cancelButton.layer.borderWidth = 0.5
        cancelButton.layer.borderColor = UIColor(red: 0.00, green: 0.25, blue: 0.50, alpha: 1.0).cgColor
        saveButton.layer.borderWidth = 0.5
        saveButton.layer.borderColor = UIColor(red: 0.00, green: 0.25, blue: 0.50, alpha: 1.0).cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerNotifications()
        cleanUp()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if (defaults.string(forKey: "username") != nil) {
            foregroundLoad(notification: nil)
        } else {
            performSegue(withIdentifier: "showSignIn", sender: Any?.self)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func unwindAction (_ sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? SignInController {
            defaults.set(sourceViewController.username, forKey: "username")
            defaults.synchronize()
            DispatchQueue.main.async { self.loadText() }
        }
    }
    
    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(foregroundLoad(notification:)), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}
