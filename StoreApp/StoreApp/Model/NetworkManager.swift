//
//  NetworkManager.swift
//  StoreApp
//
//  Created by YOUTH2 on 2018. 8. 3..
//  Copyright © 2018년 JINiOS. All rights reserved.
//

import Foundation
import Alamofire

class NetworkManager {

    //shared instance
    static let shared = NetworkManager()
    var reachable: Bool = true

    var isReachable: Bool {
        guard let reachabilityManager = reachabilityManager else { return false }
        return reachabilityManager.isReachable
    }

    let reachabilityManager = NetworkReachabilityManager()

    func startNetworkReachabilityObserver() {
        reachabilityManager?.listener = { status in
            NotificationCenter.default.post(name: .reachabilityChanged, object: self, userInfo: ["reachabilityStatus":status])
        }
        // start listening

        reachabilityManager?.startListening()
    }
}
