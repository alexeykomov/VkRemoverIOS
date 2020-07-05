//
//  HelloScreenViewController.swift
//  VkRemoverIOS
//
//  Created by Alex K on 4/25/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

class HelloScreenViewController: UIViewController {
    
    var authorizeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authorizeButton = UIButton()
        authorizeButton.setTitle("Authorize with VK", for: .normal)
        authorizeButton.backgroundColor = UIColor(red: 70, green: 128, blue: 194, alpha: 0)
        authorizeButton.tintColor = UIColor.white
        
        authorizeButton.layer.cornerRadius = 2
        authorizeButton.layer.masksToBounds = true
        
        authorizeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            authorizeButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            authorizeButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
        ])
        
        authorizeButton.addTarget(self, action: #selector(onAuthorizeButtonAction), for: .touchUpInside)
    }
    
    @objc func onAuthorizeButtonAction(_ sender: Any) {
        
    }
}
