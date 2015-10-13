//
//  InterfaceController.swift
//  Sherpadesk WatchKit Extension
//
//  Created by Евгений on 18.08.15.
//
//

import WatchKit
import Foundation
import SwiftHTTP
import JSONJoy


class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var timeTable: WKInterfaceTable!
    
    @IBOutlet weak var button: WKInterfaceButton!
    
    let swiftBlogs = ["Jameson\nbigWebApps", "Natasha \nbigWebApps", "Explorer\nbigWebApps", "Swift\nbigWebApps", "Andrew\nbigWebApps", "iAchieved\nbigWebApps", "Airspeed\nbigWebApps"]
    
    var swiftHours : [Float ] = [0.5, 2, 1, 7, 3.5, 4, 10.5]
    
    func loadTableData() {
        timeTable.setNumberOfRows(swiftBlogs.count, withRowType: "TextTableRowController")
        for (index, blogName) in swiftBlogs.enumerate() {
            //print(blogName)
            let row = timeTable.rowControllerAtIndex(index) as! TextTableRowController
            row.nameLabel.setText(blogName)
            row.hoursLabel.setText(String(format: "%2.2f", swiftHours[index]))
        }

    }
    
    override init() {
        super.init()
        
        loadTableData()
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let text = context as? String {
            let indexSet = NSMutableIndexSet()
            indexSet.addIndex(0)
            
            timeTable.insertRowsAtIndexes(indexSet,
                withRowType: "TextTableRowController")
            let row = timeTable.rowControllerAtIndex(0) as! TextTableRowController
            row.nameLabel.setText("Jon Vickers\nbigWebApps")
            row.hoursLabel.setText(text)
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
