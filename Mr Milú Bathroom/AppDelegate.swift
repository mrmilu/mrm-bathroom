//
//  AppDelegate.swift
//  Mr Milú Bathroom
//
//  Created by Daniel Seijo Sánchez on 27/11/16.
//  Copyright © 2016 Daniel Seijo Sánchez. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    
    var statusBarItem: NSStatusItem?
    
    var occupied: Bool?
    
    // In case we want some API security
    let ROOT_KEY = "79edc86c9b2930aecdfcf395ffb695a0"
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Launch on startup
        let onStartup = PALoginItemUtility.isCurrentApplicatonInLoginItems()
        
        if !onStartup {
            PALoginItemUtility.addCurrentApplicatonToLoginItems()
        }
        
        // Status Bar Item menu
        statusBarItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit Bathroom", action: #selector(quit), keyEquivalent: "q"))
        self.statusBarItem?.menu = menu
        
        // Begin loop
        self.isOccupied()
    }
    
    // Quit app func
    func quit() {
        NSApp.terminate(self)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    //MARK: App main logic. Loop.
    
    // Setter with final loop
    func setOccupied (occupied: Bool) {
        self.occupied = occupied
        if (self.occupied)! {
            self.statusBarItem?.image = #imageLiteral(resourceName: "locked")
        } else {
            self.statusBarItem?.image = #imageLiteral(resourceName: "unlocked")
        }
        
        // Delay 2 seconds
        delay(2, closure: {
            self.isOccupied()
        })
    }
    
    // Deserialize JSON response async
    func isOccupied () {
        fetchOccupied { (data, response, error) in
            if error != nil {
                return
            }
            
            do {
                let jsonObject = try(JSONSerialization.jsonObject(with: data!, options: .mutableContainers))
                
                let json = jsonObject as! NSDictionary
                
                let occupiedJSON = json["name"] as! String
                
                var occupied = false
                
                if occupiedJSON == "true" {
                    occupied = true
                }
                
                DispatchQueue.main.async(execute: {
                    self.setOccupied(occupied: occupied)
                })
                
            } catch let err {
                print(err)
            }
        }
        
    }
    
    // GET from url
    func fetchOccupied (completionHandler: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> ()) {
        
        let URL = "https://point-app-rest-api.herokuapp.com/api/place/57c59c8c9b79fa0300e73ca3"
        let request = NSMutableURLRequest(url: Foundation.URL(string: URL)!)
        
        request.addValue(ROOT_KEY, forHTTPHeaderField: "rootAuth")
        
        URLSession.shared.dataTask(with: request as URLRequest, completionHandler: { (data,response,error) in
            completionHandler(data, response, error)
        }).resume()
    }
    
    //MARK: Delay func
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
}
