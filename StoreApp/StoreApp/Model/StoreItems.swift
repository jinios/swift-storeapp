//
//  StoreItems.swift
//  StoreApp
//
//  Created by YOUTH2 on 2018. 7. 9..
//  Copyright © 2018년 JINiOS. All rights reserved.
//

import Foundation

class StoreItems {
    static let categories: [Category] = [.main, .soup, .side]
    var storeItem: [Category: Items] = [:]

    init() {
        self.storeItem = [Category.main: Items(),
                          Category.soup: Items(),
                          Category.side: Items()]
        NotificationCenter.default.addObserver(self, selector: #selector(resetData), name: .reachabilityChanged, object: nil)
    }

    subscript(index: Int) -> Items {
        get {
            guard let items = storeItem[StoreItems.categories[index]] else { return Items() }
            return items
        }
    }

    func countOfHeaders() -> Int {
        return self.storeItem.keys.count
    }

    func update(key: Category, value: Items) {
        self.storeItem[key] = value
    }

    func set() {
        StoreItems.categories.forEach { (category) in
            self.loadData(of: category)
        }
    }

    private func loadData(of category: Category) {
        DataSetter.set(with: category) { items in
            self.update(key: items.keys.first!, value: items.values.first!)
            if let firstKey = items.firstKey {
                let indexPaths = Array(0..<self.storeItem[firstKey]!.count).map {IndexPath(row: $0, section: firstKey.sectionNumber)}
                NotificationCenter.default.post(name: .sectionSetComplete,
                                                object: self,
                                                userInfo: [Keyword.sectionPath : indexPaths])
            }
        }
    }

    // Execute when Reachability changed
    @objc func resetData() {
        self.set()
    }

}

struct Items {
    let items: [ItemData]
    var count: Int {
        return self.items.count
    }

    init() {
        self.items = []
    }

    init(data: [ItemData]) {
        self.items = data
    }

    subscript(index: Int) -> ItemData {
        get {
            return items[index]
        }
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

extension Dictionary where Key == Category, Value == Items {
    var firstKey: Category? {
        guard self.count > 0 else { return nil }
        return self.keys.first!
    }
}

