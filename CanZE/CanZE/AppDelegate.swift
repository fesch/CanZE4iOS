//
//  AppDelegate.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 17/12/20.
//

import Firebase
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        #if DEBUG
        #else
            FirebaseApp.configure()
        #endif

        #if DEBUG
            Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load()
            // for tvOS:
            //Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/tvOSInjection.bundle")?.load()
            // Or for macOS:
            //Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/macOSInjection.bundle")?.load()
        #endif

        return true
        
    }
}
