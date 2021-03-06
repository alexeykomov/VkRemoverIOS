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
    private var callbacks:Dictionary<OperationType, [OperationCallbacks]> = [
        OperationType.friendsDelete: [],
        OperationType.accountBan: [],
        OperationType.accountUnban: []
    ]
    private var requestsTimer: Timer?
    private var period: Double = 5
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
    
    func addCallbacks(operationType: OperationType, successCb: @escaping (RequestEntry, VKResponse<VKApiObject>?) -> Void,
                         errorCb: @escaping (RequestEntry, Error?, Bool) -> Void) {
        callbacks[operationType] = (callbacks[operationType] ?? []) + [
            OperationCallbacks(successCb: successCb, errorCb: errorCb)]
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
                        //self.rescheduleTimer(up: false)
                        guard let callbacks = self.callbacks[opType] else {
                            return
                        }
                        callbacks.forEach { callback in 
                            callback.successCb(first.user, response)
                        }
                        
                }, errorBlock:  { error in
                    guard let error = error else {
                        return
                    }
                    let desc = error.localizedDescription
                    var enabledDeletion = false
                    switch desc {
                    case "Flood control":
                        //self.rescheduleTimer(up: true)
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
                    guard let callbacks = self.callbacks[opType] else {
                        return
                    }
                    callbacks.forEach { callback in
                        callback.errorCb(first.user, error, enabledDeletion)
                    }
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

