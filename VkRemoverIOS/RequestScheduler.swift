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
    
    func scheduleOps(operationType: OperationType,
                     ops: [Operation],
                     successCb: @escaping (Int, VKResponse<VKApiObject>?) -> Void,
                     errorCb: @escaping (Error?) -> Void) {
        processQueue[operationType] = ops
        callbacks[operationType] = OperationCallbacks(successCb: successCb, errorCb: errorCb)
        if isProcessQueueEmpty() {
            return
        }
        
        if requestsTimer == nil {
            requestsTimer = Timer.scheduledTimer(timeInterval: 10, target: self,
                                                 selector: #selector(onTick),
                                                 userInfo: nil, repeats: true)
        }
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
            print("processQueueEmpty: \(processQueueEmpty)")
            if isProcessQueueEmpty() {
                requestsTimer?.invalidate()
                requestsTimer = nil
                return
            }
            
            let opsTypeCount = operationIndexes.count
            let randomOpTypeIndex = Int.random(in: 0..<opsTypeCount)
            let randomOpType = operationsByIndex[randomOpTypeIndex]
            print("randomOpTypeIndex: \(randomOpTypeIndex)")
            
            guard var opsOfType = processQueue[randomOpType] else {
                continue
            }
            guard !opsOfType.isEmpty else {
                continue
            }
            print("opsOfType: \(opsOfType.count)")
            if let first = opsOfType.popLast() {
                processQueue[randomOpType] = opsOfType
                print("first.userId: \(first.userId)")
                VKRequest.init(method: first.name.rawValue,
                               parameters:[first.paramName.rawValue:first.userId]).execute(
                    resultBlock: { response in
                        print("response: \(response)")
                        self.callbacks[randomOpType]??.successCb(first.userId, response)
                }, errorBlock:  { error in
                    print("error: \(error)")
                    self.callbacks[randomOpType]??.errorCb(error)
                })
                found = true
            }
        }
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
    let errorCb: (Error?) -> Void
}
