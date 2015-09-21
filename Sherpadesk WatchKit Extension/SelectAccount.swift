//
//  AddTime.swift
//  Sherpadesk
//
//  Created by Евгений on 18.08.15.
//
//

import WatchKit
import Foundation


class SelectAccountInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var timeTable: WKInterfaceTable!
    
    var defaults : NSUserDefaults = NSUserDefaults(suiteName: "group.io.sherpadesk.mobile")!
    
    struct Properties {
        static var org = ""
    }
    
    var accounts: NSMutableArray = []
    
    func loadTableData() {
        timeTable.setNumberOfRows(accounts.count, withRowType: "RecordTableRowController")
        for (index, account) in enumerate(accounts) {
            //print(blogName)
            let row = timeTable.rowControllerAtIndex(index) as! RecordTableRowController
            row.recordLabel.setText((account["name"] as! String))
            print(account["id"] as! Int)
        }
    }
    
    override init() {
        super.init()
        
        getOrg()
        //loadTableData()
        
        var showtickets: NSMutableArray = []
        //self.fTicket.setTitle("Looking for recent tickets ...", forState: UIControlState.Normal)
        let urlPath: String = "http://u0diuk-b95s6o:fzo3fkthioj5xi696jzocabuojekpb5o@api.beta.sherpadesk.com/tickets?status=open&role=user&limit=3&sort_by=updated"
        //print(urlPath)
        let url: NSURL = NSURL(string: urlPath)!
        let info: String = "http";
        //return;
        post(urlPath, info: info) {
            responseString, error in
            
            if responseString == nil {
                //self.updateResult = NCUpdateResult.Failed
                print("Error during post: \(error)")
                return
            }
            
            /*var output: NSString!
            
            if responseString != nil {
            output = NSString(data: responseString!, encoding: NSUTF8StringEncoding)
            }
            */
            
            showtickets = NSJSONSerialization.JSONObjectWithData(responseString, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSMutableArray
            
            print("sting during post: \(showtickets.count)")
        }
    }
    
    func post(url: String, info: String, completionHandler: (responseString: NSData!, error: NSError!) -> ()) {
        let URL: NSURL = NSURL(string: url)!
        let request:NSMutableURLRequest = NSMutableURLRequest(URL:URL)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        //let bodyData = info;
        //request.HTTPBody = bodyData.dataUsingEncoding(NSUTF8StringEncoding);
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue()){
            
            response, data, error in
            
            var output: NSString!
            
            if data != nil {
                output = NSString(data: data!, encoding: NSUTF8StringEncoding)
            }
            
            print(output)
            
            completionHandler(responseString: data, error: error)
        }
    }
    
    func getOrg(){
        if let org:String = defaults.objectForKey("org") as? String
        {
            print(org)
            Properties.org = org
        }
        else
        {
            Properties.org = ""
        }
        if !Properties.org.isEmpty{
            if let acct:NSData = defaults.objectForKey("accounts") as? NSData
            {
                if let accts = NSJSONSerialization.JSONObjectWithData(acct, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSMutableArray
                {
                if accts.count>0 {
                    if let org = accts[0]["org"] as? String
                    {
                        print("org\(org)prop\(Properties.org)")
                        if (org == Properties.org){
                            self.accounts = accts
                            print("set\(self.accounts.count)")
                            return
                        }
                    }
                }
             }
            }
        }
        self.accounts = []
        defaults.setObject([], forKey: "accounts")
        print("unset\(self.accounts.count)")
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