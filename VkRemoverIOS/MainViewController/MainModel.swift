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
        entries[entry] = users
        var listeners: [String:(UsersAndCategory) -> Void] = [:]
        switch entry {
        case .friendRequest: listeners = self.listeners[.bulkLoadBanned] ?? [:]
        case .follower: listeners = self.listeners[.bulkLoadFollower] ?? [:]
        case .bannedUser: listeners = self.listeners[.bulkLoadRequests] ?? [:]
        }
        listeners.forEach {kv in
            kv.value(UsersAndCategory(users: users, category: entry))}
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
    
    func removeFriendRequest(user: RequestEntry) {
        entries[.friendRequest] = entries[.friendRequest]?.filter {user in user.userId != user.userId}
        listeners[.removeFriendRequest]?.forEach({kv in kv.value(user)})
    }
    
    func removeFromEntries(user: RequestEntry, category: UserCategory) {
        let entriesOfCategory = entries[category] ?? []
        let userId = user.userId
        entries[category] = entriesOfCategory.filter {r in r.userId != userId}
        listeners[.removeFromEntries]?.forEach({kv in
            kv.value(UserAndCategory(user: user, category: category))})
    }
    
    func removeFromEntriesBulk(users: [RequestEntry], category: UserCategory) {
        var entriesOfCategory = entries[category] ?? []
        let indicesToDelete:[(Int, Int)] = users.reduce([], { res, user in
            let userId = user.userId
            guard let indexToDelete = entriesOfCategory
                .firstIndex(where: {r in r.userId == userId}) else {
               print("Cannont find index in data for userId: \(userId)")
               return res
            }
            return res + [(indexToDelete, userId)]
        })
        print("Indexes to delete: \(indicesToDelete)")
        let sortedIndicesToDelete = indicesToDelete.sorted(by: { indexUserIdPairA, indexUserIdPairB in
            indexUserIdPairA.0 > indexUserIdPairB.0
        })
        print("Sorted indexes to delete: \(sortedIndicesToDelete)")
        sortedIndicesToDelete.forEach { indexUserIdPair in
            entriesOfCategory.remove(at: indexUserIdPair.0)
        }
        entries[category] = entriesOfCategory
        listeners[.removeFromEntriesBulk]?.forEach({kv in
            kv.value(IndicesToDeleteForCategory(indices: sortedIndicesToDelete, category: category))})
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
    case removeFriendRequest
    case removeFromEntries
    case removeFromEntriesBulk
}

enum UserCategory {
    case friendRequest
    case follower
    case bannedUser
}

struct UserAndCategory {
    let user: RequestEntry
    let category: UserCategory
}

struct UsersAndCategory {
    let users: [RequestEntry]
    let category: UserCategory
}

struct IndicesToDeleteForCategory {
    let indices: [(Int, Int)]
    let category: UserCategory
}
