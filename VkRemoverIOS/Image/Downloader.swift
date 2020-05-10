//
//  Downloader.swift
//  VkRemoverIOS
//
//  Created by Alex K on 5/9/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation
import SDWebImage

var imageCache = NSCache<ImageKey, UIImage>()

func loadImage(aURL: String,
               size: AvatarSize,
               onSuccess: @escaping (UIImage) -> Void) -> SDWebImageCombinedOperation? {
    var operation:SDWebImageCombinedOperation? = nil
    DispatchQueue.global(qos: .default).async {
        operation = SDWebImageManager.shared.loadImage(with: URL(string: aURL),  options: [], progress: nil) { (image, data, error, cacheType, finished,  url) in
            DispatchQueue.global(qos: .default).async {
                let imageKey = ImageKey(url: aURL, avatarSize: size)
                if let resizedImageFromCache = imageCache.object(forKey: imageKey) {
                    DispatchQueue.main.async {
                        onSuccess(resizedImageFromCache)
                    }
                    return
                }
                
                guard let resizedImage = resizeImage(image, toSize: size.getSize()) else {
                    return
                }
                imageCache.setObject(resizedImage, forKey: imageKey)
                DispatchQueue.main.async {
                    onSuccess(resizedImage)
                }
            }
        }
    }
    return operation
}

func resizeImage(_ aImage: UIImage?, toSize: CGSize) -> UIImage? {
    guard let image = aImage, let cgImage = image.cgImage else {
        return nil
    }
    if (image.size.width > toSize.width || image.size.height > toSize.height) {
        let aspectRatio = image.size.height / image.size.width
        let targetHeight = toSize.width * aspectRatio
        
        let targetSize = CGSize(width: toSize.width, height: targetHeight)
            
        UIGraphicsBeginImageContextWithOptions(targetSize, !SDImageCoderHelper.cgImageContainsAlpha(cgImage), 0.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    } else {
        return image
    }
}

class ImageKey:Equatable {
    init(url: String, avatarSize: AvatarSize) {
        self.url = url
        self.avatarSize = avatarSize
    }
    
    static func == (lhs: ImageKey, rhs: ImageKey) -> Bool {
        return lhs.avatarSize == rhs.avatarSize && lhs.url == rhs.url
    }
    
    var url:String
    var avatarSize:AvatarSize = .small
}

enum AvatarSize {
    case small
    case detailed
    
    func getSize() -> CGSize {
        if self == .detailed {
            return CGSize(width: 100, height: 100)
        }
        return CGSize(width: 33, height: 33)
    }
}
