//
//  FaceMaskHelper.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/22/23.
//

import AVFoundation
import CoreImage
import Vision
import UIKit


@available(iOS 13.0, *)
public class FaceMaskModel {
    
    public struct FaceMaskResult {
        public let result: [Float32]
    }
    
    public enum Label: Int {
        case bad = 0
        case good = 1
        case facemask = 2
        case sunglasses = 3
    }
    
    public static let InputImageSize = 112
    
    private let faceMask: FaceMask = {
        do {
            let config = MLModelConfiguration()
            return try FaceMask(configuration: config)
        } catch {
            fatalError("\(error.localizedDescription)")
        }
    }()
    
    public func detectFaceMask(buffer: CVPixelBuffer) throws -> [Float32] {
        do {
            let rawPrediction = try faceMask.prediction(x_1: buffer)
            if let result = try? UnsafeBufferPointer<Float32>(rawPrediction.var_844) {
                let predictionResult = Array(result)
                return predictionResult
            }
            return [0, 0, 0, 0]
        } catch {
            return [0, 0, 0, 0]
        }
    }
}




