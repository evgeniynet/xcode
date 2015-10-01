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
        for (index, account) in accounts.enumerate() {
            //print(blogName)
            let row = timeTable.rowControllerAtIndex(index) as! RecordTableRowController
            row.recordLabel.setText((account["name"] as! String))
            //print(account["id"] as! Int)
        }
    }
    
    override func contextForSegueWithIdentifier(segueIdentifier: String,
        inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
            let sequeId = "ToProject"
            let acc  = accounts as NSMutableArray
            if segueIdentifier == sequeId {
                let id = acc[rowIndex]["id"] as! Int
                return id
            }
            
            return nil
    }
    
    override init() {
        super.init()
        
        getOrg()
        loadTableData()
        
        var showtickets: NSMutableArray = []
        //self.fTicket.setTitle("Looking for recent tickets ...", forState: UIControlState.Normal)
        let urlPath: String = "http://u0diuk-b95s6o:fzo3fkthioj5xi696jzocabuojekpb5o@api.beta.sherpadesk.com/accounts"
        print(urlPath)
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
            
            do {
                showtickets = try NSJSONSerialization.JSONObjectWithData(responseString, options: NSJSONReadingOptions.MutableContainers) as! NSMutableArray
            } catch {
                // failure
                print("Fetch failed: \((error as NSError).localizedDescription)")
            }
            
            
            
            print("sting during post: \(showtickets.count)")
            self.accounts = showtickets
            self.loadTableData()
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
            
            /*var output: NSString!
            
            if data != nil {
                output = NSString(data: data!, encoding: NSUTF8StringEncoding)
            }
            
            print(output)
            */
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
                do {
                if let accts = try NSJSONSerialization.JSONObjectWithData(acct, options: NSJSONReadingOptions.MutableContainers) as? NSMutableArray
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
                catch {
                        // failure
                        print("Fetch failed: \((error as NSError).localizedDescription)")
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