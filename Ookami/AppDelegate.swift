//
//  AppDelegate.swift
//  Ookami
//
//  Copyright © 2016 Mikunj Varsani. All rights reserved.
//

import UIKit
import IQKeyboardManager

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FontAwesomeIcon.register()
        IQKeyboardManager.shared().isEnabled = true
        Theme.NavigationTheme().apply()
        
        window = UIWindow(frame: UIScreen.main.bounds);

        let nav = UINavigationController(rootViewController: ViewController())
        
        window?.rootViewController = nav;
        window?.makeKeyAndVisible();
        
        return true
    }

}

