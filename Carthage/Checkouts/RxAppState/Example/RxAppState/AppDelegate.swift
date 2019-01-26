//
//  AppDelegate.swift
//  RxAppState
//
//  Created by Jörn Schoppe on 03/06/2016.
//  Copyright (c) 2016 Jörn Schoppe. All rights reserved.
//

import UIKit
import RxSwift
import RxAppState

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    // Looking for all the UIApplicationDelegate methods?
    // With RxAppState you don't need them anymore.
    // Have a look at ViewController to see how you can
    // handle the changes in your app's state.
    
}
