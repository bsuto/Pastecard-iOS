//
//  SignInController.swift
//  Pastecard
//
//  Created by Brian Sutorius on 12/15/17.
//  Copyright © 2017 Brian Sutorius. All rights reserved.
//

import Foundation
import SafariServices

class SignInController: UIViewController {
    
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var userField: UITextField!
    var username: String!
    
    @IBAction func loadSignUp(_ sender: UIButton) {
        let url = URL (string: "https://pastecard.net/signup/")
        let svc = SFSafariViewController(url: url!)
        svc.preferredControlTintColor = UIColor(red: 0.00, green: 0.25, blue: 0.50, alpha: 1.0)
        present(svc, animated: true, completion: nil)
    }
    
    func addUser() {
        if (userField.text == "") {
            let alert = UIAlertController(title: "😉", message: "Please enter your Pastecard username.", preferredStyle: UIAlertControllerStyle.alert)
            let okayAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (action) in self.userField.becomeFirstResponder() }
            alert.addAction(okayAction)
            self.present(alert, animated: true)
        } else if (Reachability.isConnectedToNetwork()) {
            userField.resignFirstResponder()
            let nameCheck = userField.text?.lowercased()
            let url = URL(string: "https://pastecard.net/api/check.php?user=" + (nameCheck?.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed))!)
            var request = URLRequest(url: url!)
            request.httpMethod = "GET"
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if error != nil {return}
                let responseString = String(data: data!, encoding: .utf8)
                if (responseString == "true") {
                    self.username = nameCheck
                    self.performSegue(withIdentifier: "unwindSegue", sender: Any?.self)
                } else {
                    let alert = UIAlertController(title: "😳", message: "The computer can’t find that username, sorry!", preferredStyle: UIAlertControllerStyle.alert)
                    let okayAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (action) in self.userField.becomeFirstResponder() }
                    alert.addAction(okayAction)
                    self.present(alert, animated: true)
                }
            }
            task.resume()
        } else {
            let alert = UIAlertController(title: "😉", message: "You must have a WiFi or cellular connection to sign in.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default))
            self.present(alert, animated: true)
        }
    }
    @IBAction func keyboardGoAction(_ sender: Any) {
        addUser()
    }
    
    @IBAction func goAction(_ sender: UIButton) {
        addUser()
    }
    
    override func viewDidLoad() {
        signUpButton.layer.borderWidth = 0.5
        signUpButton.layer.borderColor = UIColor(red: 0.00, green: 0.25, blue: 0.50, alpha: 1.0).cgColor
        goButton.layer.borderWidth = 0.5
        goButton.layer.borderColor = UIColor(red: 0.00, green: 0.25, blue: 0.50, alpha: 1.0).cgColor
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
}
