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
    
    func getBanned() -> [StoredId] {
        return StoredId.fromDictList(defaults.array(forKey: "BANNED") as? [Dictionary<String, Any>] ?? [])
    }
    
    func addToBanned(id: Int) {
        let ts = Date()
        let prevBanned = getBanned()
        defaults.setValue(StoredId.toDictList(prevBanned.filter({storedId in storedId.userId != id}) + [StoredId(userId: id, whenBanned: ts)]),
                          forKey: "BANNED")
    }
    
    func removeFromBanned(id: Int) {
        let prevBanned = getBanned()
        defaults.setValue(StoredId.toDictList(prevBanned.filter({storedId in storedId.userId != id})),
                          forKey: "BANNED")
    }
}

struct StoredId {
    let userId: Int
    let whenBanned: Date
    
    static func toDictList(_ storeIds: [StoredId]) -> [Dictionary<String,Any>] {
        return storeIds.map({storeId in [
            "userId": storeId.userId,
            "whenBanned": storeId.whenBanned
        ]})
    }
    
    static func fromDictList(_ serializedStoreIds: [Dictionary<String, Any>]) -> [StoredId] {
        return serializedStoreIds.map({serializedStoreId in StoredId(
            userId: serializedStoreId["userId"] as? Int ?? 0,
            whenBanned: serializedStoreId["whenBanned"] as? Date ?? Date(timeIntervalSince1970: 0)
        )})
    }
}
