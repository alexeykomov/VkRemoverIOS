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

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        gScaleFactor.value = Double(UIScreen.main.scale)
        VKSdk.processOpen(url, fromApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as! String)
        return true
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions:
        [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("window?.contentScaleFactor: \(UIScreen.main.scale)")
        gScaleFactor.value = Double(UIScreen.main.scale)
        unBanScheduler.start()  
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier:
                "me.alexeykomov.VkRemoverIOS.refresh",
                                            using: nil)
            {task in
                BGTaskPerformer.shared().handleAppRefresh(task as!
                    BGAppRefreshTask)
            }
            #if DEBUG
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + 2, execute: {
                // TODO(alexk): This is just to have store to restore for debug.
                //requestScheduler.save()
                //BGTaskPerformer.shared().scheduleAppRefresh()
            })
            #endif
        } else {
            // Fallback on earlier versions
            UIApplication.shared.setMinimumBackgroundFetchInterval(0)
        }
        
        return true
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NSLog("")
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


