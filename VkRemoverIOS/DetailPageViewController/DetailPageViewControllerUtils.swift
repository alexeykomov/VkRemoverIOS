//
//  DetailPageViewControllerUtils.swift
//  VkRemoverIOS
//
//  Created by Alex K on 5/23/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

func mapUserGetResponse(_ item: Dictionary<String, Any>) -> UserGetResponse {
    return UserGetResponse(userId: item["id"] as? Int ?? 0,
                           firstName: item["first_name"] as? String ?? "",
                           lastName: item["last_name"] as? String ?? "",
                           photo200Orig: item["photo_200_orig"] as? String ?? "",
                           friendStatus: FriendStatus.fromValue(item["friend_status"] as? Int ?? 0),
                           blackListedByMe: (item["blacklisted_by_me"] as? Int ?? 0 == 1) ? true : false)
}

func mapUserGetResponses(_ items: [Dictionary<String, Any>]) -> [UserGetResponse] {
    return items.map { item in mapUserGetResponse(item) }
}



struct UserGetResponse {
    let userId: Int
    let firstName: String
    let lastName: String
    let photo200Orig: String
    let friendStatus: FriendStatus
    let blackListedByMe: Bool
}

/**
 статус дружбы с пользователем. Возможные значения:

 0 — не является другом,
 1 — отправлена заявка/подписка пользователю,
 2 — имеется входящая заявка/подписка от пользователя,
 3 — является другом.
 */

enum FriendStatus: Int {
    
    static func fromValue(_ inp: Int) -> FriendStatus {
        return FriendStatus.init(rawValue: inp) ?? .notFriend
    }
    
    case notFriend = 0
    case sentRequest = 1
    case gotRequest = 2
    case friend = 3
}
