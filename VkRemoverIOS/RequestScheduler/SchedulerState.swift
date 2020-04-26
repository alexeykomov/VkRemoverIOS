//
//  SchedulerState.swift
//  VkRemoverIOS
//
//  Created by Alex K on 4/25/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

struct SchedulerState {
    let operations: Dictionary<OperationType, [Operation]>
    
    func toDict() -> Dictionary<String, Any> {
        var output: Dictionary<String, Any> = [:]
        output["operations"] = operations.reduce(output, {r, kv in
            return r.merging([kv.key.rawValue:kv.value.map({op in
                op.toDict()})],
                             uniquingKeysWith: {a, b in b})
        })
        return output
    }
    
    func isEmpty() -> Bool {
        let found = operations.reduce(false, {r, kv in
            return r || !kv.value.isEmpty
        })
        return !found
    }
    
    static func fromDict(_ inp: Dictionary<String, Any>) -> SchedulerState {
        let operations: Dictionary<String, Any> = inp["operations"] as?
            Dictionary<String, Any> ?? [:]
        let output: Dictionary<OperationType, [Operation]> = [:]
        return SchedulerState(operations: operations.reduce(output, {r, kv in
            guard let operationType = OperationType(rawValue: kv.key) else {
                return r
            }
            guard let operationsDict = kv.value as? [Dictionary<String, Any>] else {
                return r
            }
            let operations: [Operation] = operationsDict.reduce([], {r, op in
                guard let op = Operation.fromDict(op) else {
                    return r
                }
                return r + [op]
            })
            return r.merging([operationType:operations],
                             uniquingKeysWith: {a, b in b})
        }))
    }
}
