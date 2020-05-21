//
//  MainModel.swift
//  VkRemoverIOS
//
//  Created by Alex K on 5/19/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

class MainModel {
    
    static func shared() -> MainModel {
        guard let instance = instance else {
            let instance = MainModel()
            self.instance = instance
            return instance
        }
        
        return instance
    }
    
    static var instance: MainModel? = nil
    
    var entries:Dictionary<OperationType, [Operation]> = [:]
    var listeners:Dictionary<OperationType, [String:(RequestEntry) -> Void]> = [:]
    
    func ban(user: RequestEntry, ban: Bool) {
        if (ban) {
            entries[.accountBan] = entries[.accountBan]?.filter {o in o.user.userId != user.userId}
            listeners[.accountBan]?.forEach({kv in kv.value(user)})
            return
        }
        entries[.accountUnban] = entries[.accountUnban]?.filter {o in o.user.userId != user.userId}
        listeners[.accountUnban]?.forEach({kv in kv.value(user)})
    }
    
    func cancelRequest(user: RequestEntry) {
        entries[.friendsDelete] = entries[.friendsDelete]?.filter {o in o.user.userId != user.userId}
        listeners[.friendsDelete]?.forEach({kv in kv.value(user)})
    }
    
    func addListener(opType: OperationType, listener: @escaping (RequestEntry) -> Void) -> () -> Void { 
        let uuid = UUID().uuidString
        listeners[opType]?[uuid] = listener
        return { self.removeListener(uuid: uuid) }
    }
    
    func removeListener(uuid: String) {
        listeners = listeners.reduce([:], {res, kv in
            var listeners = kv.value
            var newOperationsToListeners = res
            listeners[uuid] = nil
            newOperationsToListeners[kv.key] = listeners
            return newOperationsToListeners
        })
    }
    
    func isBanned(user: RequestEntry) -> Bool {
        return !(entries[.accountBan]?.map({o in o.user.userId == user.userId}).isEmpty ?? true)
    }
    
    func isRequested(user: RequestEntry) -> Bool {
        return !(entries[.friendsDelete]?.map({o in o.user.userId == user.userId}).isEmpty ?? true)
    }
    
    func clearListeners() {
        listeners = [:]
    }
}
