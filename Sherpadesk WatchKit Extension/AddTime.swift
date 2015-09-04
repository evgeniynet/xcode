//
//  AddTime.swift
//  Sherpadesk
//
//  Created by Евгений on 18.08.15.
//
//

import WatchKit
import Foundation


class AddTimeInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var label: WKInterfaceButton!
    
    @IBOutlet weak var slider: WKInterfaceSlider!
    
    var val : String = ""
    
    @IBAction func sliderDidChange(value: Float)
    {
        val = String(format: "%2.2f", value)
        label.setTitle(val);
    }
    
    @IBAction func popButtonPressed() {
        //self.popToRootController()
        self.pushControllerWithName("Main1", context: val)
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