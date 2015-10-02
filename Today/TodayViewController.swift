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
import SwiftHTTP
import JSONJoy

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var fTicket: UIButton!
    @IBOutlet weak var fLine: UIImageView!
    
    @IBOutlet weak var sTicket: UIButton!
    @IBOutlet weak var sLine: UIImageView!
    
    @IBOutlet weak var tTicket: UIButton!
    @IBOutlet weak var tLine: UIImageView!
    
    /*struct Record : JSONJoy {
        var id: Int?
        var name: String?
        init() {
            
        }
        init(_ decoder: JSONDecoder) {
            id = decoder["id"].integer
            name = decoder["name"].string
        }
    }*/
    
    struct Record : JSONJoy {
        var number: String
        var subject: String
        var key: String
        var org: String
        //init() {
        //}
        
        init(_ decoder: JSONDecoder) {
            number = String(decoder["number"].integer!)
            subject = decoder["subject"].string!
            key = decoder["key"].string!
            org = ""
        }
        init(_ array: AnyObject) {
            number = (array["number"] as? String)!
            subject = (array["subject"] as? String)!
            key = (array["key"] as? String)!
            org = (array["org"] as? String)!
        }
    }
    
    struct Records : JSONJoy {
        var records: NSMutableArray = []
        init() {
        }
        init(_ decoder: JSONDecoder) {
            //we check if the array is valid then alloc our array and loop through it, creating the new address objects.
            if let recrds = decoder.array {
                records = []
                for rDecoder in recrds {
                    let rec = Record(rDecoder)
                    records.addObject([ "number" : rec.number, "subject" : rec.subject, "key" : rec.key, "org" : Properties.org])
                }
            }
        }
    }
    
    var defaults : NSUserDefaults = NSUserDefaults(suiteName: "group.io.sherpadesk.mobile")!
    
    struct Properties {
        static var org = ""
    }
    
    var tickets: NSMutableArray = []
    
    var updateResult:NCUpdateResult = NCUpdateResult.NoData
    
    func updateWidget()
    {
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
            showTickets(self.tickets)
            
            do {
                let command = "tickets" + "?status=open&role=user&limit=3&sort_by=updated"
                let params = ["", ""]
                let urlPath: String = "http://" + Properties.org +
                    "@api.beta.sherpadesk.com/" + command
                
                let opt = try HTTP.GET(urlPath, parameters: params, headers: ["Accept": "application/json"])
                opt.start { response in
                    if let err = response.error {
                        print("error: \(err.localizedDescription)")
                        return //also notify app of failure as needed
                    }
                    let resp = Records(JSONDecoder(response.data))
                    if resp.records.count > 0 {
                        self.tickets = resp.records
                        print("sting during post: \(self.tickets.count)")
                        self.defaults.setObject(self.tickets, forKey: "tickets")
                        self.showTickets(self.tickets)
                        completionHandler(NCUpdateResult.NewData)
                    }
                }
            } catch let error {
                print("got an error creating the request: \(error)")
            }
        }
        else {
            //completionHandler(NCUpdateResult.NoData)
        }
    }
    
    func getOrg(){
        if let org:String = defaults.objectForKey("org") as? String
        {
            Properties.org = org
        }
        else
        {
            Properties.org = ""
        }
        print(Properties.org)
        if !Properties.org.isEmpty{
            if let tkts:NSMutableArray = defaults.objectForKey("tickets") as? NSMutableArray
            {
                if tkts.count>0 {
                    if let org = tkts[0]["org"] as? String
                    {
                        print("org\(org)prop\(Properties.org)")
                        if (org == Properties.org){
                            self.tickets = tkts
                            print("set\(self.tickets.count)")
                            return
                        }
                    }
                }
            }
        }
        self.tickets = []
        defaults.setObject([], forKey: "tickets")
        print("unset\(self.tickets.count)")
    }
    
    func logout(){
        self.fTicket.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Center;
        self.fTicket.setTitle("Login to SherpaDesk app first", forState: UIControlState.Normal)
        self.fTicket.setValue("index.html", forKeyPath: "page")
    }
    
    func showTickets(jsonResult : NSMutableArray)
    {
        dispatch_async(dispatch_get_main_queue(), {
        print("show: \(jsonResult.count)")
        if jsonResult.count>0{
            var rec = Record(jsonResult[0])
            self.fTicket.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Fill;
            self.fTicket.setTitle("#\(rec.number): \(rec.subject)", forState: UIControlState.Normal)
            self.fTicket.setValue("index.html#ticket="+rec.key, forKeyPath: "page")
            self.fTicket.hidden = false
            self.fLine.hidden = false
            
            if jsonResult.count>1{
                rec = Record(jsonResult[1])
                self.sTicket.setTitle("#\(rec.number): \(rec.subject)", forState: UIControlState.Normal)
                self.sTicket.setValue("index.html#ticket="+rec.key, forKeyPath: "page")
                self.sTicket.hidden = false
                self.sLine.hidden = false
                
                if jsonResult.count>2{
                    rec = Record(jsonResult[2])
                    self.tTicket.setTitle("#\(rec.number): \(rec.subject)", forState: UIControlState.Normal)
                    self.tTicket.setValue("index.html#ticket="+rec.key, forKeyPath: "page")
                    self.tTicket.hidden = false
                    self.tLine.hidden = false
                }
            }
        }
        else if !Properties.org.isEmpty
        {
            self.fTicket.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Center;
            self.fTicket.setTitle("No recent tickets yet ...", forState: UIControlState.Normal)
            self.fLine.hidden = true
            self.sTicket.hidden = true
            self.sLine.hidden = true
            self.tTicket.hidden = true
            self.tLine.hidden = true
        }
            })
    }
    
    override func viewWillAppear(animated: Bool)
    {
        //var currentSize: CGSize = self.preferredContentSize
        //currentSize.height = 120.0
//        self.preferredContentSize = currentSize
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        //self.updateWidget()
    }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    //defaults.setObject([], forKey: "tickets")
    // Do any additional setup after loading the view from its nib.
    //print("widget view did load")
            preferredContentSize = CGSizeMake(CGFloat(0), CGFloat(205.0))
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
        //defaults.setObject([], forKey: "tickets")
        OpenApp(page)
    }
    @IBAction func Ticket3(sender: AnyObject) {
        let page = (sender as! UIButton).valueForKeyPath("page") as! String
        //let page =  "index.html#ticket=k3n0hk"
        //defaults.setValue("", forKey: "org")
        OpenApp(page)
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
    /*
    func getApiWithCommand(command: String, params: Dictionary<String, String> = [:])
    {
    do {
    let urlPath: String = "http://" + Properties.org +
    //u0diuk-b95s6o:fzo3fkthioj5xi696jzocabuojekpb5o
    "@api.beta.sherpadesk.com/" + command
    //tickets?status=open&role=user&limit=3&sort_by=updated"
    let opt = try HTTP.GET(urlPath, parameters: params, headers: ["Accept": "application/json"])
    opt.start { response in
    if let err = response.error {
    print("error: \(err.localizedDescription)")
    return //also notify app of failure as needed
    }
    var resp = Records(JSONDecoder(response.data))
    if resp.records != nil &&  resp.records!.count > 0 {
    resp.records?[0].org = Properties.org
    //print(resp.records!.count)
    }
    //print("opt finished: \(response.description)")
    //print("data is: \(response.data)") access the response of the data with response.data
    }
    } catch let error {
    print("got an error creating the request: \(error)")
    }
    }
    */
}
