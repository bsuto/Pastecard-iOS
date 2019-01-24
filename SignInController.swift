//
//  SignInController.swift
//  Pastecard
//
//  Created by Brian Sutorius on 12/15/17.
//  Copyright © 2017 Brian Sutorius. All rights reserved.
//

import Foundation
import SafariServices

extension String {
    func isAlphanumeric() -> Bool {
        return self.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil && self != ""
    }
}

class SignInController: UIViewController {
    
    // MARK: Variables and Outlets
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var userField: UITextField!
    var username: String!
    
    // MARK: - Sign Up
    @IBAction func signUp(_ sender: UIButton) {
        
        // check internet connection
        if (Reachability.isConnectedToNetwork()) {
            
            // assemble the sign up alert box
            let ac = UIAlertController(title: "Choose your Username", message: "Your Pastecard URL will be pastecard.net/(username)", preferredStyle: .alert)
            ac.addTextField()
            let submitAction = UIAlertAction(title: "Sign Up", style: .default) { [unowned ac] _ in
                let nameField = ac.textFields![0]
                let name = nameField.text?.lowercased()
                
                // check alphanumeric
                if (name!.isAlphanumeric()) {
                    
                    // assemble and send the API request to create user
                    let url = URL(string: "https://pastecard.net/api/appsignup.php?user=" + (name?.addingPercentEncoding(withAllowedCharacters: .urlUserAllowed))!)
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
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default))
                            self.present(alert, animated: true)
                            
                        // if a server error, alert
                        } else {
                            let alert = UIAlertController(title: "😳", message: "Oops, something didn't work. Please go back and try again.", preferredStyle: UIAlertController.Style.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default))
                            self.present(alert, animated: true)
                        }
                    }
                    task.resume()
                    
                // if the username has unallowed characters, alert
                } else {
                    let alert = UIAlertController(title: "😬", message: "Usernames can only have letters and numbers.", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default))
                    self.present(alert, animated: true)
                }
            }
            
            // show the sign up alert box
            ac.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default))
            ac.addAction(submitAction)
            self.present(ac, animated: true)
        
        } else {
            let alert = UIAlertController(title: "😉", message: "You must have a WiFi or cellular connection to sign up.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default))
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - Sign In
    func addUser() {
        
        // check if username was entered at all
        if (userField.text == "") {
            let alert = UIAlertController(title: "😉", message: "Please enter your Pastecard username.", preferredStyle: UIAlertController.Style.alert)
            let okayAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (action) in self.userField.becomeFirstResponder() }
            alert.addAction(okayAction)
            self.present(alert, animated: true)
            
        // check internet connection
        } else if (Reachability.isConnectedToNetwork()) {
            
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
                    self.performSegue(withIdentifier: "unwindSegue", sender: Any?.self)
                
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
    
    // MARK: - Other & App Life Cycle
    @IBAction func keyboardGoAction(_ sender: Any) {
        addUser()
    }
    
    @IBAction func goAction(_ sender: UIButton) {
        addUser()
    }
    
    override func viewDidLoad() {
        
        // add borders to the buttons
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
