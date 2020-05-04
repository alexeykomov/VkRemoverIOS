//
//  DetailPageViewController.swift
//  VkRemoverIOS
//
//  Created by Alex K on 5/2/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

class DetailPageViewController:UIViewController {
    
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var banButton: UIButton!
    @IBOutlet weak var cancelRequestButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "User"
        
        avatarImage.backgroundColor = UIColor.systemGray
        avatarImage.layer.cornerRadius = 20
        avatarImage.layer.masksToBounds = true
    }
    
}
