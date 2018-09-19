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

    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {
        if (vc.pasteCard.isEditable == true) {
            vc.pasteCard.text = vc.cancelText
            vc.cleanUp()
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        if (vc.defaults.string(forKey: "username") == nil) {
            vc.performSegue(withIdentifier: "showSignIn", sender: Any?.self)
        } else {
            DispatchQueue.main.async { self.vc.loadAction(notification: nil) }
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {}

    func applicationWillTerminate(_ application: UIApplication) {}

}
