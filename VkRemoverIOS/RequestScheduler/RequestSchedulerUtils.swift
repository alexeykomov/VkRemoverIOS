//
//  RequestSchedulerUtils.swift
//  VkRemoverIOS
//
//  Created by Alex K on 6/15/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation


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

func createOperationFriendsDelete(user: RequestEntry) -> Operation2 {
    return Operation2(name: .friendsDelete,
                      params: [Param(paramName: ParamName.userId.rawValue,
                                     paramValue: String(user.userId),
                                     paramType: .number)])
}

func createOperationAccountBan(user: RequestEntry) -> Operation2 {
    return Operation2(name: .accountBan,
                      params: [Param(paramName: ParamName.ownerId.rawValue,
                                     paramValue: String(user.userId),
                                     paramType: .number)])
}

func createOperationAccountUnban(user: RequestEntry) -> Operation2 {
    return Operation2(name: .accountUnban,
                      params: [Param(paramName: ParamName.ownerId.rawValue,
                                     paramValue: String(user.userId),
                                     paramType: .number)])
}

func createOperationFriendsGetRequests() -> Operation2 {
    return Operation2(name: .friendsGetRequests,
                      params: [Param(paramName: "count",
                                     paramValue: String(1000),
                                     paramType: .number),
                               Param(paramName: "offset",
                                     paramValue: String(0),
                                     paramType: .number),
                               Param(paramName: "extended",
                                     paramValue: String(1),
                                     paramType: .number),
                               Param(paramName: "out",
                                     paramValue: String(1),
                                     paramType: .number),
                               Param(paramName: "fields",
                                     paramValue: getPhotoParam(),
                                     paramType: .number)
    ])
}

func createOperationUserGetFollowers() -> Operation2 {
    return Operation2(name: .userGetFollowers,
                      params: [Param(paramName: "count",
                                     paramValue: String(1000),
                                     paramType: .number),
                               Param(paramName: "offset",
                                     paramValue: String(0),
                                     paramType: .number),
                               Param(paramName: "fields",
                                     paramValue: getPhotoParam(),
                                     paramType: .number)
    ])
}
