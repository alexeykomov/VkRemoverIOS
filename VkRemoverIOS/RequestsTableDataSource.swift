//
//  RequestsTableDataSource.swift
//  VkRemoverIOS
//
//  Created by Alex K on 11/2/19.
//  Copyright © 2019 Alex K. All rights reserved.
//

import Foundation

class RequestsTabeDataSource: NSObject, UITableViewDataSource {
    private var data:[RequestEntry] = []
    
    override init() {
        for var i in 0...1000 {
         
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier")!
        let userData = data[indexPath.row]
        cell.textLabel?.text = userData.getLabel()
        return cell
    }
    
    func addData(_ items: [RequestEntry]) {
        data.append(contentsOf: items)
    }
    
}

struct RequestEntry: Decodable {
    let userId: String
    let photo50: String
    let firstName: String
    let lastName: String
    
    func getLabel() -> String {
        return "\(firstName) \(lastName)"
    }
    
    static func fromDictList(_ items: [Dictionary<String, Any>]) -> [RequestEntry] {
        return items.map({item in

            return RequestEntry(userId: item["user_id"] as? String ?? "",
                                photo50: item["photo_50"] as? String ?? "",
                                firstName: item["first_name"] as? String ?? "",
                                lastName: item["last_name"] as? String ?? "")
        })
    }
}
