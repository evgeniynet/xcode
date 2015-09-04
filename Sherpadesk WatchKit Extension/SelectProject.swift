//
//  AddTime.swift
//  Sherpadesk
//
//  Created by Евгений on 18.08.15.
//
//

import WatchKit
import Foundation


class SelectProjectInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var timeTable: WKInterfaceTable!
    
    let swiftBlogs = ["Test Project", "api.sherpadesk.com", "Create SEO Plan", "Finish Chargify Integration", "New Mobile App"]
    
    let swiftIds = [1, 2, 3, 4, 5, 6, 7]
    
    func loadTableData() {
        timeTable.setNumberOfRows(swiftBlogs.count, withRowType: "ProjectTableRowController")
        for (index, blogName) in enumerate(swiftBlogs) {
            //print(blogName)
            let row = timeTable.rowControllerAtIndex(index) as! ProjectTableRowController
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