//
//  CGImage+Extensions.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 7/12/23.
//

import Foundation
import CoreGraphics
import UIKit


// MARK: - Image generators
extension CGImage {
    
    class func makeGrayGradient(width: Int, height: Int, fromAlpha: CGFloat, toAlpha: CGFloat) -> CGImage? {
        guard
            let gradientBitmapContext = CGContext.GrayBitmapContext(width: width, height: height)
        else {
            return nil
        }

        // Create a CGGradient
        let colors: [CGFloat] = [toAlpha, 1.0, fromAlpha, 1.0]
        guard
            let grayScaleGradient = CGGradient(colorSpace: CGColorSpaceCreateDeviceGray(),
                                               colorComponents: colors,
                                               locations: nil, count: 2)
        else {
            return nil
        }

        // Draw the gradient into the gray bitmap context
        gradientBitmapContext.drawLinearGradient(grayScaleGradient, start: CGPoint.zero, end: CGPoint(x: 0, y: height), options: [.drawsAfterEndLocation])

        return gradientBitmapContext.makeImage()
    }

    class func makeFromString(_ string: String, font: UIFont, fontColor: UIColor, backgroundColor: UIColor, maxSize: CGSize) -> CGImage? {
        // Create an attributed string with string and font information
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .center
        let attributes = [NSAttributedString.Key.font : font, NSAttributedString.Key.foregroundColor : fontColor, NSAttributedString.Key.paragraphStyle : paragraphStyle]
        let attrString = NSAttributedString(string:string, attributes:attributes)
        let scale = UIScreen.main.scale
        let trueMaxSize = maxSize * scale

        // Figure out how big an image we need
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        var osef = CFRange(location:0, length:0)
        let goodSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, osef, nil, trueMaxSize, &osef).ceilled()
        let rect = CGRect(x: (trueMaxSize.width - goodSize.width) * 0.5, y: (trueMaxSize.height - goodSize.height) * 0.5, width: goodSize.width, height: goodSize.height)
        let path = CGPath(rect: rect, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location:0, length:0), path, nil)

        // Create the context and fill it
        guard
            let bmContext = CGContext.ARGBBitmapContext(width:Int(trueMaxSize.width), height:Int(trueMaxSize.height), withAlpha:true)
        else {
            return nil
        }
        bmContext.setFillColor(backgroundColor.cgColor)
        bmContext.fill(CGRect(origin: CGPoint.zero, size: trueMaxSize))

        // Draw the text
        bmContext.setAllowsAntialiasing(true)
        bmContext.setAllowsFontSmoothing(true)
        bmContext.interpolationQuality = .high
        CTFrameDraw(frame, bmContext)

        return bmContext.makeImage()
    }
    
}

// MARK: - Extension
extension CGImage {
    
    func hasAlpha() -> Bool {
        let alphaInfo = self.alphaInfo
        return (alphaInfo == .first || alphaInfo == .last || alphaInfo == .premultipliedFirst || alphaInfo == .premultipliedLast)
    }
    
}
