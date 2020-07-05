//
//  RootViewController.swift
//  VkRemoverIOS
//
//  Created by Alex K on 7/3/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {
    var current:UIViewController? = nil
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.current = HelloScreenViewController()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let current = self.current else {
            print("No initial controller.")
            return
        }
        
        self.addChild(current)
        current.view.frame = self.view.bounds
        self.view.addSubview(current.view)
        current.didMove(toParent: self)
    }

    func showHelloScreenViewController() {
        let startViewController = HelloScreenViewController()
        self.addChild(startViewController)
        startViewController.view.frame = self.view.bounds
        self.view.addSubview(startViewController.view)
        startViewController.didMove(toParent: self)
        
        guard let current = self.current else {
            print("No initial controller.")
            return
        }
        
        current.willMove(toParent: nil)
        current.view.removeFromSuperview()
        current.removeFromParent()
        
        self.current = startViewController
    }

    func showMainViewController() {
        let mainController = MainViewController()
        self.addChild(mainController)
        mainController.view.frame = self.view.bounds
        self.view.addSubview(mainController.view)
        mainController.didMove(toParent: self)
        
        guard let current = self.current else {
            print("No initial controller.")
            return
        }
        
        current.willMove(toParent: nil)
        current.view.removeFromSuperview()
        current.removeFromParent()
        
        self.current = mainController
    }
        
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
