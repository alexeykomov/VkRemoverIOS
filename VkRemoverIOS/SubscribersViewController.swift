//
//  SubscribersViewController.swift
//  VkRemoverIOS
//
//  Created by Alex K on 12/26/19.
//  Copyright © 2019 Alex K. All rights reserved.
//

import Foundation

import UIKit

class SubscribersViewController: BasicListViewController {
    private let dataSource = RequestsTableDataSource()
    
    @IBOutlet weak var refreshButton: UIButton!
    @IBAction func refresh(_ sender: Any) {
        playFeedback()
        startWorking()
    }
    
    @IBOutlet weak var deleteAllButton: UIButton!
    @IBAction func deleteAllAction(_ sender: Any) {
        playFeedback()
        print("deleting: \(getDeleting())")
        updateDeletionProcess(deleting: !getDeleting())
    }
    
    override func getDeleteAllButton() -> UIButton! {
        return deleteAllButton
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    override func getOperationType() -> OperationType {
        return OperationType.accountBan
    }
    
    override func getParamName() -> ParamName {
        return ParamName.ownerId
    }
    
    override func getVKMethodName() -> String {
        return "users.getFollowers"
    }
    
    override func getTableView() -> UITableView {
        return tableView
    }
    
    override func getDataSource() -> RequestsTableDataSource {
        return dataSource
    }
    
    override func vkEntitiesToInternalEntities(_ items: [Dictionary<String, Any>]) -> [RequestEntry] {
        return RequestEntry.fromFollowersList(items)
    }
    
    override func didDeleteUserSuccess(user: RequestEntry) {
        Storage.shared.addToBanned(user: user)
    }
}

