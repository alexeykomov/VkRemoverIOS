//
//  ViewController.swift
//  VkRemoverIOS
//
//  Created by Alex K on 10/27/19.
//  Copyright © 2019 Alex K. All rights reserved.
//

import UIKit

class RequestsViewController: BasicListViewController {
    private let dataSource = RequestsTableDataSource()
    private var deleting = false
    override func setDeleting(_ deleting: Bool) { self.deleting = deleting }
    override func getDeleting() -> Bool { return deleting }
    
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
        return OperationType.friendsDelete
    }
    
    override func getParamName() -> ParamName {
        return ParamName.userId
    }
    
    override func getVKMethodName() -> String {
        return "friends.getRequests"
    }
    
    override func getTableView() -> UITableView {
        return tableView
    }
    
    override func getDataSource() -> RequestsTableDataSource {
        return dataSource
    }
    
    override func vkEntitiesToInternalEntities(_ items: [Dictionary<String, Any>]) -> [RequestEntry] {
        return RequestEntry.fromRequestsList(items)
    }
}

struct FriendRequests: Decodable {
    let count: Int
    let items: [RequestEntry]
}

