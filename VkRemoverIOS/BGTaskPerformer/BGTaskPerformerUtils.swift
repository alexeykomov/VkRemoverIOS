//
//  utils.swift
//  VkRemoverIOS
//
//  Created by Alex K on 4/25/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

func formCodeFromOperations(state:SchedulerState) -> CodeWitрState {
    var modifiedState = state
    var modifiedOperations = modifiedState.operations
    let opsTypeCount = operationIndexes.count
    
    var codeStatements:Array<String> = []
    var operations:Dictionary<OperationType, [Operation]>  =  [
        OperationType.friendsDelete:[],
        OperationType.accountBan:[],
        OperationType.accountUnban:[]
    ]
    var letterCounter = 0
    while (letterCounter < MAXIMUM_NUMBER_OF_API_CALLS && !modifiedState.isEmpty()) {
        while (true) {
            let randomOpTypeIndex = Int.random(in: 0..<opsTypeCount)
            let opType = operationsByIndex[randomOpTypeIndex]
            guard var opsOfType = modifiedState.operations[opType] else {
                continue
            }
            guard !opsOfType.isEmpty else {
                continue
            }
            if !opsOfType.isEmpty {
                let first = opsOfType[0]
                opsOfType = Array(opsOfType.dropFirst())
                modifiedOperations[opType] = opsOfType
                let start = alphabet.index(alphabet.startIndex, offsetBy: letterCounter)
                letterCounter += 1
                let varName = alphabet[start]
                let code = "var \(varName) = API.\(opType.rawValue)({'\(first.paramName.rawValue)': \(first.user.userId)});"
                modifiedState = SchedulerState(operations: modifiedOperations)
                codeStatements.append(code)
                operations[opType] = (operations[opType] ?? []) + [first]
                break
            }
        }
    }
    return CodeWitрState(code: codeStatements.joined(separator: "\n"),
                         operations: operations, 
                         stateWithoutOperationsThatAreInCode: modifiedState)
}

func getTimeStamp(date: Date) -> String {
    if #available(iOS 10.0, *) {
        let fmt = ISO8601DateFormatter()
        let dateText = fmt.string(from: date)
        return dateText
    } else {
        // Fallback on earlier versions
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        fmt.calendar = Calendar(identifier: .iso8601)
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(secondsFromGMT: 0)
        let dateText = fmt.string(from: date)
        return dateText
    }
}
