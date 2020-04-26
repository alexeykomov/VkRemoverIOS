//
//  RequestEntry.swift
//  VkRemoverIOS
//
//  Created by Alex K on 4/25/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

struct RequestEntry: Hashable, Decodable {
    let userId: Int
    let photoForList: String
    let firstName: String
    let lastName: String
    
    func getLabel() -> String {
        return "\(firstName) \(lastName)"
    }
    
    static func fromRequestsList(_ items: [Dictionary<String, Any>]) -> [RequestEntry] {
        return items.map({item in
            return RequestEntry(userId: item["user_id"] as? Int ?? 0,
                                photoForList: extractPhotoURL(item),
                                firstName: item["first_name"] as? String ?? "",
                                lastName: item["last_name"] as? String ?? "")
        })
    }
    
    static func fromFollowersList(_ items: [Dictionary<String, Any>]) -> [RequestEntry] {
       return items.map({item in
           return RequestEntry(userId: item["id"] as? Int ?? 0,
                               photoForList: extractPhotoURL(item),
                               firstName: item["first_name"] as? String ?? "",
                               lastName: item["last_name"] as? String ?? "")
       })
    }
    
    func toDict() -> Dictionary<String, Any> {
        return [
            "user_id":userId,
            "photo_for_list":photoForList,
            "first_name":firstName,
            "last_name":lastName,
        ]
    }
    
    static func fromDict(_ serialized: Dictionary<String, Any>) -> RequestEntry {
        return RequestEntry(userId: serialized["user_id"] as? Int ?? 0,
                            photoForList: serialized["photo_for_list"] as? String ?? "",
                            firstName: serialized["first_name"] as? String ?? "",
                            lastName: serialized["last_name"] as? String ?? "")
    }
}
