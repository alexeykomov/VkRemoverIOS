//
//  HelloScreenViewController.swift
//  VkRemoverIOS
//
//  Created by Alex K on 4/25/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

class HelloScreenViewController: UIViewController {
    
    @IBAction func onAuthorizeButtonAction(_ sender: Any) {
        
    }
    @IBOutlet weak var authorizeButton: UIButton!
    
    override func viewDidLoad() {
    super.viewDidLoad()
        authorizeButton.layer.cornerRadius = 2
        authorizeButton.layer.masksToBounds = true
    }
}
