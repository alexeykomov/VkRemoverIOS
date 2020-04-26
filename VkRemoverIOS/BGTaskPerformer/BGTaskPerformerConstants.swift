//
//  BGTaskPerformerConstants.swift
//  VkRemoverIOS
//
//  Created by Alex K on 4/25/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

struct CodeWithName {
    let code: String
    let operationVar: String
    let operationType: OperationType
}

struct CodeWithNames {
    let code: String
    let stateWithoutOperationsThatAreInCode: SchedulerState
}

let alphabet = "abcdefghijklmnopqrstuvwxyz"

let MAXIMUM_NUMBER_OF_API_CALLS = min(25, alphabet.count)
