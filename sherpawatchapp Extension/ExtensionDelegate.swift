//
//  ExtensionDelegate.swift
//  sherpawatchapp Extension
//
//  Created by Евгений on 05.11.15.
//
//

import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    var session : WCSession?
    var defaults : UserDefaults = UserDefaults(suiteName: "group.io.sherpadesk.mobile")!
    
    func handleUserActivity(_ userInfo: [AnyHashable: Any]?) {
        
        let controllerIndex = userInfo!["controller"] as! Int
        
        let rootController =
        WKExtension.shared().rootInterfaceController
            as! InterfaceController
        rootController.popToRootController()
        
        rootController.displayDetailScene(controllerIndex)
    }
    

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
    }

    func applicationDidBecomeActive() {
        session = WCSession.default
        session?.activate()
        if let iPhoneContext = session?.receivedApplicationContext as? [String : Any] {
            let message = iPhoneContext["message"] as? String
            //let old = defaults.object(forKey: "org") as? String
            defaults.set(message, forKey: "org")
        }
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }
}
