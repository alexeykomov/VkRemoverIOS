//
//  SDWebImageManagerDelegate.swift
//  VkRemoverIOS
//
//  Created by Alex K on 2/2/20.
//  Copyright © 2020 Alex K. All rights reserved.
//

import Foundation
import SDWebImage

class ImageTransformer: NSObject, SDWebImageManagerDelegate {
    func imageManager(_ imageManager: SDWebImageManager, transformDownloadedImage image: UIImage?, with imageURL: URL?) -> UIImage? {
        
        guard let image = image, let cgImage = image.cgImage else {
            return nil
        }
        if (image.size.width > 33 || image.size.width > 33) {
            let targetSize = CGSize(width: 33, height: 33)
            UIGraphicsBeginImageContextWithOptions(image.size, !SDImageCoderHelper.cgImageContainsAlpha(cgImage), image.scale)
            image.draw(in: CGRect(origin: .zero, size: targetSize))
            
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return scaledImage
        } else {
            return image
        }
    }
}
