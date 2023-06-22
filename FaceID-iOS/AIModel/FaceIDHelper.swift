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
        do {
            let rawPrediction = try faceID.prediction(input_1: buffer)
            if let result = try? UnsafeBufferPointer<Float32>(rawPrediction.var_1612) {
                let predictionResult = Array(result)
                return predictionResult
            }
            return []
        } catch {
            return []
        }
    }
}



