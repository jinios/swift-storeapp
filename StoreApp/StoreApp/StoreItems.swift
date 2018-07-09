//
//  StoreItems.swift
//  StoreApp
//
//  Created by YOUTH2 on 2018. 7. 9..
//  Copyright © 2018년 JINiOS. All rights reserved.
//

import Foundation

struct StoreItems {
    let items: [ItemData]

    subscript(index: Int) -> ItemData {
        get {
            return items[index]
        }
    }

    func count() -> Int {
        return self.items.count
    }
}

struct ItemData: Codable {
    var detail_hash: String
    var image: String
    var alt: String
    var delivery_type: [String]
    var title: String
    var description: String
    var n_price: String?
    var s_price: String
    var badge: [String]?
}

