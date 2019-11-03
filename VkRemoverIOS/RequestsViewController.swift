//
//  ViewController.swift
//  VkRemoverIOS
//
//  Created by Alex K on 10/27/19.
//  Copyright © 2019 Alex K. All rights reserved.
//

import UIKit

class ViewController: UIViewController, VKSdkUIDelegate, VKSdkDelegate {
    @IBOutlet weak var tableView: UITableView!
    private let dataSource = RequestsTabeDataSource()
    @IBOutlet weak var deleteAllButton: UIButton!
    private var requestsTimer: Timer?
    
    @IBAction func deleteAllAction(_ sender: Any) {
        requestsTimer?.invalidate()
        requestsTimer = Timer.scheduledTimer(timeInterval: 1, target: self,
                                             selector: #selector(onTick),
                                             userInfo: nil, repeats: true)
    }
    
    @objc func onTick() {
        if dataSource.getData().isEmpty {
            requestsTimer?.invalidate()
            return
        }
        let first = dataSource.getData()[0]
        
        print("first: \(first)")
        
        VKRequest.init(method:"friends.delete",
                       parameters:["user_id":first.userId]).execute(
            resultBlock: { response in
                print("response: \(response)")
                self.removeFromDataAndTable(entry: first)
        }, errorBlock:  { error in
            print("error: \(error)")
            self.removeFromDataAndTable(entry: first)
        })
    }

    func removeFromDataAndTable(entry: RequestEntry) {
        guard let indexToDelete = self.dataSource.getData().firstIndex(where: {r in r.userId == entry.userId}) else {
            print("Cannont find index in data for userId: \(entry.userId)")
            return
        }
        dataSource.remove(at: indexToDelete)
        self.tableView.deleteRows(at: [IndexPath(row: indexToDelete, section: 0)],
                             with: UITableView.RowAnimation.automatic)
    }
    
    func vkSdkAccessAuthorizationFinished(with result: VKAuthorizationResult!) {
        if (result.token != nil) {
            self.startWorking()
        } else if ((result.error) != nil) {
            UIAlertView.init(title: "", message: "Access denied \(result.error)", delegate: self, cancelButtonTitle: "Ok").show()
         }
    }
    
    func vkSdkUserAuthorizationFailed() {
        UIAlertView.init(title: "", message: "Access denied", delegate: self, cancelButtonTitle: "Ok").show()
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
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        let SCOPE = [VK_PER_FRIENDS];
           
        let instance = VKSdk.initialize(withAppId: "7144627")
        instance?.uiDelegate = self
        instance?.register(self)
        VKSdk.wakeUpSession(SCOPE, complete: {state, error in
            if (state == VKAuthorizationState.authorized) {
                self.startWorking()
            } else if (error != nil) {
                UIAlertView(title: "", message: error.debugDescription, delegate: self as! UIAlertViewDelegate, cancelButtonTitle: "Ok").show()
            }
        })
        VKSdk.authorize(SCOPE)
        tableView.dataSource = dataSource
    }
    
    func startWorking() {
        VKRequest.init(method:"friends.getRequests",
                       parameters:["count":1000, "offset": 0, "out": 1,
                                   "extended": 1, "fields": "photo_50"]).execute(
            resultBlock: { response in
                guard let dict = response?.json as? Dictionary<String, Any> else {
                    return
                }
                guard let items = dict["items"] as? [Dictionary<String, Any>] else {
                    return
                }
                print("items: \(items)")
                let parsedItems = RequestEntry.fromDictList(items)
                print("parsed items: \(parsedItems)")
                self.dataSource.addData(parsedItems)
                self.tableView.reloadData()
        }, errorBlock:  { error in
            print("error: \(error)")
        })
    }

    
}

struct FriendRequests: Decodable {
    let count: Int
    let items: [RequestEntry]
}

