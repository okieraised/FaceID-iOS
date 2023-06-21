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
        
        do {
//            let cc = try faceID.prediction(input_1: MLFeatureValue(g))
//
//            print(cc.var_1612)

            return []

        } catch {
            return []
        }
    }
}



