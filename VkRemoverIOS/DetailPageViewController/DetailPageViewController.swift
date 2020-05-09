//
//  DetailPageViewController.swift
//  VkRemoverIOS
//
//  Created by Alex K on 5/2/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

class DetailPageViewController:UITableViewController {
    
    var requestEntry: RequestEntry = RequestEntry(userId: 0, photoForList: "", firstName: "", lastName: "")
    var avatarImage:UIImage? = nil
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
        
    }
    override func viewDidLoad() {
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.sectionHeaderHeight = 20
        
        tableView.backgroundColor = UIColor(red: 241/255.0, green: 242/255.0, blue: 246/255.0, alpha: 1)
        
        title = "id" + String(requestEntry.userId)
        
        parent?.navigationItem.rightBarButtonItem?.title = "Done"
        
        //tableView.register(AvatarTableCell.self, forCellReuseIdentifier: "avatarCellIdentifier")
        //tableView.register(ButtonCell.self, forCellReuseIdentifier: "buttonCellIdentifier")
        
    }

    
    override func viewWillAppear(_ animated: Bool) {
        print(requestEntry)
        loadImage(aURL: requestEntry.photoForList, size: .detailed, onSuccess: { image in
            self.avatarImage = image
            let cell = self.tableView.cellForRow(at: IndexPath.init(row: 1, section: 0))
            let avatarCell = cell as? AvatarTableCell
            avatarCell?.avatarImage.image = image
            avatarCell?.reloadInputViews()
        })
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.row == 1) {
            return 300
        }
        if (indexPath.row == 0 || indexPath.row == 2) {
            return 35
        }
        return 44
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath.row == 0 || indexPath.row == 2) {
            let view = tableView.dequeueReusableCell(withIdentifier: "spacerCellIdentifier") as! SpacerTableCell
            view.backgroundColor = UIColor(red: 241/255.0, green: 242/255.0, blue: 246/255.0, alpha: 1)
            view.selectionStyle = .none
            return view
        }
        
        
        if (indexPath.row == 1) {
            let view = tableView.dequeueReusableCell(withIdentifier: "avatarCellIdentifier") as! AvatarTableCell
            
            view.avatarImage.layer.cornerRadius = view.avatarImage.frame.width / 2.0
            view.avatarImage.backgroundColor = .gray
            view.selectionStyle = .none
            
            guard let avatarImage = self.avatarImage else {
                return view
            }
            print("avatarImage: \(avatarImage)")
            view.avatarImage.image = avatarImage
            return view
        }
        
        let view = tableView.dequeueReusableCell(withIdentifier: "buttonCellIdentifier") as! ButtonTableCell
        view.selectionStyle = .default
        if (indexPath.row == 3) {
            view.actionLabel.text = "Ban"
        }
        if (indexPath.row == 4) {
            view.actionLabel.text = "Cancel Request"
        }
        return view
    }
}

struct ButtonEntry {
    let title: String
}
