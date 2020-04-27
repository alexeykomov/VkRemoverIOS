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
        print("Code that will be sent: \(codeWithState.code)")
        #endif
        let code = codeWithState.code
        
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
                task.setTaskCompleted(success: true)
        }, errorBlock:  { error in
            print("error: \(error)")
        })
      
        task.expirationHandler = {
            request.cancel()
        }
    }
    
}
