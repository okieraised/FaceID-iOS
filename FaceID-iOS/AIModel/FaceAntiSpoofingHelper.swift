//
//  FaceAntiSpoofinghelper.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/21/23.
//

import Foundation
import CoreImage
import Vision
import UIKit
import CoreML



@available(iOS 13.0, *)
public class FaceAntiSpoofingModel {
    
    public struct FaceAntiSpoofingResult {
        public let result: [Float32]
    }
    
    public static let InputImageSize = 80
    
    private let faceAntiSpoofing: FaceAntiSpoofing = {
        do {
            let config = MLModelConfiguration()
            return try FaceAntiSpoofing(configuration: config)
        } catch {
            fatalError("\(error.localizedDescription)")
        }
    }()
    
    public func antiSpoofing(buffer: CVPixelBuffer) throws -> [Float32] {
        
        if let resizedBuffer = resizePixelBuffer(buffer, width: FaceAntiSpoofingModel.InputImageSize, height: FaceAntiSpoofingModel.InputImageSize) {
            do {
                let rawPrediction = try faceAntiSpoofing.prediction(input_1: resizedBuffer)
    
                print(rawPrediction.var_1030)
                
                if let result = try? UnsafeBufferPointer<Float32>(rawPrediction.var_1030) {
                    let predictionResult = Array(result)
                    print(predictionResult)

                    return predictionResult
                }
                
                return [0, 0, 0]
                

            } catch {
                print("\(error.localizedDescription)")
                return [0, 0, 0]
            }
        }
        return [0, 0, 0]
    }
}
