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
    
    public static let DefaultResult: [Float32] = [0, 0, 0]
    public static let InputImageSize = 80
    public static let AntiSpoofingThreshold: Float32 = 0.9
    
    private let faceAntiSpoofing2: FaceAntiSpoofing2 = {
        do {
            let config = MLModelConfiguration()
            return try FaceAntiSpoofing2(configuration: config)
        } catch {
            fatalError("\(error.localizedDescription)")
        }
    }()
    
    private let faceAntiSpoofing4: FaceAntiSpoofing4 = {
        do {
            let config = MLModelConfiguration()
            return try FaceAntiSpoofing4(configuration: config)
        } catch {
            fatalError("\(error.localizedDescription)")
        }
    }()
    
    public func antiSpoofing2(buffer: CVPixelBuffer) throws -> [Float32] {
        
        if let resizedBuffer = resizePixelBuffer(buffer, width: FaceAntiSpoofingModel.InputImageSize, height: FaceAntiSpoofingModel.InputImageSize) {
            do {
                let rawPrediction = try faceAntiSpoofing2.prediction(input_1: resizedBuffer)
                if let result = try? UnsafeBufferPointer<Float32>(rawPrediction.var_933) {
                    let predictionResult = Array(result)
                    return predictionResult
                }
                return FaceAntiSpoofingModel.DefaultResult
            } catch {
                print("\(error.localizedDescription)")
                return FaceAntiSpoofingModel.DefaultResult
            }
        }
        return FaceAntiSpoofingModel.DefaultResult
    }
    
    public func antiSpoofing4(buffer: CVPixelBuffer) throws -> [Float32] {
        
        if let resizedBuffer = resizePixelBuffer(buffer, width: FaceAntiSpoofingModel.InputImageSize, height: FaceAntiSpoofingModel.InputImageSize) {
            do {
                let rawPrediction = try faceAntiSpoofing4.prediction(input_1: resizedBuffer)
                if let result = try? UnsafeBufferPointer<Float32>(rawPrediction.var_1030) {
                    let predictionResult = Array(result)
                    return predictionResult
                }
                return FaceAntiSpoofingModel.DefaultResult
            } catch {
                print("\(error.localizedDescription)")
                return FaceAntiSpoofingModel.DefaultResult
            }
        }
        return FaceAntiSpoofingModel.DefaultResult
    }

    
    
}
