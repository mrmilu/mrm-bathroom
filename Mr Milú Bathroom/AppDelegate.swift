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
    
    var receiveNoti: Bool = true
    
    var occupied: Bool = false
    
    let URL = "http://192.168.1.123:5001/api/bathroom_updates/1"
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
        self.statusBarItem?.image = #imageLiteral(resourceName: "empty")
        
        let menu = NSMenu()
        
        let notifItem = NSMenuItem(title: "Receive notifications", action: #selector(checkNotifications), keyEquivalent: "n")
        
        let receiveInt = UserDefaults.standard.integer(forKey: "receiveNoti")
        
        receiveNoti = (receiveInt == 0 || receiveInt == 2)
        
        if (receiveNoti) {
            notifItem.state = NSOnState
        } else {
            notifItem.state = NSOffState
        }
        
        menu.addItem(notifItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Bathroom", action: #selector(quit), keyEquivalent: "q"))
        self.statusBarItem?.menu = menu
        
        // Begin loop
        self.isOccupied()
    }
    
    func checkNotifications (sender: NSMenuItem) {
        receiveNoti = !receiveNoti
        if (receiveNoti) {
            sender.state = NSOnState
        } else {
            sender.state = NSOffState
        }
        
        UserDefaults.standard.set(receiveNoti ? 2 : 1, forKey: "receiveNoti")
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
        if (self.occupied != occupied) {
            self.occupied = occupied
            if (self.occupied) {
                self.statusBarItem?.image = #imageLiteral(resourceName: "busy")
            } else {
                self.statusBarItem?.image = #imageLiteral(resourceName: "empty")
            }
            if (self.receiveNoti) {
                showNotification(self.occupied)
            }
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
                self.setOccupied(occupied: false)
                return
            }
            
            do {
                let jsonObject = try(JSONSerialization.jsonObject(with: data!, options: .mutableContainers))
                
                let json = jsonObject as? NSDictionary
                
                var occupied = false
                occupied = json?["occupied"] as? Bool ?? false
                
                DispatchQueue.main.async(execute: {
                    self.setOccupied(occupied: occupied)
                    return
                })
                
            } catch let err {
                print(err)
                self.setOccupied(occupied: false)
            }
        }
        
    }
    
    func showNotification (_ occupied: Bool) {
        let notification = NSUserNotification()
        notification.title = "Mr. Milú Bathroom"
        if (occupied) {
            notification.informativeText = "The bathroom is occupied."
        } else {
            notification.informativeText = "The bathroom is free again."
        }
        //notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    // GET from url
    func fetchOccupied (completionHandler: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> ()) {
        
        let request = NSMutableURLRequest(url: Foundation.URL(string: URL)!)
        
        //request.addValue(ROOT_KEY, forHTTPHeaderField: "rootAuth")
        
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
