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
    
    let defaults = UserDefaults.standard
    let file = "pastecard.txt"
    @IBOutlet weak var pasteCard: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    var tapCard = UITapGestureRecognizer(target: self, action: #selector(makeEditable))
    var swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipeMenu))
    let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    let haptic = UINotificationFeedbackGenerator()
    var cancelText = ""
    
    @IBAction func cancelAction(_ sender: UIButton) {
        pasteCard.text = cancelText
        cleanUp()
    }
    @IBAction func saveAction(_ sender: UIButton) {
        cleanUp()
        let user = defaults.string(forKey: "username")!
        let text = deSymbol(text: pasteCard.text)
        let postData = ("u=" + user + "&pc=" + text).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        
        guard let url = URL(string: "http://pastecard.net/api/write.php") else {return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postData?.data(using: String.Encoding.utf8);
        
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error != nil {return}
            var responseData = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
            responseData = responseData?.removingPercentEncoding
            self.saveLocal(text: responseData!)
            DispatchQueue.main.async { self.pasteCard.text = responseData }
        }
        task.resume()
    }
    
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
        var returnString = ""
        returnString = text.replacingOccurrences(of: "http://", with: "")
        returnString = returnString.replacingOccurrences(of: "https://", with: "")
        returnString = returnString.replacingOccurrences(of: "+", with: "%2B")
        returnString = returnString.replacingOccurrences(of: "&", with: "%26")
        return returnString
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
    
    @objc func makeEditable(_ sender: UITapGestureRecognizer) -> Void {
        if sender.state == .ended {
            if (pasteCard.isEditable == false && Reachability.isConnectedToNetwork()) {
                cancelButton.isHidden = false
                saveButton.isHidden = false
                cancelText = pasteCard.text
                pasteCard.isEditable = true
                addDoneButton()
                pasteCard.becomeFirstResponder()
                tapCard.isEnabled = false;
                swipeUp.isEnabled = false;
            } else {
                haptic.notificationOccurred(.error)
            }
        }
    }
    
    func loadText() {
        let path = "http://pastecard.net/api/db/"
        let user = defaults.string(forKey: "username")
        let textExtension = ".txt"
        let url = URL(string: path + user! + textExtension)
        var cardContents = ""
        do {
            cardContents = try String(contentsOf: url!)
            pasteCard.text = cardContents
        } catch _ as NSError {
            print("String error")
        }
    }
    @objc func foregroundLoad(notification: Notification) {
        if (Reachability.isConnectedToNetwork()) {
            loadText()
        } else {
            pasteCard.text = loadLocal()
        }
    }
    
    func textView(_ pasteCard: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = pasteCard.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let changedText = currentText.replacingCharacters(in: stringRange, with: text)
        return changedText.count <= 1134
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

    override func viewDidLoad() {
        super.viewDidLoad()
        pasteCard.delegate = self
        
        swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipeMenu))
        swipeUp.direction = .up
        self.pasteCard.addGestureRecognizer(swipeUp)
        tapCard = UITapGestureRecognizer(target: self, action: #selector(makeEditable))
        self.pasteCard.addGestureRecognizer(tapCard)
        
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
            if (Reachability.isConnectedToNetwork()) {
                loadText()
            } else {
                pasteCard.text = loadLocal()
            }
        } else {
            performSegue(withIdentifier: "showSignIn", sender: Any?.self)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
