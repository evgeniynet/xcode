//
//  GlanceController.swift
//  sherpawatchapp Extension
//
//  Created by Евгений on 16.11.15.
//
//

import WatchKit
import Foundation


class GlanceController: WKInterfaceController {
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        updateUserActivity("com.sherpadesk.mobile.watch.glance",
            userInfo: ["controller": 1], webpageURL: nil)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
