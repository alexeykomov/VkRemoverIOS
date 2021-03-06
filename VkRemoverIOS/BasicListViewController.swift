//
//  BasicListViewController.swift
//  VkRemoverIOS
//
//  Created by Alex K on 1/11/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation
import SDWebImage

class BasicListViewController: UIViewController, VKSdkUIDelegate, VKSdkDelegate, UITableViewDelegate {
    private let dataSource = RequestsTableDataSource()
    private var userIds = Set<Int>()
    var deleting = false
    func setDeleting(_ deleting: Bool) { self.deleting = deleting }
    func getDeleting() -> Bool { return deleting }
    let refreshControl = UIRefreshControl()
    
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
        if deleting && getDataSource().getData().isEmpty {
            return
        }
        if deleting {
            requestScheduler.scheduleOps(operationType: getOperationType(),
                ops: getDataSource().getData().map({d in
                    print("user: \(d.userId) \(d.firstName) \(d.lastName)")
                    
                    return Operation(
                    name: getOperationType(),
                    paramName: getParamName(),
                    user: d)})
                )
        } else {
            requestScheduler.clearOps(operationType: getOperationType())
        }
        self.setDeleting(deleting)
        updateButton()
    }
    
    func updateButton() {
        getDeleteAllButton().setTitle(getDeleting() ? "Stop deleting" : "Delete All", for: .normal)
    }

    func didDeleteUserSuccess(user: RequestEntry) {
    }
 
    func didDeleteUserFailure(user: RequestEntry) {
    }
    
    func didDeleteUserSuccess(users: [RequestEntry]) {
    }
    
    func didDeleteUserFailure(users: [RequestEntry]) {
    }
    
    func removeFromDataAndTable(user: RequestEntry) {
        let userId = user.userId
        guard let indexToDelete = self.getDataSource().getData().firstIndex(where: {r in r.userId == userId}) else {
            print("Cannont find index in data for userId: \(userId)")
            return
        }
        getDataSource().remove(at: indexToDelete)
        userIds.remove(userId)
        self.getTableView().deleteRows(at: [IndexPath(row: indexToDelete, section: 0)],
                             with: UITableView.RowAnimation.automatic)
        if self.getDataSource().getData().isEmpty {
            updateDeletionProcess(deleting: false)
        }
    }
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let splitViewControllerParent = self.parent?.parent as? UISplitViewController
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "detailPageNavigationController") as! UINavigationController
        guard let first = vc.children.first else {
            return
        }
        guard let detailPageViewController = first as? DetailPageViewController else {
            return
        }
        detailPageViewController.requestEntry = self.getDataSource().getData()[indexPath.row]
        splitViewControllerParent?.showDetailViewController(vc, sender: nil)
    }
    
    func removeFromDataAndTable(users: [RequestEntry]) {
        let indicesToDelete:[(Int, Int)] = users.reduce([], { res, user in
            let userId = user.userId
            guard let indexToDelete = self.getDataSource().getData()
                .firstIndex(where: {r in r.userId == userId}) else {
               print("Cannont find index in data for userId: \(userId)")
               return res
            }
            return res + [(indexToDelete, userId)]
        })
        print("Indexes to delete: \(indicesToDelete)")
        let sortedIndicesToDelete = indicesToDelete.sorted(by: { indexUserIdPairA, indexUserIdPairB in
                indexUserIdPairA.0 > indexUserIdPairB.0
            })
        print("Sorted indexes to delete: \(sortedIndicesToDelete)")
        sortedIndicesToDelete.forEach { indexUserIdPair in
            getDataSource().remove(at: indexUserIdPair.0)
            userIds.remove(indexUserIdPair.1)
        }
        self.getTableView().deleteRows(at:
        indicesToDelete.map { indexUserIdPair in
            IndexPath(row: indexUserIdPair.0, section: 0)},
                                   with: UITableView.RowAnimation.none)
        
        if self.getDataSource().getData().isEmpty {
            updateDeletionProcess(deleting: false)
        }
    }
    
    func vkSdkAccessAuthorizationFinished(with result: VKAuthorizationResult!) {
        if (result.token != nil) {
            self.startWorking()
        } else if ((result.error) != nil) {
            self.showAlert(title: "", message: "Access denied \(result.error)")
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert =  UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title:
            NSLocalizedString("OK", comment: "Default action"),
                                      style: .default,
                                      handler: { _ in
                                        NSLog("The \"OK\" alert occured.")
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func vkSdkUserAuthorizationFailed() {
        self.showAlert(title: "", message: "Sdk user authorization failed")
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
    
    @objc private func refreshData(_ sender: Any) {
        startWorking()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if #available(iOS 10.0, *) {
            getTableView()?.refreshControl = refreshControl
        } else {
            getTableView().addSubview(refreshControl)
        }
        getTableView().delegate = self;
        refreshControl.addTarget(self, action: #selector(refreshData(_:)),
                                 for: .valueChanged)
        
        deleting = !requestScheduler.isEmpty(operationType: getOperationType())
        updateButton()
        requestScheduler.addCallbacks(operationType: getOperationType(),
                                         successCb: {user, r in
                                             self.removeFromDataAndTable(user: user)
                                             self.didDeleteUserSuccess(user: user)
                                             },
                                         errorCb: {user, e, enabledDeletion in
                                             if enabledDeletion {
                                                 self.removeFromDataAndTable(user: user)
                                                 self.didDeleteUserFailure(user: user)
                                            }})
        BGTaskPerformer.shared().addCallbacks(operationType: getOperationType(),
                                              successCb: {users, r in
                                                self.removeFromDataAndTable(users: users)
                                                self.didDeleteUserSuccess(users: users)
        },
                                              errorCb:{users, r in
                                                self.removeFromDataAndTable(users: users)
                                                self.didDeleteUserSuccess(users: users)
        })
        setupVkData()
    }
    
    func setupVkData() {
        let SCOPE = [VK_PER_FRIENDS];
           
        let instance = VKSdk.initialize(withAppId: "7144627")
        instance?.uiDelegate = self
        instance?.register(self)
        VKSdk.wakeUpSession(SCOPE, complete: {state, error in
            if (state == VKAuthorizationState.authorized) {
                self.startWorking()
            } else if (error != nil) {
                self.showAlert(title: "", message: error.debugDescription)
            }
        })
        VKSdk.authorize(SCOPE)
        getTableView().dataSource = getDataSource()
    }
    
    func vkEntitiesToInternalEntities(_ items: [Dictionary<String, Any>]) ->
            [RequestEntry] {
        return []
    }
    
    func startWorking() {
        var photoParamName:[String] = []
        switch gScaleFactor.value {
        case 1.0:photoParamName.append("photo_50")
                photoParamName.append("photo_100")
        case 1.0...3.0:photoParamName.append("photo_100")
            photoParamName.append("photo_200_orig")
        default: break
        }
        print("photoParamName: \(photoParamName)")
        let requestParams: [String:Any] = ["count":1000, "offset": 0, "out": 1,
                                           "extended": 1, "fields": photoParamName.joined(separator: ",")]
        
        VKRequest.init(method: getVKMethodName(),
                       parameters:requestParams).execute(
            resultBlock: { response in
                guard let dict = response?.json as? Dictionary<String, Any> else {
                    return
                }
                guard let items = dict["items"] as? [Dictionary<String, Any>] else {
                    return
                }
                print("items: \(items)")
                let parsedItems = self.vkEntitiesToInternalEntities(items)
                print("userIds: \(self.userIds)")
                let filtered = parsedItems.filter({e in !self.userIds.contains(e.userId)})
                self.userIds = self.userIds.union(filtered.map({user in user.userId}))
                print("parsed items: \(parsedItems)")
                self.getDataSource().addData(filtered)
                self.getTableView().reloadData()
                if self.deleting {
                    self.updateDeletionProcess(deleting: true)
                }
                self.refreshControl.endRefreshing()
        }, errorBlock:  { error in
            print("error: \(error)")
            self.refreshControl.endRefreshing()
        })
    }
}

