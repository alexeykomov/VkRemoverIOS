//
//  MainViewController.swift
//  VkRemoverIOS
//
//  Created by Alex K on 5/4/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation
import UIKit

class MainViewController:UISplitViewController, VKSdkUIDelegate, VKSdkDelegate {
    var callbacks:[()->Void] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredDisplayMode = .allVisible
        
        // Tabs.
        let tabsController = UITabBarController()
        
        let requestsViewController = BasicListViewController(category: .friendRequest);
        requestsViewController.title = "Requests";
        let requestsViewControllerWithNavigation = UINavigationController(rootViewController: requestsViewController);
        var requestsTabBarImage:UIImage? = UIImage()
        if #available(iOS 13.0, *) {
            requestsTabBarImage = UIImage(systemName: "arrow.up.circle.fill")
        } else {
            requestsTabBarImage = UIImage(named: "", in: nil, compatibleWith: .none)
        }
        let requestsTabBarItem = UITabBarItem(title: "", image: requestsTabBarImage, tag: 1)
        requestsViewControllerWithNavigation.tabBarItem = requestsTabBarItem;
        
        let followersViewController = BasicListViewController(category: .follower);
        followersViewController.title = "Followers";
        let followersViewControllerWithNavigation = UINavigationController(rootViewController: followersViewController);
        var followersTabBarImage:UIImage? = UIImage()
        if #available(iOS 13.0, *) {
            followersTabBarImage = UIImage(systemName: "arrow.down.circle.fill")
        } else {
            requestsTabBarImage = UIImage(named: "", in: nil, compatibleWith: .none)
        }
        let followersTabBarItem = UITabBarItem(title: "", image: followersTabBarImage, tag: 1)
        followersViewControllerWithNavigation.tabBarItem = followersTabBarItem;
        
        let bannedViewController = BasicListViewController(category: .bannedUser);
        bannedViewController.title = "Banned";
        let bannedViewControllerWithNavigation = UINavigationController(rootViewController: bannedViewController);
        var bannedTabBarImage:UIImage? = UIImage()
        if #available(iOS 13.0, *) {
            bannedTabBarImage = UIImage(systemName: "person.crop.circle.badge.xmark")
        } else {
            bannedTabBarImage = UIImage(named: "", in: nil, compatibleWith: .none)
        }
        let bannedTabBarItem = UITabBarItem(title: "", image: bannedTabBarImage, tag: 2)
        bannedViewControllerWithNavigation.tabBarItem = bannedTabBarItem;
        
        tabsController.viewControllers = [requestsViewControllerWithNavigation,
                                followersViewControllerWithNavigation,
                                bannedViewControllerWithNavigation];
        
        tabsController.selectedIndex = 0;
    
        // Detail page.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let detailPageViewController = storyboard.instantiateViewController(withIdentifier: "detailPageNavigationController") as! UINavigationController
        
        viewControllers = [tabsController, detailPageViewController]
        
        // Get data.
        subscribeToEvents()
        setupVkData()
    }
    
    func subscribeToEvents() {
        callbacks.append(
            requestScheduler.addCallbacks(operationType: .friendsGetRequests,
                                          successCb: {user, response in
                                            guard let dict = response?.json as? Dictionary<String, Any> else {
                                                return
                                            }
                                            guard let items = dict["items"] as? [Dictionary<String, Any>] else {
                                                return
                                            }
                                            print("items: \(items)")
                                            let parsedItems = RequestEntry.fromRequestsList(items)
                                            MainModel.shared().bulkLoad(users: parsedItems, entry: .friendRequest)
            },
                                          errorCb: {user, e, enabledDeletion in}
        ))
        callbacks.append(
            requestScheduler.addCallbacks(operationType: .userGetFollowers,
                                          successCb: {user, response in
                                            guard let dict = response?.json as? Dictionary<String, Any> else {
                                                return
                                            }
                                            guard let items = dict["items"] as? [Dictionary<String, Any>] else {
                                                return
                                            }
                                            print("items: \(items)")
                                            let parsedItems = RequestEntry.fromRequestsList(items)
                                            MainModel.shared().bulkLoad(users: parsedItems, entry: .follower)
            },
                                          errorCb: {user, e, enabledDeletion in}
        ))
        MainModel.shared().bulkLoad(users:
            Storage.shared.getBanned().map {u in u.user}, entry: .bannedUser)
        
        BGTaskPerformer.shared().addCallbacks(operationType: .friendsGetRequests,
                                              successCb: {users, r in },
                                              errorCb:{users, r in })
        BGTaskPerformer.shared().addCallbacks(operationType: .userGetFollowers,
                                              successCb: {users, r in },
                                              errorCb:{users, r in })
    }
    
    override func didReceiveMemoryWarning() {
        while (!callbacks.isEmpty) {
            guard let unsubscriber = callbacks.popLast() else {
                continue
            }
            unsubscriber()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (callbacks.isEmpty) {
            subscribeToEvents()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
    
    func setupVkData() {
        let SCOPE = [VK_PER_FRIENDS];
           
        let instance = VKSdk.initialize(withAppId: "7144627")
        instance?.uiDelegate = self
        instance?.register(self)
        VKSdk.wakeUpSession(SCOPE, complete: {state, error in
            if (state == VKAuthorizationState.authorized) {
                self.startWorking()
            } else if (error != nil) {
                self.showAlert(title: "", message: error.debugDescription)
            }
        })
        VKSdk.authorize(SCOPE)
    }
    
    func vkSdkAccessAuthorizationFinished(with result: VKAuthorizationResult!) {
        if (result.token != nil) {
            self.startWorking()
        } else if ((result.error) != nil) {
            self.showAlert(title: "", message: "Access denied \(result.error)")
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert =  UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title:
            NSLocalizedString("OK", comment: "Default action"),
                                      style: .default,
                                      handler: { _ in
                                        NSLog("The \"OK\" alert occured.")
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func vkSdkUserAuthorizationFailed() {
        self.showAlert(title: "", message: "Sdk user authorization failed")
        navigationController?.popToRootViewController(animated: true)
    }
    
    func vkSdkShouldPresent(_ controller: UIViewController!) {
        self.navigationController?.topViewController?.present(controller,
                                                              animated: true,
                                                              completion: {})
    }
    
    func vkSdkNeedCaptchaEnter(_ captchaError: VKError!) {
        let vc = VKCaptchaViewController.captchaControllerWithError(captchaError)
        vc?.present(in: self.navigationController?.topViewController)
    }
    
    func startWorking() {
        requestScheduler.scheduleOps(operationType: .friendsGetRequests,
                                     ops: [createOperationFriendsGetRequests()])
        requestScheduler.scheduleOps(operationType: .userGetFollowers,
                                     ops: [createOperationUserGetFollowers()])
    }
}
