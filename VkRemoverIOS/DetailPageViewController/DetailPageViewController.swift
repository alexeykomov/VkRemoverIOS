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
        
    }
    
    override func didReceiveMemoryWarning() {
        listeners.forEach {listener in listener()}
    }
    
    func onBan(user: RequestEntry, ban: Bool) {
        guard user.userId == requestEntry.userId else {
            return
        }
        updateBanLabel() 
    }
    
    func updateBanLabel() {
        let cell = self.tableView.cellForRow(at: IndexPath.init(row: 0, section: 1))
        guard let buttonCell = cell as? ButtonTableViewCell else {
            return
        }
        let isBanned = MainModel.shared().isBanned(user: requestEntry)
        buttonCell.buttonLabel.text = isBanned ? "Unban" : "Ban"
    }
    
    func onFriendsDelete(_ user: RequestEntry) {
        
    }

    @objc func addTapped() {
        dismiss(animated: true, completion: {})
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("requestEntry: \(requestEntry)")
        
        loadImage(aURL: requestEntry.photoForDetailedView, size: .detailed, onSuccess: { image in
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
            
            self.dataSource[0] = DetailPageItem(title: "", image: image)
        })
        
        let cell = self.tableView.cellForRow(at: IndexPath.init(row: 0, section: 0))
        guard let avatarCell = cell as? AvatarTableCell else {
            return
        }
        
        avatarCell.avatarImage.backgroundColor = .clear
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = self.tableView.cellForRow(at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (indexPath.section == 1 && indexPath.row == 0) {
            let isBanned = MainModel.shared().isBanned(user: requestEntry)
            MainModel.shared().ban(user: requestEntry, ban: !isBanned)
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
            let view = tableView.dequeueReusableCell(withIdentifier: "avatarCellIdentifier") as! AvatarTableCell
            
            view.avatarImage.layer.cornerRadius = view.avatarImage.frame.width / 2.0
            view.avatarImage.layer.masksToBounds = true
            if #available(iOS 13.0, *) {
                view.avatarImage.backgroundColor = .systemGray3
            } else {
                view.avatarImage.backgroundColor = UIColor.init(red: 198/255.0, green: 199/255.0, blue:203/255.0, alpha:1)
            }
            
            view.avatarImage.contentMode = .topLeft
            
            
            view.selectionStyle = .none
            
            guard let image = dataSource[indexPath.row].image else {
                return view
            }
            
            view.avatarImage.image = image
            
            view.userName.text = self.requestEntry.firstName + " " + self.requestEntry.lastName
            
            return view
        }
        
        if (indexPath.section == 1) {
            let view = tableView.dequeueReusableCell(withIdentifier: "buttonCellIdentifier") as! ButtonTableViewCell
            if (indexPath.row == 0) {
                let isBanned = MainModel.shared().isBanned(user: requestEntry)
                view.buttonLabel.text = isBanned ? "Unban" : "Ban"
            }
            if (indexPath.row == 1) {
                let isRequested = MainModel.shared().isRequested(user: requestEntry)
                view.buttonLabel.text = "Cancel Request"
                view.isHidden = !isRequested
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
