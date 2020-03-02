//
//  SceneDelegate.swift
//  VkRemoverIOS
//
//  Created by Alex K on 10/27/19.
//  Copyright © 2019 Alex K. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    @available(iOS 13.0, *)
    func sceneWillResignActive(_ scene: UIScene) {
        print("Scene will resign active")
    }
    
    @available(iOS 13.0, *)
    func sceneWillEnterForeground(_ scene: UIScene) {
        print("Scene will enter foreground")
    }
}

