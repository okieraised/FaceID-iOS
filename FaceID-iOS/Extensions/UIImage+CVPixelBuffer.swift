//
//  UIImageExtension.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/21/23.
//

import Foundation
import UIKit


extension UIImage {
    
    func resizeImageTo(size: CGSize) -> UIImage {

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return resizedImage
        }

        return UIImage()
    }
}

#if canImport(UIKit)

import UIKit
import VideoToolbox

extension UIImage {
    /**
    Converts the image to an ARGB `CVPixelBuffer`.
    */
    public func pixelBuffer() -> CVPixelBuffer? {
        return pixelBuffer(width: Int(size.width), height: Int(size.height))
    }

    /**
    Resizes the image to `width` x `height` and converts it to an ARGB
    `CVPixelBuffer`.
    */
    public func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        return pixelBuffer(width: width,
                           height: height,
                           pixelFormatType: kCVPixelFormatType_32ABGR,
                           colorSpace: CGColorSpaceCreateDeviceRGB(),
                           alphaInfo: .noneSkipFirst)
    }

    /**
    Converts the image to a grayscale `CVPixelBuffer`.
    */
    public func pixelBufferGray() -> CVPixelBuffer? {
        return pixelBufferGray(width: Int(size.width), height: Int(size.height))
    }

    /**
    Resizes the image to `width` x `height` and converts it to a grayscale
    `CVPixelBuffer`.
    */
    public func pixelBufferGray(width: Int, height: Int) -> CVPixelBuffer? {
        return pixelBuffer(width: width,
                           height: height,
                           pixelFormatType: kCVPixelFormatType_OneComponent8,
                           colorSpace: CGColorSpaceCreateDeviceGray(),
                           alphaInfo: .none)
    }

    /**
    Resizes the image to `width` x `height` and converts it to a `CVPixelBuffer`
    with the specified pixel format, color space, and alpha channel.
    */
    public func pixelBuffer(width: Int, height: Int, pixelFormatType: OSType, colorSpace: CGColorSpace, alphaInfo: CGImageAlphaInfo) -> CVPixelBuffer? {
        var maybePixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, pixelFormatType, attrs as CFDictionary, &maybePixelBuffer)

        guard
            status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer
        else {
            return nil
        }

        let flags = CVPixelBufferLockFlags(rawValue: 0)
        guard
            kCVReturnSuccess == CVPixelBufferLockBaseAddress(pixelBuffer, flags)
        else {
            return nil
        }
        
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, flags)
        }

        guard
            let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                    space: colorSpace,
                                    bitmapInfo: alphaInfo.rawValue)
        else {
            return nil
        }

        UIGraphicsPushContext(context)
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()

        return pixelBuffer
    }
}

#endif
