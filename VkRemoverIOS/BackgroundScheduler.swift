//
//  BackgroundScheduler.swift
//  VkRemoverIOS
//
//  Created by Alex K on 1/4/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

class BackgroundScheduler: NSObject {
    private var bgTimer: Timer?
    
    static let BAN_PERIOD: Double = 4 * 3600
    
    func start() {
        stop()
        bgTimer = Timer.scheduledTimer(timeInterval: 60, target: self,
                                                 selector: #selector(onTick),
                                                 userInfo: nil, repeats: true)
    }
    
    func stop() {
        bgTimer?.invalidate()
    }
    
    @objc func onTick() {
        let now = Date().timeIntervalSince1970
        let unbanOperations = Storage.shared.getBanned().filter({storedId in
            print("storedId.ts: \(storedId.whenBanned.timeIntervalSince1970)")
            print("now: \(now)")
            let distance = now - storedId.whenBanned.timeIntervalSince1970
            print("distance: \(distance)")
            return now - storedId.whenBanned.timeIntervalSince1970 >= BackgroundScheduler.BAN_PERIOD })
                .map({ storedId in
                    Operation(name: OperationType.accountUnban,
                              paramName: ParamName.ownerId,
                              userId: storedId.userId)
                })
        if !unbanOperations.isEmpty {
            requestScheduler.scheduleOps(operationType: OperationType.accountUnban,
                                         ops: unbanOperations,
                                         successCb: {userId,_ in Storage.shared.removeFromBanned(id: userId)},
                                         errorCb: {userId,_ in
                                            Storage.shared.removeFromBanned(id: userId)})
        }
    }
}

let bgScheduler = BackgroundScheduler()
