//
//  RequestTableCell.swift
//  VkRemoverIOS
//
//  Created by Alex K on 11/2/19.
//  Copyright © 2019 Alex K. All rights reserved.
//

import UIKit
import SDWebImage

class RequestTableCell: UITableViewCell {
    @IBOutlet weak var avatarImg: UIImageView!
    @IBOutlet weak var userName: UILabel!
    private var operation: SDWebImageCombinedOperation? = nil
    
    override func prepareForReuse() {
        super.prepareForReuse()
        operation?.cancel()
        self.avatarImg.image = UIImage(named: "avatar_placeholder")
    }
    
    func loadImage(url: String) {
        DispatchQueue.global(qos: .utility).async {
            self.operation = SDWebImageManager.shared.loadImage(with: URL(string: url), options: [], progress: nil) { (image, data, error, cacheType, finished, url) in
                DispatchQueue.global(qos: .utility).async {
                    
                    guard let resizedImage = self.resizeImage(image) else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.avatarImg.image = resizedImage
                    }
                }
            }
        }
    }
    
    func resizeImage(_ aImage: UIImage?) -> UIImage? {
        guard let image = aImage, let cgImage = image.cgImage else {
            return nil
        }
        if (image.size.width > 33 || image.size.width > 33) {
            let targetSize = CGSize(width: 33, height: 33)
            UIGraphicsBeginImageContextWithOptions(targetSize, !SDImageCoderHelper.cgImageContainsAlpha(cgImage), 0.0)
            image.draw(in: CGRect(origin: .zero, size: targetSize))
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return scaledImage
        } else {
            return image
        }
    }
}
