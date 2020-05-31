//
//  DetailPageViewController.swift
//  VkRemoverIOS
//
//  Created by Alex K on 5/2/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

class DetailPageViewController:UITableViewController {
    
    var requestEntry: RequestEntry = RequestEntry(userId: 0, photoForList: "", photoForDetailedView: "", firstName: "", lastName: "")
    var avatarImage:UIImage? = nil
    var imageHeight:CGFloat = 100.0
    var dataSource:[DetailPageItem] = [DetailPageItem(title: "", image: UIImage.init())]
    var listeners:[() -> Void] = []
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {
            return 1
        }
        return 2
        
    }
    
    override func viewDidLoad() {
        print("viewDidLoad")
        
        tableView.backgroundColor = UIColor(red: 241/255.0, green: 242/255.0, blue: 246/255.0, alpha: 1)
        
        title = "id" + String(requestEntry.userId)
        
        let insideModal = presentingViewController?.presentedViewController == self ||
            (navigationController != nil && navigationController?.presentingViewController?.presentedViewController == navigationController) ||
        tabBarController?.presentingViewController is UITabBarController
        print("insideModal: \(insideModal)")
        if (insideModal) {
            navigationItem.rightBarButtonItem = UIBarButtonItem.init(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(addTapped))
        }
        
        listeners.append(contentsOf: [
            MainModel.shared().addListener(opType: .accountBan, listener:
                { user in self.onBan(user: user, ban: true) } ),
            MainModel.shared().addListener(opType: .accountUnban, listener:
                { user in self.onBan(user: user, ban: false) } ),
            MainModel.shared().addListener(opType: .friendsDelete, listener: onFriendsDelete)
        ])
        
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
        
    }
    
    @objc func refreshData(_ sender: Any) {
        VKRequest.init(method: "users.get",
                       parameters:[
                        "user_ids": requestEntry.userId,
                        "fields": ["friend_status", "blacklisted_by_me",
                                   "photo_200_orig"]
                            .joined(separator: ",")
                        ]).execute(
        resultBlock: { response in
            guard let dicts = response?.json as? [Dictionary<String, Any>] else {
                return
            }
            var items = mapUserGetResponses(dicts)
            guard let user = items.popLast() else {
                return
            }
            guard let prevItem = self.dataSource.popLast() else {
                return
            }
            self.dataSource.append(
                DetailPageItem(title: "\(user.firstName) \(user.lastName)",
                                image: prevItem.image))
            self.loadAvatar(url: user.photo200Orig, onComplete: {
                self.refreshControl?.endRefreshing()
            })
        }, errorBlock: { error in
            self.refreshControl?.endRefreshing()
        })
    }
    
    override func didReceiveMemoryWarning() {
        listeners.forEach {listener in listener()}
    }
    
    func onBan(user: RequestEntry, ban: Bool) {
        guard user.userId == requestEntry.userId else {
            return
        }
        let cell = self.tableView.cellForRow(at: IndexPath.init(row: 0, section: 0))
        guard let buttonCell = cell as? ButtonTableViewCell else {
            return
        }
        updateBanLabel(buttonCell)
    }
    
    func onFriendsDelete(_ user: RequestEntry) {
        guard user.userId == requestEntry.userId else {
            return
        }
        let cell = self.tableView.cellForRow(at: IndexPath.init(row: 1, section: 0))
        guard let buttonCell = cell as? ButtonTableViewCell else {
            return
        }
        updateCancelLabel(buttonCell)
    }
    
    func updateBanLabel(_ buttonCell: ButtonTableViewCell) {
        let banned = MainModel.shared().isBanned(user: requestEntry)
        let unbanned = MainModel.shared().isBanned(user: requestEntry)
        buttonCell.buttonLabel.text = banned ? "Unban" : "Ban"
        
        let interactable = banned || unbanned
        buttonCell.isUserInteractionEnabled = interactable
        buttonCell.buttonLabel.isEnabled = interactable
    }
    
    func updateCancelLabel(_ buttonCell: ButtonTableViewCell) {
        let requested = MainModel.shared().isRequested(user: requestEntry)
        buttonCell.isUserInteractionEnabled = requested
        buttonCell.buttonLabel.isEnabled = requested
    }

    @objc func addTapped() {
        dismiss(animated: true, completion: {})
    }
    
    private func loadAvatar(url: String, onComplete: @escaping () -> Void) {
        loadImage(aURL: url, size: .detailed, onSuccess: { image in
            let cell = self.tableView.cellForRow(at: IndexPath.init(row: 0, section: 0))
            guard let avatarCell = cell as? AvatarTableCell else {
                return
            }
            
            if #available(iOS 13.0, *) {
                avatarCell.avatarImage.backgroundColor = .systemGray3
            } else {
                avatarCell.avatarImage.backgroundColor = .lightGray
            }
            
            avatarCell.avatarImage.image = image
            print("image.size: \(image.size)")
            guard let prevItem = self.dataSource.popLast() else {
                return
            }
            self.dataSource.append(DetailPageItem(title: prevItem.title, image: image))
            onComplete()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("requestEntry: \(requestEntry)")
        
        loadAvatar(url: requestEntry.photoForDetailedView, onComplete: {})
        
        let cell = self.tableView.cellForRow(at: IndexPath.init(row: 0, section: 0))
        guard let avatarCell = cell as? AvatarTableCell else {
            return
        }
        
        avatarCell.avatarImage.backgroundColor = .clear
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (indexPath.section == 1 && indexPath.row == 0) {
            let isBanned = MainModel.shared().isBanned(user: requestEntry)
            if (isBanned) {
                MainModel.shared().ban(user: requestEntry)
            } else {
                MainModel.shared().unban(user: requestEntry)
            }
        }
        if (indexPath.section == 1 && indexPath.row == 1) {
            let isRequested = MainModel.shared().isRequested(user: requestEntry)
            if (isRequested) {
                MainModel.shared().cancelRequest(user: requestEntry)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row == 0 && indexPath.section == 0) {
            let avatarCell = tableView.dequeueReusableCell(withIdentifier: "avatarCellIdentifier") as! AvatarTableCell
            avatarCell.avatarImage.layer.cornerRadius = avatarCell.avatarImage.frame.width / 2.0
            avatarCell.avatarImage.layer.masksToBounds = true
            if #available(iOS 13.0, *) {
                avatarCell.avatarImage.backgroundColor = .systemGray3
            } else {
                avatarCell.avatarImage.backgroundColor = UIColor.init(red: 198/255.0, green: 199/255.0, blue:203/255.0, alpha:1)
            }
            
            avatarCell.avatarImage.contentMode = .topLeft
            
            avatarCell.selectionStyle = .none
            guard let image = dataSource[indexPath.row].image else {
                return avatarCell
            }
            avatarCell.avatarImage.image = image
            avatarCell.userName.text = self.requestEntry.firstName + " " + self.requestEntry.lastName
            return avatarCell
        }
        
        if (indexPath.section == 1) {
            let view = tableView.dequeueReusableCell(withIdentifier: "buttonCellIdentifier") as! ButtonTableViewCell
            if (indexPath.row == 0) {
                updateBanLabel(view)
            }
            if (indexPath.row == 1) {
                view.buttonLabel.text = "Cancel Request"
                updateCancelLabel(view)
            }
            return view
        }
        return UITableViewCell()
    }
}

struct ButtonEntry {
    let title: String
}

struct DetailPageItem {
    let title: String
    let image: UIImage?
}
