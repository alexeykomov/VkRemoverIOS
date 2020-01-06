//
//  SubscribersViewController.swift
//  VkRemoverIOS
//
//  Created by Alex K on 12/26/19.
//  Copyright © 2019 Alex K. All rights reserved.
//

import Foundation

import UIKit

class SubscribersViewController: UIViewController, VKSdkUIDelegate, VKSdkDelegate {
    private let dataSource = RequestsTableDataSource()
    private var deleting = false
    
    @IBOutlet weak var refreshButton: UIButton!
    @IBAction func refresh(_ sender: UIButton) {
    }
    @IBOutlet weak var deleteAllButton: UIButton!
    @IBAction func deleteAll(_ sender: UIButton) {
        updateDeletionProcess(deleting: !self.deleting)
    }
    @IBOutlet weak var tableView: UITableView!
    
    func updateDeletionProcess(deleting: Bool) {
        if deleting && dataSource.getData().isEmpty {
            return
        }
        if deleting {
            requestScheduler.scheduleOps(operationType: OperationType.accountBan,
                ops: dataSource.getData().map({d in Operation(name: OperationType.accountBan,
                                                              paramName: ParamName.ownerId,
                                                              userId: d.userId)}),
                successCb: {userId, r in
                    self.removeFromDataAndTable(userId: userId)
                    Storage.shared.addToBanned(id: userId)
                    if self.dataSource.getData().isEmpty {
                        self.deleting = false
                    }},
                errorCb: {userId, e in })
        } else {
            requestScheduler.clearOps(operationType: OperationType.accountBan)
        }
        self.deleting = deleting
        deleteAllButton.setTitle(deleting ? "Stop deleting" : "Delete All", for: .normal)
    }
    
    func removeFromDataAndTable(userId: Int) {
        guard let indexToDelete = self.dataSource.getData().firstIndex(where: {r in r.userId == userId}) else {
            print("Cannont find index in data for userId: \(userId)")
            return
        }
        dataSource.remove(at: indexToDelete)
        self.tableView.deleteRows(at: [IndexPath(row: indexToDelete, section: 0)],
                             with: UITableView.RowAnimation.automatic)
    }
    
    func vkSdkAccessAuthorizationFinished(with result: VKAuthorizationResult!) {
        if (result.token != nil) {
            self.startWorking()
        } else if ((result.error) != nil) {
            UIAlertView.init(title: "", message: "Access denied \(result.error)", delegate: self, cancelButtonTitle: "Ok").show()
         }
    }
    
    func vkSdkUserAuthorizationFailed() {
        UIAlertView.init(title: "", message: "Access denied", delegate: self, cancelButtonTitle: "Ok").show()
        navigationController?.popToRootViewController(animated: true)
    }
    
    func vkSdkShouldPresent(_ controller: UIViewController!) {
        self.navigationController?.topViewController?.present(controller,
                                                              animated: true,
                                                              completion: {})
    }
    
    func vkSdkNeedCaptchaEnter(_ captchaError: VKError!) {
        let vc = VKCaptchaViewController.captchaControllerWithError(captchaError)
        vc?.present(in: self.navigationController?.topViewController)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        updateDeletionProcess(deleting: false)
        
        let SCOPE = [VK_PER_FRIENDS];
           
        let instance = VKSdk.initialize(withAppId: "7144627")
        instance?.uiDelegate = self
        instance?.register(self)
        VKSdk.wakeUpSession(SCOPE, complete: {state, error in
            if (state == VKAuthorizationState.authorized) {
                self.startWorking()
            } else if (error != nil) {
                UIAlertView(title: "", message: error.debugDescription,
                            delegate: self as! UIAlertViewDelegate,
                            cancelButtonTitle: "Ok").show()
            }
        })
        VKSdk.authorize(SCOPE)
        tableView.dataSource = dataSource
    }
    
    func startWorking() {
        VKRequest.init(method:"users.getFollowers",
                       parameters:["count":1000, "offset": 0,
                                   "fields": "photo_50"]).execute(
            resultBlock: { response in
                guard let dict = response?.json as? Dictionary<String, Any> else {
                    return
                }
                guard let items = dict["items"] as? [Dictionary<String, Any>] else {
                    return
                }
                print("items: \(items)")
                let parsedItems = RequestEntry.fromFollowersList(items)
                print("parsed items: \(parsedItems)")
                self.dataSource.addData(parsedItems)
                self.tableView.reloadData()
        }, errorBlock:  { error in
            print("error: \(error)")
        })
    }
}

