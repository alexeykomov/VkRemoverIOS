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

        let codeWithNames: CodeWithNames = formCodeFromOperations()
        #if DEBUG
        NSLog("Code that will be sent: %@", codeWithNames.code)
        #endif
        let code = codeWithNames.code
        let vars = codeWithNames.operationVars
        let operationTypes = codeWithNames.operationTypes
        
        let request: VKRequest = VKRequest.init(method: "execute", parameters:
            ["code": code])
        request.execute(
            resultBlock: { response in
                print("Response: \(response)")
                guard let dict = response?.json as? Dictionary<String, Any> else {
                    return
                }
                guard let items = dict["items"] as? [Dictionary<String, Any>] else {
                    return
                }
                vars.forEach({varName in
                    guard let success = dict[varName] else {
                        NSLog("Cannot get status of %@", varName)
                        return
                    }
                    guard let indexOfSentVar = vars.firstIndex(where: {sentVar
                            in sentVar == varName}) else {
                        NSLog("Cannot find index of %@", varName)
                        return
                    }
                    let operationSent = operationTypes[indexOfSentVar]
                    
                })
                
                task.setTaskCompleted(success: true)
        }, errorBlock:  { error in
            print("error: \(error)")
        })
      
        task.expirationHandler = {
            
            request.cancel()
        }
    }
    
    func formCodeFromOperations() -> CodeWithNames {
        let state = Storage.shared.getSchedulerState()
        var letterCounter = 0
        let codeWithNames = CodeWithNames(code: "", operationVars: [],
                                          operationTypes: [])
        let apiCalls = state.operations.reduce(codeWithNames, { res, keyValue in
            let codesList = keyValue.value.map {op -> CodeWithName in
                let start = alphabet.index(alphabet.startIndex, offsetBy: letterCounter)
                let end = alphabet.index(alphabet.startIndex, offsetBy: letterCounter + 1)
                let varName = String(alphabet[start..<end])
                letterCounter+=1
                let code = "var \(varName) = API.\(keyValue.key)({'\(op.paramName)': \(op.user.userId)})"
                return CodeWithName(code: code, operationVar: varName,
                                    operationType: op.name)
            }
            return CodeWithNames(code: res.code +
                codesList.reduce("", {total, code in total + code.code}),
                                 operationVars: res.operationVars +
                                    codesList.reduce([], {vars, code in
                                        vars + [code.operationVar]}),
                                 operationTypes: res.operationTypes +
                                    codesList.reduce([], {vars, code in
                                        vars + [code.operationType]})
            )
        })
        return apiCalls
    }
    
}

struct CodeWithName {
    let code: String
    let operationVar: String
    let operationType: OperationType
}

struct CodeWithNames {
    let code: String
    let operationVars: [String]
    let operationTypes: [OperationType]
}

let alphabet = "abcdefghijklmnopqrstuvwxyz"
