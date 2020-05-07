//
//  DetailPageViewController.swift
//  VkRemoverIOS
//
//  Created by Alex K on 5/2/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

class DetailPageViewController:UIViewController, UITableViewDataSource {
    var data:[ButtonEntry] = [
        ButtonEntry(title: "Ban"), ButtonEntry(title: "Cancel request")
    ]
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "buttonCellIdentifier") as! ButtonCell
        
        cell.button.setTitle("Ban", for: .normal)
        
        return cell
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var banButton: UIButton!
    @IBOutlet weak var cancelRequestButton: UIButton!
    @IBOutlet weak var table: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "User"
        
        if #available(iOS 13.0, *) {
            avatarImage.backgroundColor = UIColor.systemGray3
        } else {
            avatarImage.backgroundColor = UIColor.init(red: 192/255.0,
                                                       green: 199/255.0,
                                                       blue: 203/255.0,
                                                       alpha: 0)
        }
        avatarImage.layer.cornerRadius = avatarImage.layer.frame.width / 2.0
        avatarImage.layer.masksToBounds = true

        banButton.layer.borderWidth = 1
        if #available(iOS 13.0, *) {
            banButton.layer.borderColor = UIColor.systemGray3.cgColor
        } else {
            banButton.layer.borderColor = UIColor.init(red: 192/255.0,
                                                       green: 199/255.0,
                                                       blue: 203/255.0,
                                                       alpha: 0).cgColor
        }
        
        
    }
    
}

struct ButtonEntry {
    let title: String
}
