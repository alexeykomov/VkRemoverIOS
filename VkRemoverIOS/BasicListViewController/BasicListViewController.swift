//
//  BasicListViewController.swift
//  VkRemoverIOS
//
//  Created by Alex K on 1/11/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation
import SDWebImage

class BasicListViewController: UITableViewController, SDWebImageManagerDelegate {
    
    var deleting = false
    var category:UserCategory
    func setDeleting(_ deleting: Bool) { self.deleting = deleting }
    func getDeleting() -> Bool { return deleting }
    var listeners:[() -> Void] = []
    
    var data:[RequestEntry] {
        get {
             return MainModel.shared().entries[category] ?? []
        }
    }
    
    init(category: UserCategory) {
        self.category = category
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var imageManager = SDWebImageManager()
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier") as! RequestTableCell
        let userData = data[indexPath.row]
        cell.userName.text = userData.getLabel()
        
        cell.avatarImg.layer.borderWidth = 0
        cell.avatarImg.layer.masksToBounds = false
        cell.avatarImg.layer.borderColor = UIColor.white.cgColor
        cell.avatarImg.layer.cornerRadius = cell.avatarImg.frame.height / 2
        cell.avatarImg.clipsToBounds = true
        
        cell.loadImage(url: userData.photoForList)
        return cell
    }
    
    func getDeleteAllButton() -> UIBarButtonItem! {
        return self.navigationController?.navigationItem.leftBarButtonItem
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
        if deleting && data.isEmpty {
            return
        }
        if deleting {
            requestScheduler.scheduleOps(operationType: .friendsDelete,
                ops: data.map({d in
                    print("user: \(d.userId) \(d.firstName) \(d.lastName)")
                    return createOperationFriendsDelete(user: d)
                }))
        } else {
            requestScheduler.clearOps(operationType:
                mapUserCategoryToLoadRequestType(category: self.category))
        }
        self.setDeleting(deleting)
        updateButton()
    }
    
    func updateButton() {
        getDeleteAllButton().title = getDeleting() ? "Stop deleting" : "Delete All"
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
        guard let indexToDelete = data.firstIndex(where: {r in r.userId == userId}) else {
            print("Cannont find index in data for userId: \(userId)")
            return
        }
        self.getTableView().deleteRows(at: [IndexPath(row: indexToDelete, section: 0)],
                             with: UITableView.RowAnimation.automatic)
        if data.isEmpty {
            updateDeletionProcess(deleting: false)
        }
    }
    
    func removeFromDataAndTable(indicesToDelete: [(Int, Int)]) {
        self.getTableView().deleteRows(at:
            indicesToDelete.map { indexUserIdPair in
                IndexPath(row: indexUserIdPair.0, section: 0)},
                                       with: UITableView.RowAnimation.none)
        if data.isEmpty {
            updateDeletionProcess(deleting: false)
        }
    }
        
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let splitViewControllerParent = self.parent?.parent as? UISplitViewController
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "detailPageNavigationController") as! UINavigationController
        guard let first = vc.children.first else {
            return
        }
        guard let detailPageViewController = first as? DetailPageViewController else {
            return
        }
        detailPageViewController.requestEntry = data[indexPath.row]
        splitViewControllerParent?.showDetailViewController(vc, sender: nil)
    }
    
    @objc private func refreshData(_ sender: Any) {
        guard let loadRequestType = mapUserCategoryToLoadRequestType(category: category) else {
            return
        }
        guard let loadOperation = mapUserCategoryToLoadOperation(category: category) else {
            return
        }
        requestScheduler.scheduleOps(
            operationType: loadRequestType,
            ops: [loadOperation])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imageManager.delegate = self
        self.refreshControl = UIRefreshControl()
        guard let refreshControl = self.refreshControl else {
            return
        }
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        refreshControl.addTarget(self, action: #selector(refreshData(_:)),
                                 for: .valueChanged)
        deleting = !requestScheduler.isEmpty(operationType: .friendsDelete)
        updateButton()
         
        // NOTE: Listeners.
        subscribeToEvents()
    }
    
    func subscribeToEvents() {
        listeners.append(contentsOf: [
            MainModel.shared().addListener(
                type: mapUserCategoryToBulkLoadModelEventType(category: self.category),
                listener: {event in
                    guard let usersAndCategory = event as? UsersAndCategory else {
                        return
                    }
                    guard usersAndCategory.category == self.category else {
                        return
                    }
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
            }),
            MainModel.shared().addListener(type: .removeFromEntries, listener: {event in
                guard let userAndCategory = event as? UserAndCategory else {
                    return
                }
                guard userAndCategory.category == self.category else {
                    return
                }
                self.removeFromDataAndTable(user: userAndCategory.user)
            }),
            MainModel.shared().addListener(type: .removeFromEntriesBulk, listener: {event in
                guard let indicesToDeleteForCategory = event as? IndicesToDeleteForCategory else {
                    return
                }
                guard indicesToDeleteForCategory.category == self.category else {
                    return
                }
                self.removeFromDataAndTable(indicesToDelete: indicesToDeleteForCategory.indices)
            }),
            requestScheduler.addCallbacks(
                operationType: .friendsDelete,
                successCb: {user, response  in
                    MainModel.shared().removeFromEntries(user: user, category: self.category)
            },
                errorCb: {
                    user, error, deleteEnabled in
                    if (deleteEnabled) {
                        MainModel.shared().removeFromEntries(user: user, category: self.category)
                    }
            })
        ])
    }
    
    override func didReceiveMemoryWarning() {
        while (!listeners.isEmpty) {
            guard let unsubscriber = listeners.popLast() else {
                continue
            }
            unsubscriber()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (listeners.isEmpty) {
            subscribeToEvents()
        }
    }
}

