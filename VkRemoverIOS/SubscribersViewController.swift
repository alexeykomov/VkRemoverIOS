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
    private var deleting = false
    
    @IBOutlet weak var refreshButton: UIButton!
    @IBAction func refresh(_ sender: Any) {
        startWorking()
    }
    
    @IBOutlet weak var deleteAllButton: UIButton!
    @IBAction func deleteAll(_ sender: UIButton) {
        updateDeletionProcess(deleting: !self.deleting)
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
}

