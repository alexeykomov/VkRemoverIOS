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
    
    @IBAction func refresh(_ sender: Any) {
        startWorking()
    }
    @IBOutlet weak var deleteAllButton: UIButton!
    @IBAction func deleteAllAction(_ sender: Any) {
        if #available(iOS 10.0, *) {
            let feedbackGenerator = UISelectionFeedbackGenerator()
            feedbackGenerator.prepare()
            feedbackGenerator.selectionChanged()
        } else {
            // Fallback on earlier versions
        }
        
        
        updateDeletionProcess(deleting: !self.deleting)
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
}

struct FriendRequests: Decodable {
    let count: Int
    let items: [RequestEntry]
}

