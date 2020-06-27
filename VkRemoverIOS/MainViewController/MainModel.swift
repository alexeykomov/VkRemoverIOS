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
    
    var entries:Dictionary<UserCategory, [RequestEntry]> = [
        .friendRequest:[],
        .follower:[],
        .bannedUser:[]
    ]
    var listeners:Dictionary<MainModelEventType, [String:(Any) -> Void]> = [:]
    
    func bulkLoad(users: [RequestEntry], entry: UserCategory) {
        guard var usersOfType = entries[entry] else {
            return
        }
        usersOfType.append(contentsOf: users)
        entries[entry] = usersOfType
        var listeners: [String:([RequestEntry]) -> Void] = [:]
        switch entry {
        case .friendRequest: listeners = self.listeners[.bulkLoadBanned] ?? [:]
        case .follower: listeners = self.listeners[.bulkLoadFollower] ?? [:]
        case .bannedUser: listeners = self.listeners[.bulkLoadRequests] ?? [:]
        }
        listeners.forEach {kv in kv.value(users)}
    }
    
    func ban(user: RequestEntry) {
        entries[.bannedUser] = entries[.bannedUser]?.filter {user in user.userId != user.userId}
        listeners[.ban]?.forEach({kv in kv.value(user)})
        
        var followers = entries[.follower] ?? []
        if !followers.contains(user) {
            followers.append(user)
            entries[.follower] = followers
        }
    }
    
    func unban(user: RequestEntry) {
        entries[.follower] = entries[.follower]?.filter {user in user.userId != user.userId}
        listeners[.unBan]?.forEach({kv in kv.value(user)})
        
        var banned = entries[.bannedUser] ?? []
        if !banned.contains(user) {
            banned.append(user)
            entries[.bannedUser] = banned
        }
    }
    
    func cancelRequest(user: RequestEntry) {
        entries[.friendRequest] = entries[.friendRequest]?.filter {user in user.userId != user.userId}
        listeners[.cancelRequest]?.forEach({kv in kv.value(user)})
    }
    
    func addListener(type: MainModelEventType,
                     listener: @escaping (Any) -> Void) -> () -> Void {
        let uuid = UUID().uuidString
        listeners[type]?[uuid] = listener
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
        return !(entries[.bannedUser]?.map({user in user.userId == user.userId}).isEmpty ?? true)
    }
    
    func isRequested(user: RequestEntry) -> Bool {
        return !(entries[.friendRequest]?.map({user in user.userId == user.userId}).isEmpty ?? true)
    }
    
    func clearListeners() {
        listeners = [:]
    }
}

enum MainModelEventType {
    case bulkLoadRequests
    case bulkLoadBanned
    case bulkLoadFollower
    case ban
    case unBan
    case cancelRequest
}

enum UserCategory {
    case friendRequest
    case follower
    case bannedUser
}
