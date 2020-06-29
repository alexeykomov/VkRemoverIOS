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
    
    override init(style: UITableView.Style) {
        super.init(style: style)
        let refreshControl = UIRefreshControl()
        imageManager.delegate = self
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        let refreshControl = UIRefreshControl()
        imageManager.delegate = self
    }
    
    init(category: UserCategory) {
        self.category = category
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
    
    func addData(_ items: [RequestEntry]) {
        data.append(contentsOf: items)
    }
    
    func getData() -> [RequestEntry] {
        return data
    }
    
    func remove(at: Int) -> Void {
         data.remove(at: at)
    }
    
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
            requestScheduler.scheduleOps(operationType: .friendsDelete,
                ops: data.map({d in
                    print("user: \(d.userId) \(d.firstName) \(d.lastName)")
                    return createOperationFriendsDelete(user: d)
                }))
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
        self.getTableView().deleteRows(at: [IndexPath(row: indexToDelete, section: 0)],
                             with: UITableView.RowAnimation.automatic)
        if self.getDataSource().getData().isEmpty {
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
        detailPageViewController.requestEntry = self.getDataSource().getData()[indexPath.row]
        splitViewControllerParent?.showDetailViewController(vc, sender: nil)
    }
    
    func removeFromDataAndTable(users: [RequestEntry]) {
        let indicesToDelete:[(Int, Int)] = users.reduce([], { res, user in
            let userId = user.userId
            guard let indexToDelete = self.data
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
    
    
    @objc private func refreshData(_ sender: Any) {
        requestScheduler.scheduleOps(operationType: .friendsGetRequests, ops: [createOperationFriendsGetRequests()])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        refreshControl.addTarget(self, action: #selector(refreshData(_:)),
                                 for: .valueChanged)
        deleting = !requestScheduler.isEmpty(operationType: .friendsDelete)
        updateButton()
         
        listeners.append(contentsOf: [
            MainModel.shared().addListener(type: .bulkLoadRequests, listener: {_ in
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }),
            MainModel.shared().addListener(type: .removeFriendRequest, listener: {_ in
                
            }),
            MainModel.shared().addListener(type: .removeFromEntries, listener: {_ in
                
            }),
            requestScheduler.addCallbacks(
                operationType: .friendsDelete,
                successCb: {user, response  in
                    self.removeFromDataAndTable(user: user)
            },
                errorCb: {
                user,eror,deleteEnabled  in
                if (deleteEnabled) {
                    self.removeFromDataAndTable(user: user)
                }
                
            })
        ])
        
    }
}

