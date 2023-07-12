//
//  CGImage+Rotating.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 7/12/23.
//

import UIKit
import Accelerate


extension CGImage {
    
    func horizontallyFlipped() -> CGImage? {
        return self.rotated(radians: 0.0, flipOverHorizontalAxis: true, flipOverVerticalAxis: false)
    }

    func verticallyFlipped() -> CGImage? {
        return self.rotated(radians: 0.0, flipOverHorizontalAxis: false, flipOverVerticalAxis: true)
    }

    func rotated(radians: CGFloat) -> CGImage? {
        return self.rotated(radians: radians, flipOverHorizontalAxis: false, flipOverVerticalAxis: false)
    }

    func rotated(degrees: CGFloat) -> CGImage? {
        return self.rotated(radians: deg2rad(degrees), flipOverHorizontalAxis: false, flipOverVerticalAxis: false)
    }

    func rotated(degrees: CGFloat, flipOverHorizontalAxis: Bool, flipOverVerticalAxis: Bool) -> CGImage? {
        return self.rotated(radians: deg2rad(degrees), flipOverHorizontalAxis: flipOverHorizontalAxis, flipOverVerticalAxis: flipOverVerticalAxis)
    }

    func rotated(radians: CGFloat, flipOverHorizontalAxis: Bool, flipOverVerticalAxis: Bool) -> CGImage? {
        // Create an ARGB bitmap context
        let width = self.width
        let height = self.height

        let rotatedRect = CGRect(x: 0, y: 0, width: width, height: height)
            .applying(CGAffineTransform(rotationAngle: radians))

        guard
            let bmContext = CGContext.ARGBBitmapContext(width: Int(rotatedRect.size.width), height: Int(rotatedRect.size.height), withAlpha: true)
        else {
            return nil
        }

        // Image quality
        bmContext.setShouldAntialias(true)
        bmContext.setAllowsAntialiasing(true)
        bmContext.interpolationQuality = .high

        // Rotation happen here (around the center)
        bmContext.scaleBy(x: +(rotatedRect.size.width / 2.0), y: +(rotatedRect.size.height / 2.0))
        bmContext.rotate(by: radians)

        // Do flips
        bmContext.scaleBy(x: (flipOverHorizontalAxis ? -1.0 : 1.0), y: (flipOverVerticalAxis ? -1.0 : 1.0))

        // Draw the image in the bitmap context
        bmContext.draw(self, in: CGRect(x: -(CGFloat(width) / 2.0), y: -(CGFloat(height) / 2.0), width: CGFloat(width), height: CGFloat(height)))

        // Create an image object from the context
        return bmContext.makeImage()
    }

    func pixelsRotated(degrees: Float) -> CGImage? {
        return self.pixelsRotated(radians: deg2rad(degrees))
    }

    func pixelsRotated(radians: Float) -> CGImage? {
        // Create an ARGB bitmap context
        let width = self.width
        let height = self.height
        let bytesPerRow = width * numberOfComponentsPerARBGPixel
        guard
            let bmContext = CGContext.ARGBBitmapContext(width: width, height: height, withAlpha: true)
        else {
            return nil
        }

        // Draw the image in the bitmap context
        bmContext.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Grab the image raw data
        guard
            let data = bmContext.data
        else {
            return nil
        }

        var src = vImage_Buffer(data: data, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: bytesPerRow)
        var dst = vImage_Buffer(data: data, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: bytesPerRow)
        let bgColor: [UInt8] = [0, 0, 0, 0]
        vImageRotate_ARGB8888(&src, &dst, nil, radians, bgColor, vImage_Flags(kvImageBackgroundColorFill))

        return bmContext.makeImage()
    }

    func reflected(height: Int = 0, fromAlpha: CGFloat = 1.0, toAlpha: CGFloat = 0.0) -> CGImage? {
        var h = height
        let width = self.width
        if h <= 0 {
            h = self.height
            return nil
        }

        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0.0)
        guard
            let mainViewContentContext = UIGraphicsGetCurrentContext()
        else {
            return nil
        }

        guard
            let gradientMaskImage = CGImage.makeGrayGradient(width: 1, height: h, fromAlpha: fromAlpha, toAlpha: toAlpha)
        else {
            return nil
        }

        mainViewContentContext.clip(to: CGRect(x: 0, y: 0, width: width, height: h), mask: gradientMaskImage)
        mainViewContentContext.draw(self, in: CGRect(x: 0, y: 0, width: width, height: self.height))

        let theImage = mainViewContentContext.makeImage()

        UIGraphicsEndImageContext()

        return theImage
    }
}
