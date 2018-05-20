//
//  MotionManager.swift
//  walking
//
//  Created by Jiameng Cen on 1/5/18.
//  Copyright © 2018 Jiameng Cen. All rights reserved.
//

import UIKit
import CoreMotion

class MotionManager{
    // MARK - Global & private properties
    
    let pedometer = CMPedometer()  //-- Static pedometer object to access all services
    let activityManager = CMMotionActivityManager()
    // MARK: Error Handling
    
    /** Convert CMMotionActivity Error into user msg.
     */
    func handleMotionError(error: NSError) -> String{
        var errMsg : String
        switch error.code {
        case Int(CMErrorMotionActivityNotAvailable.rawValue):
            errMsg = "Motion Coprocessor not installed on this device"
        case Int(CMErrorMotionActivityNotAuthorized.rawValue):
            errMsg = "Fitness & Motion Activity permision deined"
        default:
            errMsg = "Unexpected error code:\(error.code)"
        }
        
        return errMsg
}

    // MARK: Live Activity Updates
    
    /** This method should be used to start monitoring live peometer updates.
     */
    /*func startLivePedometerUpdates(completionHandler: (_ result: Int) -> Void) -> Bool {
     var updatesAvailable = true
     // If step counting is available, start pedometer updates from now going forward.
     if CMPedometer.isStepCountingAvailable() {
     let now = midnightOfToday
     pedometer.startUpdates(from:now) {
     pedometerData, error in
     // Here is the start of the completion handler
     if let pedometerData = pedometerData {
     completionHandler(result: pedometerData.numberOfSteps.integerValue)
     
     }
     else if let error = error {
     let errMsg = self.handleMotionError(error:)
     fatalError(errMsg)   //-- If all proper availability checking is done, we shouldn't never get here
     }
     }
     }
     else {
     updatesAvailable = false
     }
     
     return updatesAvailable
     }
     } */
    
}
