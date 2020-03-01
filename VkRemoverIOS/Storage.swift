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
    
    func getBanned() -> [StoredUser] {
        return StoredUser.fromDictList(defaults.array(forKey: "BANNED") as? [Dictionary<String, Any>] ?? [])
    }
    
    func addToBanned(user: RequestEntry) {
        let ts = Date()
        let prevBanned = getBanned()
        defaults.setValue(StoredUser.toDictList(prevBanned.filter({storedId in storedId.user.userId != user.userId}) + [StoredUser(user: user, whenBanned: ts)]),
                          forKey: "BANNED")
    }
    
    func removeFromBanned(id: Int) {
        let prevBanned = getBanned()
        defaults.setValue(StoredUser.toDictList(prevBanned.filter({storedId in storedId.user.userId != id})),
                          forKey: "BANNED")
    }
    
    func saveSchedulerState(_ state: SchedulerState) {
        defaults.setValue(state.toDict(), forKey: "SCHEDULER_STATE")
    }
    
    func getSchedulerState() -> SchedulerState {
        return SchedulerState.fromDict(defaults.dictionary(forKey:
            "SCHEDULER_STATE") ?? [:])
    }
}

struct StoredUser {
    let user: RequestEntry
    let whenBanned: Date
    
    static func toDictList(_ storeIds: [StoredUser]) -> [Dictionary<String,Any>] {
        return storeIds.map({bannedUser in [
            "whenBanned": bannedUser.whenBanned,
            "user": bannedUser.user.toDict()
        ]})
    }
    
    static func fromDictList(_ serializedStoreIds: [Dictionary<String, Any>]) -> [StoredUser] {
        return serializedStoreIds.map({serializedStoreId in StoredUser(
            user: RequestEntry.fromDict(serializedStoreId["user"] as? Dictionary<String, Any> ?? [:]),
            whenBanned: serializedStoreId["whenBanned"] as? Date ?? Date(timeIntervalSince1970: 0)
        )})
    }
}
