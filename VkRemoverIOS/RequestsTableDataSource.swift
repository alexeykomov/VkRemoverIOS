//
//  RequestsTableDataSource.swift
//  VkRemoverIOS
//
//  Created by Alex K on 11/2/19.
//  Copyright © 2019 Alex K. All rights reserved.
//

import Foundation
import SDWebImage

class RequestsTableDataSource: NSObject, UITableViewDataSource {
    private var data:[RequestEntry] = [
//        RequestEntry(userId: "177234906",
//                     photo50: "",
//                     firstName: "Some",
//                     lastName: "Name")
    ]
    
    override init() {        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier") as! RequestTableCell
        let userData = data[indexPath.row]
        cell.userName.text = userData.getLabel()
        cell.avatarImg.sd_setImage(with: URL(string: userData.photo50))
        cell.avatarImg.layer.borderWidth = 0
        cell.avatarImg.layer.masksToBounds = false
        cell.avatarImg.layer.borderColor = UIColor.white.cgColor
        cell.avatarImg.layer.cornerRadius = cell.avatarImg.frame.height / 2
        cell.avatarImg.clipsToBounds = true
        return cell
    }
    
    func addData(_ items: [RequestEntry]) {
        data.append(contentsOf: items)
    }
    
    func getData() -> [RequestEntry] {
        return data
    }
    
    func remove(at: Int) -> Void {
         data.remove(at: at)
    }
}

struct RequestEntry: Hashable, Decodable {
    let userId: Int
    let photo50: String
    let firstName: String
    let lastName: String
    
    func getLabel() -> String {
        return "\(firstName) \(lastName)"
    }
    
    static func fromRequestsList(_ items: [Dictionary<String, Any>]) -> [RequestEntry] {
        return items.map({item in
            return RequestEntry(userId: item["user_id"] as? Int ?? 0,
                                photo50: item["photo_50"] as? String ?? "",
                                firstName: item["first_name"] as? String ?? "",
                                lastName: item["last_name"] as? String ?? "")
        })
    }
    
    static func fromFollowersList(_ items: [Dictionary<String, Any>]) -> [RequestEntry] {
       return items.map({item in
           return RequestEntry(userId: item["id"] as? Int ?? 0,
                               photo50: item["photo_50"] as? String ?? "",
                               firstName: item["first_name"] as? String ?? "",
                               lastName: item["last_name"] as? String ?? "")
       })
    }
    
    func toDict() -> Dictionary<String, Any> {
        return [
            "user_id":userId,
            "photo_50":photo50,
            "first_name":firstName,
            "last_name":lastName,
        ]
    }
    
    static func fromDict(_ serialized: Dictionary<String, Any>) -> RequestEntry {
        return RequestEntry(userId: serialized["user_id"] as? Int ?? 0,
                            photo50: serialized["photo_50"] as? String ?? "",
                            firstName: serialized["first_name"] as? String ?? "",
                            lastName: serialized["last_name"] as? String ?? "")
    }
}
