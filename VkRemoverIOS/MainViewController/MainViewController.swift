//
//  MainViewController.swift
//  VkRemoverIOS
//
//  Created by Alex K on 5/4/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

class MainViewController:UISplitViewController, VKSdkUIDelegate, VKSdkDelegate {
    var callbacks:[()->Void] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredDisplayMode = .allVisible
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
