//
//  UIImage.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 7/7/23.
//

import Foundation
import CoreImage
import UIKit

extension UIImage {
    var isBlurry: Bool {
        guard let inputImage = CIImage(image: self) else { return false }
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(inputImage, forKey: kCIInputImageKey)
        filter?.setValue(10.0, forKey: kCIInputRadiusKey)
        guard let outputImage = filter?.outputImage else { return false }
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return false }
        let image = UIImage(cgImage: cgImage)
        return image.size.width < self.size.width * 0.9
    }
}
