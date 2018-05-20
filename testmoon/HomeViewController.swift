//
//  HomeViewController.swift
//  testmoon
//
//  Created by Jiameng Cen on 14/4/18.
//  Copyright © 2018 Jiameng Cen. All rights reserved.
//

import UIKit
import UserNotifications

class HomeViewController: UIViewController {
    
    @IBOutlet weak var notifyPressed: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]){ (success, error) in
            
            if error != nil{
                print("Authenticated Unsuceesfully")
            } else {
                print("Hi! 1600 steps for this week but today you just need to walk 200 steps! Cheers")
            }
            
        }
        
    }
    
    @IBAction func notifyPressed(_ sender: Any) {
        timedNotifications(inSeconds: 5) {  (success) in
            if success{
                print("Sucessfully notified")
            }
        }
    }
    
    func timedNotifications(inSeconds: TimeInterval, completion:@escaping(_ Success: Bool) -> ()) {
        //let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: inSeconds, repeats: false)
        let content = UNMutableNotificationContent()
        
        content.title = "Updating Steps"
        content.subtitle = "Let's Walking ! guys!"
        content.body = "Hi! 1600 steps for this week but today you just need to walk 200 steps! Cheers"
        let request = UNNotificationRequest(identifier :"customnotification", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request){ (error) in
            if error != nil{
                completion(false)
            }else{
                completion(true)
            }
        }
    }
    
}
