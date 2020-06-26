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
    
    func toDict() -> Dictionary<String, String> {
        return [
            "paramName":paramName,
            "paramValue": paramValue,
            "paramType": paramType.rawValue
        ]
    }
    
    static func fromDict(_ input: Dictionary<String, String>) -> Param? {
        guard let paramName = input["paramName"] else {
            return nil
        }
        guard let paramValue = input["paramValue"] else {
            return nil
        }
        guard let paramType = input["paramType"] else {
            return nil
        }
        guard let paramTypeReckognized = ParamType(rawValue: paramType) else {
            return nil
        }
        return Param(paramName: paramName, paramValue: paramValue,
                     paramType: paramTypeReckognized)
    }
}

struct Operation: Hashable, Equatable {
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
    
    func toDict() -> Dictionary<String, Any> {
        var output: Dictionary<String, Any> = [:]
        output["name"] = name.rawValue
        output["params"] = params.map({ p in p.toDict()})
        return output
    }
    
    static func fromDict(_ inp: Dictionary<String, Any>) -> Operation? {
        guard let name = inp["name"] as? String else {
            return nil
        }
        guard let nameReckognized = OperationType(rawValue: name) else {
            return nil
        }
        guard let params = inp["params"] as? [Dictionary<String, String>] else {
            return nil
        }
        let acc:[Param] = []
        let paramsDeserialized = params.reduce(acc, { res, param in
            guard let paramDeserialized = Param.fromDict(param) else {
                return res
            }
            return res + [paramDeserialized]
        })
        return Operation(name: nameReckognized,
                  params: paramsDeserialized)
    }
}

struct OperationCallbacks {
    let successCb: (RequestEntry, VKResponse<VKApiObject>?) -> Void
    let errorCb: (RequestEntry, Error?, Bool) -> Void
    let uuid: String
}
