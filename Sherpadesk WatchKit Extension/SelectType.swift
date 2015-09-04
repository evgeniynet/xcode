//
//  AddTime.swift
//  Sherpadesk
//
//  Created by Евгений on 18.08.15.
//
//

import WatchKit
import Foundation


class SelectTypeInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var timeTable: WKInterfaceTable!
    
    let swiftBlogs = ["Development", "Support", "Training", "UI Design", "Vacation"]
    
    let swiftIds = [1, 2, 3, 4, 5, 6, 7]
    
    func loadTableData() {
        timeTable.setNumberOfRows(swiftBlogs.count, withRowType: "TypeTableRowController")
        for (index, blogName) in enumerate(swiftBlogs) {
            //print(blogName)
            let row = timeTable.rowControllerAtIndex(index) as! TypeTableRowController
            row.recordLabel.setText(blogName)
            print(swiftIds[index])
        }
    }
    
    override init() {
        super.init()
        
        loadTableData()
    }
    
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
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