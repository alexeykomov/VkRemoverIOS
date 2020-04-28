//
//  BannedViewController.swift
//  VkRemoverIOS
//
//  Created by Alex K on 1/18/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

import UIKit

class BannedViewController: BasicListViewController {
    private var userIds = Set<Int>()
    private let dataSource = RequestsTableDataSource()
    
    @IBOutlet weak var refreshButton: UIButton!
    @IBAction func refresh(_ sender: Any) {
        playFeedback()
        startWorking()
    }
    
    @IBOutlet weak var deleteAllButton: UIButton!
    @IBAction func deleteAllAction(_ sender: Any) {
        playFeedback()
        updateDeletionProcess(deleting: !getDeleting())
    }
    
    override func getDeleteAllButton() -> UIButton! {
        return deleteAllButton
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    override func getOperationType() -> OperationType {
        return OperationType.accountUnban
    }
    
    override func getParamName() -> ParamName {
        return ParamName.ownerId
    }
    
    override func getVKMethodName() -> String {
        // View is not populated from VK.
        return ""
    }
    
    override func getTableView() -> UITableView {
        return tableView
    }
    
    override func getDataSource() -> RequestsTableDataSource {
        return dataSource
    }
    
    override func setupVkData() {
        let SCOPE = [VK_PER_FRIENDS];
        let instance = VKSdk.initialize(withAppId: "7144627")
        instance?.uiDelegate = self
        instance?.register(self)
        getTableView().dataSource = getDataSource()
        startWorking()
    }
    
    override func startWorking() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let items = Storage.shared.getBanned()
            print("items: \(items)")
            let filtered = items.map({item in item.user}).filter({e in !self.userIds.contains(e.userId)})
            self.userIds = self.userIds.union(filtered.map({user in user.userId}))
            print("parsed items: \(filtered)")
            self.getDataSource().addData(filtered)
            self.getTableView().reloadData()
            if self.deleting {
                self.updateDeletionProcess(deleting: true)
            }
            self.refreshControl.endRefreshing()
        }
    }
    
    override func didDeleteUserSuccess(user: RequestEntry) {
        Storage.shared.removeFromBanned(id: user.userId)
    }
    
    override func didDeleteUserFailure(user: RequestEntry) {
        Storage.shared.removeFromBanned(id: user.userId)
    }
    
    override func didDeleteUserSuccess(users: [RequestEntry]) {
        users.forEach { user in
            Storage.shared.removeFromBanned(id: user.userId)
        }
    }
    
    override func didDeleteUserFailure(users: [RequestEntry]) {
        users.forEach { user in
            Storage.shared.removeFromBanned(id: user.userId)
        }
    }
    
}


