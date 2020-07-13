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

func mapUserCategoryToRemoveRequestType(category: UserCategory) -> OperationType {
    switch (category) {
    case .friendRequest: return .friendsDelete
    case .follower: return .accountBan
    case .bannedUser: return .accountUnban
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

func mapUserCategoryToRemoveOperation(category: UserCategory, user: RequestEntry) -> Operation {
    switch (category) {
    case .friendRequest: return createOperationFriendsDelete(user: user)
    case .follower: return createOperationAccountBan(user: user)
    case .bannedUser: return createOperationAccountUnban(user: user)
    }
}
