//
//  TodayViewController.swift
//  todayClockWidget
//
//  Created by Christina Moulton on 2015-05-21.
//  Copyright (c) 2015 Teak Mobile Inc. All rights reserved.
//

class MyButton: UIButton {
    var page: String?
}

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var fTicket: UIButton!
    @IBOutlet weak var fLine: UIImageView!
    
    @IBOutlet weak var sTicket: UIButton!
    @IBOutlet weak var sLine: UIImageView!
    
    @IBOutlet weak var tTicket: UIButton!
    @IBOutlet weak var tLine: UIImageView!
    
    struct Properties {
        static var org = ""
    }
    
    var tickets: NSMutableArray = []
    
    var updateResult:NCUpdateResult = NCUpdateResult.NoData
    
    func updateWidget()
    {
        getOrg()

        if !Properties.org.isEmpty
        {
            showTickets(self.tickets)
            //self.fTicket.setTitle("Looking for recent tickets ...", forState: UIControlState.Normal)
        let urlPath: String = "http://" + Properties.org +
            //u0diuk-b95s6o:fzo3fkthioj5xi696jzocabuojekpb5o
        "@api.beta.sherpadesk.com/tickets?status=open&role=user&limit=3&sort_by=updated"
            //print(urlPath)
        let url: NSURL = NSURL(string: urlPath)!
        let info: String = "http";
        //return;
        post(urlPath, info: info) {
            responseString, error in
            
            if responseString == nil {
                self.updateResult = NCUpdateResult.Failed
                print("Error during post: \(error)")
                return
            }
            
            /*var output: NSString!
            
            if responseString != nil {
             output = NSString(data: responseString!, encoding: NSUTF8StringEncoding)
            }
            
            print("sting during post: \(output)")
            */
            self.tickets = NSJSONSerialization.JSONObjectWithData(responseString, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSMutableArray
            
            self.showTickets(self.tickets)
            
         }
        }
    }
    
    func showTickets(jsonResult : NSMutableArray)
    {
        if jsonResult.count>0{
            let defaults = NSUserDefaults(suiteName: "group.io.sherpadesk.mobile")
            self.tickets = []
            var number = jsonResult[0]["number"] as! Int,
            subject = jsonResult[0]["subject"] as! String,
            key = jsonResult[0]["key"] as! String
            self.fTicket.setTitle("#\(number): \(subject)", forState: UIControlState.Normal)
            self.fTicket.setValue( "index.html#ticket="+key, forKeyPath: "page" )
            self.fTicket.hidden = false
            self.fLine.hidden = false
            self.tickets.addObject([ "number" : number, "subject" : subject, "key" : key])
            
            if jsonResult.count>1{
                number = jsonResult[1]["number"] as! Int
                subject = jsonResult[1]["subject"] as! String
                key = jsonResult[1]["key"] as! String
                self.sTicket.setTitle("#\(number): \(subject)", forState: UIControlState.Normal)
                self.sTicket.setValue( "index.html#ticket="+key, forKeyPath: "page" )
                self.sTicket.hidden = false
                self.sLine.hidden = false
                
                self.tickets.addObject([ "number" : number, "subject" : subject, "key" : key])
                
                if jsonResult.count>2{
                    number = jsonResult[2]["number"] as! Int
                    subject = jsonResult[2]["subject"] as! String
                    key = jsonResult[2]["key"] as! String
                    self.tTicket.setTitle("#\(number): \(subject)", forState: UIControlState.Normal)
                    self.tTicket.setValue( "index.html#ticket="+key, forKeyPath: "page" )
                    self.tTicket.hidden = false
                    self.tLine.hidden = false
                    self.tickets.addObject([ "number" : number, "subject" : subject, "key" : key])
                }
            }
            
            defaults?.setObject(self.tickets, forKey: "tickets")
        }
        else
        {
            self.fTicket.setTitle("No recent tickets yet", forState: UIControlState.Normal)
        }

    }
    
    override func viewWillAppear(animated: Bool)
    {
        var currentSize: CGSize = self.preferredContentSize
        currentSize.height = 220.0
//        self.preferredContentSize = currentSize
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        //self.updateWidget()
    }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view from its nib.
    //print("widget view did load")
  }
  
    @IBAction func OpenUrl(sender: AnyObject) {
        let page =  "add_time.html"
        OpenApp(page)
    }
    
    @IBAction func AddTicket(sender: AnyObject) {
        let page =  "add_tickets.html"
        OpenApp(page)
    }
    
    @IBAction func MyTickets(sender: AnyObject) {
        let page =  "ticket_list.html#tab=my"
        OpenApp(page)
    }
    
    @IBAction func AllTickets(sender: AnyObject) {
        let page =  "ticket_list.html#tab=all"
        OpenApp(page)
    }
    @IBAction func Ticket1(sender: AnyObject) {
        let page = (sender as! UIButton).valueForKeyPath("page") as! String
        //let page =  "index.html#ticket=zcmkjo"
        OpenApp(page)
    }
    @IBAction func Ticket2(sender: AnyObject) {
                let page = (sender as! UIButton).valueForKeyPath("page") as! String
        //let page =  "index.html#ticket=evbcak"
        let defaults = NSUserDefaults(suiteName: "group.io.sherpadesk.mobile")
        defaults?.setObject([], forKey: "tickets")
        //OpenApp(page)
    }
    @IBAction func Ticket3(sender: AnyObject) {
                let page = (sender as! UIButton).valueForKeyPath("page") as! String
        //let page =  "index.html#ticket=k3n0hk"
        let defaults = NSUserDefaults(suiteName: "group.io.sherpadesk.mobile")
        defaults?.setValue("", forKey: "org")
        //OpenApp(page)
    }
    
    func OpenApp(_page : String) {
        print(_page)
        let sherpaHooks = "sherpadesk://"
        let url = NSURL(string: sherpaHooks + _page);
        extensionContext!.openURL(url!, completionHandler: nil)
    }

    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        let newInsets = UIEdgeInsets(top: defaultMarginInsets.top, left: defaultMarginInsets.left-30,
            bottom: defaultMarginInsets.bottom, right: defaultMarginInsets.right)
        return newInsets
    }

    override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
    //print("widgetPerformUpdateWithCompletionHandler")
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResult.Failed
    // If there's no update required, use NCUpdateResult.NoData
    // If there's an update, use NCUpdateResult.NewData
    getOrg()
    if !Properties.org.isEmpty
    {
        self.updateWidget()
    }
    
    completionHandler(NCUpdateResult.NewData)
  }
    
    func getOrg(){
        let defaults = NSUserDefaults(suiteName: "group.io.sherpadesk.mobile")
        if let org:String = defaults?.objectForKey("org") as? String
        {
                Properties.org = org
        }
        
        if let tkts:NSMutableArray = defaults?.objectForKey("tickets") as? NSMutableArray
        {
            tickets = tkts
        }
        
    }
    
    func logout(){
        self.fTicket.setTitle("Login to SherpaDesk app first", forState: UIControlState.Normal)
        self.fTicket.setValue("index.html", forKeyPath: "page")
    }
    
    
    func post(url: String, info: String, completionHandler: (responseString: NSData!, error: NSError!) -> ()) {
        let URL: NSURL = NSURL(string: url)!
        let request:NSMutableURLRequest = NSMutableURLRequest(URL:URL)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        //let bodyData = info;
        //request.HTTPBody = bodyData.dataUsingEncoding(NSUTF8StringEncoding);
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue()){
            
            response, data, error in
            
            //var output: NSString!
            
            //if data != nil {
            //    output = NSString(data: data!, encoding: NSUTF8StringEncoding)
            //}
            
            completionHandler(responseString: data, error: error)
        }
    }

    
    /*
    private func decodeResponseData(data: NSData) -> [Coin] {
    var coinData = [Coin]()
    
    var JSONError: NSError?
    let responseArray: NSArray = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments, error: &JSONError) as! NSArray
    if JSONError == nil {
    
    for coinDict in responseArray {
    if let coinDict = coinDict as? NSDictionary {
    if let key = coinDict["id"] as? String {
    if (key as NSString).hasSuffix("/usd") {
    let currency = key.stringByReplacingOccurrencesOfString("/usd", withString: "", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil).uppercaseString
    coinData.append(Coin(name: currency, price: (coinDict["price"] as! NSString).doubleValue, price24h: (coinDict["price_before_24h"] as! NSString).doubleValue, volume: (coinDict["volume_first"] as! NSString).doubleValue))
    }
    }
    }
    }
    
    coinData.sort({ (a, b) -> Bool in
    a.name < b.name
    })
    
    }
    return coinData
    }
    */

  
}
