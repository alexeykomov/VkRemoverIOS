//
//  RequestSchedulerConstants.swift
//  VkRemoverIOS
//
//  Created by Alex K on 4/25/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation



let operationIndexes = [
    OperationType.friendsDelete: 0,
    OperationType.accountBan: 1,
    OperationType.accountUnban: 2,
]

let operationsByIndex = [OperationType.friendsDelete, OperationType.accountBan, OperationType.accountUnban]

enum OperationType: String {
    case friendsDelete = "friends.delete"
    case accountBan = "account.ban"
    case accountUnban = "account.unban"
}

enum ParamName: String {
    case userId = "user_id"
    case ownerId = "owner_id"
}

struct Operation: Hashable, Equatable { 
    let name: OperationType
    let paramName: ParamName
    let user: RequestEntry
    
    func toDict() -> Dictionary<String, Any> {
        var output: Dictionary<String, Any> = [:]
        output["name"] = name.rawValue
        output["paramName"] = paramName.rawValue
        output["user"] = user.toDict()
        return output
    }
    
    static func fromDict(_ inp: Dictionary<String, Any>) -> Operation? {
        guard let name = inp["name"] as? String else {
            return nil
        }
        guard let operationType = OperationType(rawValue: name) else {
            return nil
        }
        guard let paramNameStr = inp["paramName"] as? String else {
            return nil
        }
        guard let paramName = ParamName(rawValue: paramNameStr) else {
            return nil
        }
        guard let userDict = inp["user"] as? Dictionary<String, Any> else {
            return nil
        }
        let user = RequestEntry.fromDict(userDict)
        return Operation(name: operationType,
                  paramName: paramName,
                  user: user)
    }
}

struct OperationCallbacks {
    let successCb: (RequestEntry, VKResponse<VKApiObject>?) -> Void
    let errorCb: (RequestEntry, Error?, Bool) -> Void
}
