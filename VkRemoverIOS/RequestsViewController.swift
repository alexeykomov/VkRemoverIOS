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
    
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let splitViewControllerParent = self.parent?.parent as? UISplitViewController
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let vc = storyboard.instantiateViewController(withIdentifier: "detailPage")
//        splitViewControllerParent?.showDetailViewController(vc, sender: nil)
//    }
    
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

