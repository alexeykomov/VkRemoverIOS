//
//  RequestsTableDataSource.swift
//  VkRemoverIOS
//
//  Created by Alex K on 11/2/19.
//  Copyright © 2019 Alex K. All rights reserved.
//

import Foundation
import SDWebImage

class RequestsTableDataSource: NSObject, UITableViewDataSource, SDWebImageManagerDelegate {
    private var data:[RequestEntry] = []
    private var imageManager = SDWebImageManager()
    
    override init() {
        super.init()
        imageManager.delegate = self
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
        
        cell.avatarImg.layer.borderWidth = 0
        cell.avatarImg.layer.masksToBounds = false
        cell.avatarImg.layer.borderColor = UIColor.white.cgColor
        cell.avatarImg.layer.cornerRadius = cell.avatarImg.frame.height / 2
        cell.avatarImg.clipsToBounds = true
        
        cell.loadImage(url: userData.photoForList)
        return cell
    }

    
    func imageManager(_ imageManager: SDWebImageManager,
                      transformDownloadedImage image: UIImage?,
                      with imageURL: URL?) -> UIImage? {
        print("imageManager")
        guard let image = image, let cgImage = image.cgImage else {
            return nil
        }
        if (image.size.width > 33 || image.size.width > 33) {
            let targetSize = CGSize(width: 33, height: 33)
            UIGraphicsBeginImageContextWithOptions(targetSize, !SDImageCoderHelper.cgImageContainsAlpha(cgImage), image.scale)
            image.draw(in: CGRect(origin: .zero, size: targetSize))
            
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return scaledImage
        } else {
            return image
        }
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
