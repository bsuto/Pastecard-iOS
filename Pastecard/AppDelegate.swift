//
//  AppDelegate.swift
//  Pastecard
//
//  Created by Brian Sutorius on 12/13/17.
//  Copyright © 2017 Brian Sutorius. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var vc = ViewController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {        
        if let firstViewController = self.window?.rootViewController as? ViewController {
            self.vc = firstViewController
        }
        
        return true
    }

    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // essentially, hit the Cancel button if you leave the app with the card open
        if (vc.pasteCard.isEditable == true) {
            vc.pasteCard.text = vc.cancelText
            vc.cleanUp()
        }
        
        // close the popover menu because swipe up for home might open it
        vc.popoverMenu.dismiss(animated: true, completion: nil)
    }

    // check for logged in user when opening
    func applicationWillEnterForeground(_ application: UIApplication) {
        if (vc.defaults?.string(forKey: "username") == nil) {
            vc.performSegue(withIdentifier: "showSignIn", sender: Any?.self)
        } else {
            DispatchQueue.main.async { self.vc.loadRemote() }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {}
    func applicationDidBecomeActive(_ application: UIApplication) {}
    func applicationWillTerminate(_ application: UIApplication) {}

}
