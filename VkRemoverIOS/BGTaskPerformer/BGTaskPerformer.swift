//
//  BGTaskPerformer.swift
//  VkRemoverIOS
//
//  Created by Alex K on 3/8/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation
import BackgroundTasks

class BGTaskPerformer: NSObject {
    static var bgTaskPerformer:BGTaskPerformer? = nil
    
    private var callbacks:Dictionary<OperationType, [BgOperationCallbacks]> = [
        OperationType.friendsDelete: [],
        OperationType.accountBan: [],
        OperationType.accountUnban: []
    ]
    
    static func shared() -> BGTaskPerformer {
        guard let bgTaskPerformer = BGTaskPerformer.bgTaskPerformer else {
            let bgTaskPerformer = BGTaskPerformer()
            BGTaskPerformer.bgTaskPerformer = bgTaskPerformer
            return bgTaskPerformer
        }
        return bgTaskPerformer
    }
    
    @available(iOS 13.0, *)
    func scheduleAppRefresh() {
        requestScheduler.save()
        let request = BGAppRefreshTaskRequest(identifier: "me.alexeykomov.VkRemoverIOS.refresh")
        do {
            try BGTaskScheduler.shared.submit(request)
            
        } catch {
            print("Could not schedule app refresh: \(error)")
       }
    }
    
    @available(iOS 13.0, *)
    func handleAppRefresh(_ task: BGAppRefreshTask) {
        scheduleAppRefresh()

        let codeWithState: CodeWithNames = formCodeFromOperations(
            state: Storage.shared.getSchedulerState())
        #if DEBUG
        let now = Date()
        let fmt = ISO8601DateFormatter()
        let dateText = fmt.string(from: now)
        print("Code that will be sent at \(dateText)): \(codeWithState.code)")
        #endif
        let code = codeWithState.code
        let operations = codeWithState.operations
        if code.isEmpty {
            task.setTaskCompleted(success: true)
            return
        }
        
        let request: VKRequest = VKRequest.init(method: "execute", parameters:
                   ["code": code])
        request.execute(
            resultBlock: { response in
                guard let response = response else {
                    return
                }
                print("Response: \(response)")
                print("Response string: \(response.responseString)")
                
                Storage.shared.saveSchedulerState(
                    codeWithState.stateWithoutOperationsThatAreInCode)
                
                operations.forEach { operationTypeAndOps in
                    let opType = operationTypeAndOps.key
                    guard let callbacks = self.callbacks[opType] else {
                        return
                    }
                    callbacks.forEach { callback in
                        callback.successCb(operationTypeAndOps.value.map { o in
                            o.user }, response)
                    }
                }
                
                task.setTaskCompleted(success: true)
        }, errorBlock:  { error in
            print("error: \(error)")
        })
      
        task.expirationHandler = {
            request.cancel()
        }
    }
    
    func addCallbacks(operationType: OperationType, successCb: @escaping ([RequestEntry], VKResponse<VKApiObject>?) -> Void,
                         errorCb: @escaping ([RequestEntry], Error?) -> Void) {
        callbacks[operationType] = (callbacks[operationType] ?? []) + [
            BgOperationCallbacks(successCb: successCb, errorCb: errorCb)]
    }
    
}
