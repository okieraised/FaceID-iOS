//
//  FaceIDModelHelper.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/20/23.
//

import AVFoundation
import CoreImage
import Vision
import UIKit


@available(iOS 13.0, *)
public class FaceIDModel {
    
    public struct FaceIDResult {
        public let result: [Float32]
    }
    
    public static let InputImageSize = 112
    
    private let faceID: FaceID = {
        do {
            let config = MLModelConfiguration()
            return try FaceID(configuration: config)
        } catch {
            fatalError("\(error.localizedDescription)")
        }
    }()
    
    public func detectFaceID(buffer: CVPixelBuffer) throws -> [Float32] {
        
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let scale = CGFloat(FaceIDModel.InputImageSize) / CGFloat(min(width, height))
        let transform = CGAffineTransform(scaleX: scale, y: scale)

        
        let ciImage = CIImage(cvPixelBuffer: buffer).transformed(by: transform, highQualityDownsample: true)
        let uiImage = UIImage(ciImage: ciImage)
        
        let resized = uiImage.resizeImageTo(size: CGSize(width: 112, height: 112))
        
//        let imageAsMultiArray: MLMultiArray = resized.mlMultiArray()
        
        do {
            let cc = try faceID.prediction(input_1: resized as! CVPixelBuffer)

            print(cc.var_1612)

            return []

        } catch {
            return []
        }
    }
}



//@available(iOS 13.0, *)
//public class MaskDetectionVideoHelper {
//
//    public enum ResizeMode {
//        case centerCrop
//        case stretch
//    }
//
//    private let resizeMode: ResizeMode
//    private let faceID: FaceID
//
//    public init(faceID: FaceID, resizeMode: ResizeMode = .centerCrop) {
//        self.faceID = faceID
//        self.resizeMode = resizeMode
//    }
//
//    public func detectInImageBuffer(_ image: CVImageBuffer) -> [FaceID] {
//        let width = CVPixelBufferGetWidth(image)
//        let height = CVPixelBufferGetHeight(image)
//        let transform: CGAffineTransform
//        if resizeMode == .centerCrop  {
//            let scale = CGFloat(MaskDetector.InputImageSize) / CGFloat(min(width, height))
//            transform = CGAffineTransform(scaleX: scale, y: scale)
//        } else {
//            let scaleX = CGFloat(MaskDetector.InputImageSize) / CGFloat(width)
//            let scaleY = CGFloat(MaskDetector.InputImageSize) / CGFloat(height)
//            transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
//        }
//
//        let ciImage = CIImage(cvPixelBuffer: image)
//                        .transformed(by: transform, highQualityDownsample: true)
//        if let results = try? maskDetector.detectMasks(ciImage: ciImage) {
//            if resizeMode == .centerCrop {
//            // Transform bounding box coordinates back to the input image
//            let inputAspect = CGFloat(width) / CGFloat(height)
//            return results.map { res in
//                let bound = res.bound
//                                .applying(CGAffineTransform(scaleX: 1, y: inputAspect))
//                                .applying(CGAffineTransform(translationX: 0, y: 0.5 * (1 - inputAspect)))
//                return MaskDetector.MaskResult(status: res.status, bound: bound, confidence: res.confidence)
//                }
//            } else {
//                return results
//            }
//        } else {
//            return [MaskDetector.MaskResult(status: .noMask, bound: CGRect(x: 1, y: 1, width: 1, height: 1), confidence: 0)]
//        }
//    }
//}

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


    func mlMultiArray(scale preprocessScale:Double=255, rBias preprocessRBias:Double=0, gBias preprocessGBias:Double=0, bBias preprocessBBias:Double=0) -> MLMultiArray {
        let imagePixel = self.getPixelRgb(scale: preprocessScale,
                                          rBias: preprocessRBias,
                                          gBias: preprocessGBias,
                                          bBias: preprocessBBias)
        let size = self.size
        
        let imagePointer : UnsafePointer<Double> = UnsafePointer(imagePixel)
        
        let mlArray = try! MLMultiArray(shape: [1, 3,
                                                NSNumber(value: Float32(size.width)),
                                                NSNumber(value: Float32(size.height))],
                                        dataType: MLMultiArrayDataType.float32)
        
        mlArray.dataPointer.initializeMemory(as: Double.self, from: imagePointer, count: 80*80)
        
        return mlArray
    }
    
//    func mlMultiArrayGrayScale(scale preprocessScale:Double=255,bias preprocessBias:Double=0) -> MLMultiArray {
//        let imagePixel = self.getPixelGrayScale(scale: preprocessScale, bias: preprocessBias)
//        let size = self.size
//        let imagePointer : UnsafePointer<Double> = UnsafePointer(imagePixel)
//        let mlArray = try! MLMultiArray(shape: [1,  NSNumber(value: Float(size.width)), NSNumber(value: Float(size.height))], dataType: MLMultiArrayDataType.double)
//        mlArray.dataPointer.initializeMemory(as: Double.self, from: imagePointer, count: imagePixel.count)
//        return mlArray
//    }

    func getPixelRgb(scale preprocessScale:Double=255, rBias preprocessRBias:Double=0, gBias preprocessGBias:Double=0, bBias preprocessBBias:Double=0) -> [Double]
    {
        guard let cgImage = self.cgImage else {
            return []
        }
        let bytesPerRow = cgImage.bytesPerRow
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let pixelData = cgImage.dataProvider!.data! as Data
        
        var r_buf : [Double] = []
        var g_buf : [Double] = []
        var b_buf : [Double] = []
        
        for j in 0..<height {
            for i in 0..<width {
                let pixelInfo = bytesPerRow * j + i * bytesPerPixel
                let r = Double(pixelData[pixelInfo])
                let g = Double(pixelData[pixelInfo+1])
                let b = Double(pixelData[pixelInfo+2])
                r_buf.append(Double(r/preprocessScale)+preprocessRBias)
                g_buf.append(Double(g/preprocessScale)+preprocessGBias)
                b_buf.append(Double(b/preprocessScale)+preprocessBBias)
            }
        }
        return ((b_buf + g_buf) + r_buf)
    }
    
    func getPixelGrayScale(scale preprocessScale:Double=255, bias preprocessBias:Double=0) -> [Double]
    {
        guard let cgImage = self.cgImage else {
            return []
        }
        let bytesPerRow = cgImage.bytesPerRow
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 2
        let pixelData = cgImage.dataProvider!.data! as Data
        
        var buf : [Double] = []
        
        for j in 0..<height {
            for i in 0..<width {
                let pixelInfo = bytesPerRow * j + i * bytesPerPixel
                let v = Double(pixelData[pixelInfo])
                buf.append(Double(v/preprocessScale)+preprocessBias)
            }
        }
        return buf
    }
    
    func resize(to newSize: CGSize) -> UIImage? {

        guard self.size != newSize else { return self }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))

        defer { UIGraphicsEndImageContext() }
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    public func pixelData() -> [UInt8]? {
        let dataSize = size.width * size.height * 4
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 4 * Int(size.width), space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        
        guard let cgImage = self.cgImage else { return nil }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        return pixelData
    }
    
//    func preprocess(uimage: UIImage) -> MLMultiArray? {
//            let size = CGSize(width: 299, height: 299)
//
//
//            guard let pixels = uimage.resize(to: size).pixelData()?.map({ (Double($0) / 255.0 - 0.5) * 2 }) else {
//                return nil
//            }
//
//            guard let array = try? MLMultiArray(shape: [3, 299, 299], dataType: .double) else {
//                return nil
//            }
//
//            let r = pixels.enumerated().filter { $0.offset % 4 == 0 }.map { $0.element }
//            let g = pixels.enumerated().filter { $0.offset % 4 == 1 }.map { $0.element }
//            let b = pixels.enumerated().filter { $0.offset % 4 == 2 }.map { $0.element }
//
//            let combination = r + g + b
//            for (index, element) in combination.enumerated() {
//                array[index] = NSNumber(value: element)
//            }
//
//            return array
//        }
    
}
