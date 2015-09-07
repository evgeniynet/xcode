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
    
    @IBOutlet weak var sTiket: UIButton!
    @IBOutlet weak var sLine: UIImageView!
    
    @IBOutlet weak var tTicket: UIButton!
    @IBOutlet weak var tLine: UIImageView!
    
    struct Properties {
        static var org = ""
    }
    
    var updateResult:NCUpdateResult = NCUpdateResult.NoData
    
    func updateWidget()
    {
        if !Properties.org.isEmpty
        {
        let urlPath: String = "http://" + Properties.org +
            //u0diuk-b95s6o:fzo3fkthioj5xi696jzocabuojekpb5o
        "@api.beta.sherpadesk.com/tickets?status=open&role=user&limit=1&sort_by=updated"
            //print(urlPath)
        let url: NSURL = NSURL(string: urlPath)!
        let info: String = "http";
        return;
        post(urlPath, info: info) {
            responseString, error in
            
            if responseString == nil {
                self.updateResult = NCUpdateResult.Failed
                print("Error during post: \(error)")
                return
            }
            
            //print("sting during post: \(responseString)")
            //let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(responseString, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary

            
            /*if jsonResult.count>0 && jsonResult["results"].count>0 {
                var results: NSArray = jsonResult["results"] as NSArray
                self.tableData = results
                self.appsTableView.reloadData()*/
            
         }
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
        print(page)
        OpenApp(page)
    }
    @IBAction func Ticket2(sender: AnyObject) {
        let page =  "index.html#ticket=evbcak"
        OpenApp(page)
    }
    @IBAction func Ticket3(sender: AnyObject) {
        let page =  "index.html#ticket=k3n0hk"
        let defaults = NSUserDefaults(suiteName: "group.io.sherpadesk.mobile")
        defaults?.setValue("", forKey: "org")
        //OpenApp(page)
    }
    
    func OpenApp(_page : String) {
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

    self.fTicket.setTitle("Login to SherpaDesk app first", forState: UIControlState.Normal)
    self.fTicket.setValue("index.html", forKeyPath: "page")
      let defaults = NSUserDefaults(suiteName: "group.io.sherpadesk.mobile")
      if let timeString:String = defaults?.objectForKey("org") as? String
      {
        if (!timeString.isEmpty){
        //print(timeString)t
         Properties.org = timeString
            self.fTicket.setTitle("#1330: sherpadesk Code: " + timeString, forState: UIControlState.Normal)
            self.fTicket.setValue( "index.html#ticket=zcmkjo", forKeyPath: "page" )
            self.fLine.hidden = false
            self.sTiket.hidden = false
            self.sLine.hidden = false
            self.tTicket.hidden=false
            self.tLine.hidden=false
        self.updateWidget()
        }
    }
    
    completionHandler(NCUpdateResult.NewData)
  }
    
    
    func post(url: String, info: String, completionHandler: (responseString: NSString!, error: NSError!) -> ()) {
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
            
            completionHandler(responseString: output, error: error)
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
