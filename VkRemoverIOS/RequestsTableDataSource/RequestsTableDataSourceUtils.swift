//
//  utils.swift
//  VkRemoverIOS
//
//  Created by Alex K on 4/25/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation

func extractPhotoURL(_ item: Dictionary<String, Any>) -> String {
    var photoForList = ""
    if let field = item["photo_200"] {
        photoForList = field as? String ?? ""
    }
    if let field = item["photo_100"] {
        photoForList = field as? String ?? ""
    }
    if let field = item["photo_50"] {
        photoForList = field as? String ?? ""
    }
    return photoForList
}

