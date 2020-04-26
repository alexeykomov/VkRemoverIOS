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
    let bgTaskPerformer: BGTaskPerformer = BGTaskPerformer()
    
    @available(iOS 13.0, *)
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        NSLog("scene")
    }
    
    @available(iOS 13.0, *)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        var contexts = URLContexts.map {c in c}
        guard let context = contexts.popLast() else {
            return
        }
        let url = context.url
        let app = context.options.sourceApplication
        print("Url: \(url)")
        print("App: \(app)")
        VKSdk.processOpen(url, fromApplication: app)
        NSLog("scene openURLContexts: %@", URLContexts)
    }
    
    @available(iOS 13.0, *)
    func sceneWillResignActive(_ scene: UIScene) {
        print("Scene will resign active")
        requestScheduler.save()
        //BGTaskPerformer.shared().scheduleAppRefresh()
    }
    
    @available(iOS 13.0, *)
    func sceneWillEnterForeground(_ scene: UIScene) {
        if (VKSdk.initialized()) {
            requestScheduler.restore()
        }
        print("Scene will enter foreground")
    }
}

