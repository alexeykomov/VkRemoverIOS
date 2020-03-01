//
//  RequestScheduler.swift
//  VkRemoverIOS
//
//  Created by Alex K on 12/28/19.
//  Copyright © 2019 Alex K. All rights reserved.
//

import Foundation

class RequestScheduler: NSObject {
    private var processQueue:Dictionary<OperationType, [Operation]> = [
        OperationType.friendsDelete:[],
        OperationType.accountBan:[],
        OperationType.accountUnban:[]
    ]
    private var callbacks:Dictionary<OperationType, OperationCallbacks?> = [
        OperationType.friendsDelete: nil,
        OperationType.accountBan: nil,
        OperationType.accountUnban: nil
    ]
    private var requestsTimer: Timer?
    private var period: Double = 1
    private let MULT_FACTOR = 2
    private var successCounter = 0
    private let MAX_SUCCESSES = 5
    
    func scheduleOps(operationType: OperationType,
                     ops: [Operation]) {
        processQueue[operationType] = ops
        if isProcessQueueEmpty() {
            return
        }
        if requestsTimer == nil {
            scheduleTimer()
        }
    }
    
    func save() {
        requestsTimer?.invalidate()
        Storage.shared.saveSchedulerState(SchedulerState(operations: processQueue))
    }
    
    func restore() {
        let schedulerState = Storage.shared.getSchedulerState()
        processQueue = schedulerState.operations
        
        if !isProcessQueueEmpty() {
             scheduleTimer()
        }
    }
    
    func assignCallbacks(operationType: OperationType, successCb: @escaping (RequestEntry, VKResponse<VKApiObject>?) -> Void,
                         errorCb: @escaping (RequestEntry, Error?, Bool) -> Void) {
        callbacks[operationType] = OperationCallbacks(successCb: successCb, errorCb: errorCb)
    }
        
    func rescheduleTimer(up: Bool) {
        let currentPeriod = Int(self.period)
        if currentPeriod == 1 && !up {
            return
        }
        if successCounter < MAX_SUCCESSES && !up {
            return
        }
        successCounter = 0
        self.period = Double(currentPeriod * (up ? MULT_FACTOR : 1/MULT_FACTOR))
        requestsTimer?.invalidate()
        scheduleTimer()
    }
    
    func scheduleTimer() {
        requestsTimer = Timer.scheduledTimer(timeInterval: period, target: self,
                                             selector: #selector(onTick),
                                             userInfo: nil, repeats: true)
    }
    
    func clearOps(operationType: OperationType) {
        processQueue[operationType] = []
        callbacks[operationType] = nil
        if isProcessQueueEmpty() {
            requestsTimer?.invalidate()
            requestsTimer = nil
        }
    }
    
    func isEmpty(operationType: OperationType) -> Bool {
        guard let ops = processQueue[operationType] else {
            return true
        }
        return ops.isEmpty
    }
    
    func isProcessQueueEmpty() -> Bool {
        return processQueue.map({k, v in v.count}).reduce(0, {a, b in a + b}) == 0
    }
    
    func performNextOperation() {
        var found = false
        while !found {
            let processQueueEmpty = isProcessQueueEmpty()
            if processQueueEmpty {
                requestsTimer?.invalidate()
                requestsTimer = nil
                return
            }
            let opsTypeCount = operationIndexes.count
            let randomOpTypeIndex = Int.random(in: 0..<opsTypeCount)
            let opType = operationsByIndex[randomOpTypeIndex]
            print("randomOpTypeIndex: \(randomOpTypeIndex)")
            guard var opsOfType = processQueue[opType] else {
                continue
            }
            guard !opsOfType.isEmpty else {
                continue
            }
            if !opsOfType.isEmpty {
                let first = opsOfType[0]
                processQueue[opType] = Array(opsOfType.dropFirst())
                print("first.userId: \(first.user.userId)")
                VKRequest.init(method: first.name.rawValue,
                               parameters:[first.paramName.rawValue:first.user.userId]).execute(
                    resultBlock: { response in
                        print("response: \(response)")
                        self.successCounter += 1
                        self.rescheduleTimer(up: false)
                        self.callbacks[opType]??.successCb(first.user, response)
                }, errorBlock:  { error in
                    guard let error = error else {
                        return
                    }
                    let desc = error.localizedDescription
                    var enabledDeletion = false
                    switch desc {
                    case "Flood control":
                        self.rescheduleTimer(up: true)
                        self.replayOperation(op: first)
                    case "One of the parameters specified was missing or invalid: owner_id is incorrect":
                        enabledDeletion = true
                        break
                    case "Access denied: user not blacklisted":
                        enabledDeletion = true
                        break
                    case "Access denied: No friend or friend request found.":
                        enabledDeletion = true
                        break
                    default:
                        enabledDeletion = true
                        break
                    }
                    print("desc: \(desc)")
                    print("error: \(error)")
                    self.callbacks[opType]??.errorCb(first.user, error, enabledDeletion)
                })
                found = true
            }
        }
    }
    
    func replayOperation(op: Operation) {
        let opType = op.name
        let opsOfTypeBeforeError = processQueue[opType] ?? []
        processQueue[opType] = [op] + opsOfTypeBeforeError
    }
    
    @objc func onTick() {
        performNextOperation()
    }
}

let requestScheduler = RequestScheduler()

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

struct Operation: Hashable {
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
