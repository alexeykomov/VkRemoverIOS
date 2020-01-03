//
//  Storage.swift
//  VkRemoverIOS
//
//  Created by Alex K on 1/3/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

class Storage: NSObject {
    static let shared = Storage()
    
    let defaults = UserDefaults()
    
    func getBanned() -> [Int] {
        return defaults.array(forKey: "BANNED") as? [Int] ?? []
    }
    
    func addToBanned(id: Int) {
        let prevBanned = getBanned()
        defaults.setValue((prevBanned.filter({presentId in presentId != id}) + [id]),
                          forKey: "BANNED")
    }
    
    func removeFromBanned(id: Int) {
        let prevBanned = getBanned()
        defaults.setValue(prevBanned.filter({presentId in presentId != id}),
                          forKey: "BANNED")
    }
}
