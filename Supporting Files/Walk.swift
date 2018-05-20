//
//  Walk.swift
//  testmoon
//
//  Created by Jiameng Cen on 18/5/18.
//  Copyright © 2018 Jiameng Cen. All rights reserved.
//

import Foundation

protocol DocumentSerializable {
    init? (dictionary:[String:Any])
}
struct userWalk {
    var email:String
    var step: String
    var timeStamp: Date
    
    var dictionary:[String:Any]{
        return[
        "email":email,
        "step" : step,
        "timeStamp" : timeStamp
        ]
    }
}

extension userWalk : DocumentSerializable {
    init?(dictionary:[String : Any]){
        guard let email = dictionary["email"] as? String,
              let step = dictionary["step"] as? String,
            let timeStamp = dictionary["timeStamp"] as? Date else { return nil}
        self.init(email: email ,step: step, timeStamp: timeStamp)
        
    }
}
