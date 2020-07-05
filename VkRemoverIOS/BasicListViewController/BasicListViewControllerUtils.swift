//
//  BasicListViewControllerUtils.swift
//  VkRemoverIOS
//
//  Created by Alex K on 7/5/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

func mapUserCategoryToLoadRequestType(category: UserCategory) -> OperationType? {
    switch (category) {
    case .friendRequest: return .friendsGetRequests
    case .follower: return .userGetFollowers
    case .bannedUser: return nil
    }
}

func mapUserCategoryToBulkLoadModelEventType(category: UserCategory) -> MainModelEventType {
    switch (category) {
    case .friendRequest: return .bulkLoadRequests
    case .follower: return .bulkLoadFollower
    case .bannedUser: return .bulkLoadBanned
    }
}

func mapUserCategoryToLoadOperation(category: UserCategory) -> Operation? {
    switch (category) {
    case .friendRequest: return createOperationFriendsGetRequests()
    case .follower: return createOperationUserGetFollowers()
    case .bannedUser: return nil
    }
    
}
