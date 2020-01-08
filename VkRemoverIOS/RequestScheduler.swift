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
                     ops: [Operation],
                     successCb: @escaping (Int, VKResponse<VKApiObject>?) -> Void,
                     errorCb: @escaping (Int, Error?) -> Void) {
        processQueue[operationType] = ops
        callbacks[operationType] = OperationCallbacks(successCb: successCb, errorCb: errorCb)
        if isProcessQueueEmpty() {
            return
        }
        if requestsTimer == nil {
            scheduleTimer()
        }
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
            if isProcessQueueEmpty() {
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
            print("opsOfType: \(opsOfType.count)")
            if let first = opsOfType.popLast() {
                processQueue[opType] = opsOfType
                print("first.userId: \(first.userId)")
                VKRequest.init(method: first.name.rawValue,
                               parameters:[first.paramName.rawValue:first.userId]).execute(
                    resultBlock: { response in
                        print("response: \(response)")
                        self.successCounter += 1
                        self.rescheduleTimer(up: false)
                        self.callbacks[opType]??.successCb(first.userId, response)
                }, errorBlock:  { error in
                    guard let error = error else {
                        return
                    }
                    let desc = error.localizedDescription
                    switch desc {
                    case "Flood control":
                        self.rescheduleTimer(up: true)
                        self.replayOperation(op: first)
                    case "One of the parameters specified was missing or invalid: owner_id is incorrect":
                        break
                    case "Access denied: user not blacklisted":
                        break
                    case "Access denied: No friend or friend request found.":
                        break
                    default:
                        self.replayOperation(op: first)
                    }
                    print("desc: \(desc)")
                    print("error: \(error)")
                    self.callbacks[opType]??.errorCb(first.userId, error)
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
    let userId: Int
}

struct OperationCallbacks {
    let successCb: (Int, VKResponse<VKApiObject>?) -> Void
    let errorCb: (Int, Error?) -> Void
}
