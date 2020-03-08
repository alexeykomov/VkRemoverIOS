//
//  AppDelegate.swift
//  VkRemoverIOS
//
//  Created by Alex K on 10/27/19.
//  Copyright © 2019 Alex K. All rights reserved.
//

import UIKit
import BackgroundTasks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var bgTaskPerformer: BGTaskPerformer

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        gScaleFactor.value = Double(UIScreen.main.scale)
        VKSdk.processOpen(url, fromApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as! String)
        return true
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("window?.contentScaleFactor: \(UIScreen.main.scale)")
        gScaleFactor.value = Double(UIScreen.main.scale)
        bgScheduler.start()
        bgTaskPerformer = BGTaskPerformer()
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier:
                "me.alexeykomov.VkRemoverIOS.refresh",
                                            using: nil)
            {task in
                self.bgTaskPerformer.handleAppRefresh(task as! BGAppRefreshTask)
            }
        } else {
            // Fallback on earlier versions
        }
        
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App did enter bg")
        requestScheduler.save()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("App will enter fg")
        requestScheduler.restore()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("App did become active")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("App will resign active")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("App will terminate")
    }
    
    
    // MARK: UISceneSession Lifecycle



}


