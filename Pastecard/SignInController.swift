//
//  SignInController.swift
//  Pastecard
//
//  Created by Brian Sutorius on 12/15/17.
//  Copyright © 2017 Brian Sutorius. All rights reserved.
//

import UIKit

class SignInController: UIViewController {
    
    // MARK: Variables, Outlets and Functions
    var username: String!
    var nameField: UITextField!
    let alertBox = UIAlertController(title: "Choose your Username", message: "Your Pastecard URL will be \n pastecard.net/(username)", preferredStyle: .alert)
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var userField: UITextField!
    @IBAction func keyboardGoAction(_ sender: Any) {
        addUser()
    }
    @IBAction func goAction(_ sender: UIButton) {
        addUser()
    }
    
    // when there's valid text in the sign up field
    @objc func textFieldDidChange(){
        if let t = nameField.text {
            let validUsername: Bool = t.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil && t != "" && t.count < 21
            
            // enable the submit button and update the helper text
            if (validUsername) {
                alertBox.actions[1].isEnabled = true
                alertBox.message = "Your Pastecard URL will be \n pastecard.net/\(t)"
            } else {
                alertBox.actions[1].isEnabled = false
                if t == "" {
                    alertBox.message = "Your Pastecard URL will be \n pastecard.net/(username)"
                } else if t.count > 20 {
                    alertBox.message = "Invalid username: \n 20 character maximum"
                } else {
                    alertBox.message = "Invalid username: \n Letters and numbers only"
                }
            }
        }
    }
    
    // enable the Go button if there's text in the username field
    @objc func userFieldDidChange(){
        if let t = userField.text {
            if (t == "") {
                goButton.isEnabled = false
            } else {
                goButton.isEnabled = true
            }
        }
    }
    
    // MARK: - Sign Up
    func createUser(name: String) {
            
        // assemble the API request to create user
        let url = URL(string: "https://pastecard.net/api/appsignup.php?user=" + (name.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed))!)
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {return}
            let responseString = String(data: data!, encoding: .utf8)
            
            // if it succeeds, set the username and go to the card
            if (responseString == "success") {
                self.username = name
                self.performSegue(withIdentifier: "unwindSegue", sender: Any?.self)
                
            // if the username is taken, alert
            } else if (responseString == "taken") {
                let alert = UIAlertController(title: "😬", message: "That username is not available.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { _ in self.signUp((Any).self) })
                self.present(alert, animated: true)
                
            // if a server error, alert
            } else {
                let alert = UIAlertController(title: "😳", message: "Oops, something didn't work. Please try again.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default))
                self.present(alert, animated: true)
            }
        }
        task.resume()
    }
    
    @IBAction func signUp(_ sender: Any) {
        
        // if an internet connection, show the sign up alert
        if (Reachability.isConnectedToNetwork()) {
            self.present(alertBox, animated: true)
        } else {
            let alert = UIAlertController(title: "😉", message: "You must have a WiFi or cellular connection to sign up.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default))
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - Sign In
    func addUser() {
        
        // check internet connection
        if (Reachability.isConnectedToNetwork()) {
            
            // assemble and send the API request to check if username exists
            userField.resignFirstResponder()
            let nameCheck = userField.text?.lowercased()
            let url = URL(string: "https://pastecard.net/api/appcheck.php?user=" + (nameCheck?.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed))!)
            var request = URLRequest(url: url!)
            request.httpMethod = "GET"
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if error != nil {return}
                let responseString = String(data: data!, encoding: .utf8)
                
                // if it does, set the username and go to the card
                if (responseString == "true") {
                    self.username = nameCheck
                    DispatchQueue.main.async {
                      self.performSegue(withIdentifier: "unwindSegue", sender: self)
                    }
                
                // otherwise, alert
                } else {
                    let alert = UIAlertController(title: "😳", message: "The computer can’t find that username, sorry!", preferredStyle: UIAlertController.Style.alert)
                    let okayAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (action) in self.userField.becomeFirstResponder() }
                    alert.addAction(okayAction)
                    self.present(alert, animated: true)
                }
            }
            task.resume()
        
        } else {
            let alert = UIAlertController(title: "😉", message: "You must have a WiFi or cellular connection to sign in.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default))
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - App Life Cycle
    
    override func viewDidLoad() {
        
        // assemble the sign up alert box
        alertBox.addTextField { (textField) -> Void in
            self.nameField = textField
            textField.addTarget(self, action: #selector(self.textFieldDidChange), for: UIControl.Event.editingChanged)
        }
        alertBox.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel))
        let submitAction = UIAlertAction(title: "Submit", style: .default) { _ in
            let name = self.nameField.text?.lowercased()
            self.createUser(name: name!)
            }
        alertBox.addAction(submitAction)
        submitAction.isEnabled = false
        
        // watch the username field for enabling the Go button
        userField.addTarget(self, action: #selector(self.userFieldDidChange), for: UIControl.Event.editingChanged)
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:))))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
}
