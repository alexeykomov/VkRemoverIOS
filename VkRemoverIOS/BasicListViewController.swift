//
//  BasicListViewController.swift
//  VkRemoverIOS
//
//  Created by Alex K on 1/11/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

class BasicListViewController: UIViewController, VKSdkUIDelegate, VKSdkDelegate {
    private let dataSource = RequestsTableDataSource()
    private var userIds = Set<Int>()
    private var deleting = false
    func setDeleting(_ deleting: Bool) { self.deleting = deleting }
    func getDeleting() -> Bool { return deleting }
    
    func getDataSource() ->RequestsTableDataSource {
        return dataSource
    }
    
    func getDeleteAllButton() -> UIButton! {
        return UIButton()
    }
    
    func getTableView() -> UITableView! {
        return UITableView()
    }
    
    func getOperationType() -> OperationType {
        return OperationType.friendsDelete
    }
    
    func getParamName() -> ParamName {
        return ParamName.ownerId
    }
    
    func getVKMethodName() -> String {
        return "friends.getRequests"
    }
    
    func playFeedback() {
        if #available(iOS 10.0, *) {
            let feedbackGenerator = UISelectionFeedbackGenerator()
            feedbackGenerator.prepare()
            feedbackGenerator.selectionChanged()
        }
    }
    
    func updateDeletionProcess(deleting: Bool) {
        if getDeleting() && getDataSource().getData().isEmpty {
            return
        }
        if getDeleting() {
            requestScheduler.scheduleOps(operationType: getOperationType(),
                ops: getDataSource().getData().map({d in
                    print("user: \(d.userId) \(d.firstName) \(d.lastName)")
                    
                    return Operation(
                    name: getOperationType(),
                    paramName: getParamName(),
                    user: d)}),
                successCb: {user, r in
                    self.removeFromDataAndTable(userId: user.userId)
                    self.userDidDelete(user: user)
                    if self.getDataSource().getData().isEmpty {
                        self.setDeleting(false)
                    }},
                
                errorCb: {userId, e in })
        } else {
            requestScheduler.clearOps(operationType: getOperationType())
        }
        self.setDeleting(deleting)
        getDeleteAllButton().setTitle(getDeleting() ? "Stop deleting" : "Delete All", for: .normal)
    }

    func userDidDelete(user: RequestEntry) {
    }
    
    func removeFromDataAndTable(userId: Int) {
        guard let indexToDelete = self.getDataSource().getData().firstIndex(where: {r in r.userId == userId}) else {
            print("Cannont find index in data for userId: \(userId)")
            return
        }
        getDataSource().remove(at: indexToDelete)
        userIds.remove(indexToDelete)
        self.getTableView().deleteRows(at: [IndexPath(row: indexToDelete, section: 0)],
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
        getTableView().dataSource = getDataSource()
    }
    
    func vkEntitiesToInternalEntities(_ items: [Dictionary<String, Any>]) -> [RequestEntry] {
        return RequestEntry.fromRequestsList(items)
    }
    
    func startWorking() {
        VKRequest.init(method: getVKMethodName(),
                       parameters:["count":1000, "offset": 0, "out": 1,
                                   "extended": 1, "fields": "photo_50"]).execute(
            resultBlock: { response in
                guard let dict = response?.json as? Dictionary<String, Any> else {
                    return
                }
                guard let items = dict["items"] as? [Dictionary<String, Any>] else {
                    return
                }
                print("items: \(items)")
                let parsedItems = self.vkEntitiesToInternalEntities(items)
                let filtered = parsedItems.filter({e in !self.userIds.contains(e.userId)})
                self.userIds = self.userIds.union(filtered.map({user in user.userId}))
                print("parsed items: \(parsedItems)")
                self.getDataSource().addData(parsedItems)
                self.getTableView().reloadData()
        }, errorBlock:  { error in
            print("error: \(error)")
        })
    }
}

