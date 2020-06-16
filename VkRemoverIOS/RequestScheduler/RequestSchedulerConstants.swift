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
    case friendsGetRequests = "friends.getRequests"
    case userGetFollowers = "users.getFollowers"
}

enum ParamName: String {
    case userId = "user_id"
    case ownerId = "owner_id"
}

enum ParamType: String {
    case number = "number"
    case string = "string"
}

struct Param: Hashable, Equatable {
    let paramName: String
    let paramValue: String
    let paramType: ParamType
}

struct Operation2: Hashable, Equatable {
    let name: OperationType
    let params: [Param]
    
    func getPhotoParam() -> String {
        var photoParamName:[String] = []
        switch gScaleFactor.value {
        case 1.0:photoParamName.append("photo_50")
                photoParamName.append("photo_100")
        case 1.0...3.0:photoParamName.append("photo_100")
            photoParamName.append("photo_200_orig")
        default: break
        }
        return photoParamName.joined(separator: ",")
    }
    
    func getParams() -> Dictionary<String, Any> {
        return params.reduce ([:], { aRes, param  in
            var paramValue: Any
            var res = aRes
            switch param.paramType {
            case .number: paramValue = Int(param.paramValue) ?? 0
            case .string: paramValue = String(param.paramValue)
            default: paramValue = param.paramValue
            }
            res[param.paramName] = paramValue
            return res
        })
    }
}

struct Operation: Hashable, Equatable { 
    let name: OperationType
    let paramName: ParamName
    let user: RequestEntry
    
    func getPhotoParam() -> String {
        var photoParamName:[String] = []
        switch gScaleFactor.value {
        case 1.0:photoParamName.append("photo_50")
                photoParamName.append("photo_100")
        case 1.0...3.0:photoParamName.append("photo_100")
            photoParamName.append("photo_200_orig")
        default: break
        }
        return photoParamName.joined(separator: ",")
    }
    
    func getParams() -> Dictionary<String, Any> {
        switch name {
        case .friendsGetRequests:
            return ["count":1000, "offset": 0, "out": 1,
            "extended": 1, "fields": getPhotoParam()]
        case .userGetFollowers:
            return ["count":1000, "offset": 0, "fields": getPhotoParam()]
        case .friendsDelete:
            return [ParamName.userId.rawValue:user.userId]
        case.accountBan, .accountUnban:
            return [ParamName.ownerId.rawValue:user.userId]
        }
    }
    
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
