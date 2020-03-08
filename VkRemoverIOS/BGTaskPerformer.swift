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
    @available(iOS 13.0, *)
    func scheduleAppRefresh() {
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

        let code = formCodeFromOperations()
        
        let request: VKRequest = VKRequest.init(method: "execute", parameters:
            ["code": code])
        request.execute(
            resultBlock: { response in
                guard let dict = response?.json as? Dictionary<String, Any> else {
                    return
                }
                guard let items = dict["items"] as? [Dictionary<String, Any>] else {
                    return
                }
                dict.forEach {opType, opResults in
                    
                }
                print("items: \(items)")
                let parsedItems = self.vkEntitiesToInternalEntities(items)
                print("userIds: \(self.userIds)")
                let filtered = parsedItems.filter({e in !self.userIds.contains(e.userId)})
                self.userIds = self.userIds.union(filtered.map({user in user.userId}))
                print("parsed items: \(parsedItems)")
                self.getDataSource().addData(filtered)
                self.getTableView().reloadData()
                if self.deleting {
                    self.updateDeletionProcess(deleting: true)
                }
                self.refreshControl.endRefreshing()
                task.setTaskCompleted(success: !operation.isCancelled)
        }, errorBlock:  { error in
            print("error: \(error)")
            self.refreshControl.endRefreshing()
        })
      
        task.expirationHandler = {
            request.cancel()
        }
    }
    
    func formCodeFromOperations() -> String {
        let state = Storage.shared.getSchedulerState()
        let apiCalls = state.operations.reduce("", { res, keyValue in
            keyValue.value.map {op in
                "var a = API.\(keyValue.key)({'\(op.paramName)': \(op.user.userId)})"}
            res
        })
        let code = ""
    }
    
}

let CODE
