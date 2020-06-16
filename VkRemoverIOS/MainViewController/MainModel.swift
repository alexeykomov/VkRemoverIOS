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
    
    var entries:Dictionary<OperationType, [RequestEntry]> = [
        .friendsDelete:[],
        .accountBan:[],
        .accountUnban:[]
    ]
    var listeners:Dictionary<MainModelEventType, [String:(Any) -> Void]> = [:]
    
    func bulkLoad(users: [RequestEntry], opType: OperationType) {
        guard var usersOfType = entries[opType] else {
            return
        }
        usersOfType.append(users)
        entries[opType] = usersOfType
        var listeners: [String:(RequestEntry) -> Void] = [:]
        switch opType {
        case .accountBan: listeners = self.listeners[.bulkLoadBanned] ?? [:]
        case .accountUnban: listeners = self.listeners[.bulkLoadUnBanned] ?? [:]
        case .friendsDelete: listeners = self.listeners[.bulkLoadRequests] ?? [:]
        }
        listeners.forEach {kv in kv.value(users)}
    }
    
    func ban(user: RequestEntry) {
        entries[.accountBan] = entries[.accountBan]?.filter {o in o.user.userId != user.userId}
        listeners[.accountBan]?.forEach({kv in kv.value(user)})
        
        var unbanned = entries[.accountUnban] ?? []
        let unbanOperation = Operation(name: .accountUnban, paramName: .ownerId, user: user)
        if !unbanned.contains(unbanOperation) {
            unbanned.append(unbanOperation)
            entries[.accountUnban] = unbanned
        }
    }
    
    func unban(user: RequestEntry) {
        entries[.accountUnban] = entries[.accountUnban]?.filter {o in o.user.userId != user.userId}
        listeners[.accountUnban]?.forEach({kv in kv.value(user)})
        
        var banned = entries[.accountBan] ?? []
        let banOperation = Operation(name: .accountBan, paramName: .ownerId, user: user)
        if !banned.contains(banOperation) {
            banned.append(banOperation)
            entries[.accountBan] = banned
        }
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


enum MainModelEventType {
    case bulkLoadRequests
    case bulkLoadBanned
    case bulkLoadUnBanned
    case ban
    case unBan
}
