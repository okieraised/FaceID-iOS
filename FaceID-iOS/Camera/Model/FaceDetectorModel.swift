//
//  FaceDetectorModel.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/13/23.
//

import AVFoundation
import Foundation
import Vision
import CoreImage
import UIKit
import Combine


protocol FaceDetectorDelegate: NSObjectProtocol {
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect
}

class FaceDetector: NSObject {
    
    // MARK: - Variables
    
    weak var viewDelegate: FaceDetectorDelegate?
    
    weak var cameraViewModel: CameraViewModel? {
        didSet {
            cameraViewModel?.shutterReleased.sink { completion in
                switch completion {
                case .finished:
                    return
                case .failure(let error):
                    print("Received error: \(error)")
                }
            } receiveValue: { _ in
                self.isCapturingPhoto = true
            }
            .store(in: &subscriptions)
        }
    }

    var sequenceHandler = VNSequenceRequestHandler()
    var faceIDModel = FaceIDModel()
    var faceAntiSpoofingModel = FaceAntiSpoofingModel()
    var faceMaskModel = FaceMaskModel()
    var isCapturingPhoto = false
    var currentFrameBuffer: CVImageBuffer?
    var subscriptions = Set<AnyCancellable>()
    var bBox = CGRect()
    var faceLandmark: VNFaceLandmarks2D?

    // MARK: - Processing Queue

    let imageProcessingQueue = DispatchQueue(
        label: "Image Processing Queue",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    
    let context = CIContext()
}

// MARK: - Extension

extension FaceDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer), let model = cameraViewModel, let viewDelegate = viewDelegate
        else {
            return
        }
        
        // Discard blurry frame
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let image = UIImage(cgImage: cgImage)
            if image.isBlurry {
                return
            }
        }
        

        if isCapturingPhoto {
            isCapturingPhoto = false
            saveCapturedPhoto(from: pixelBuffer)
        }
        
        let detectFaceRectanglesRequest = VNDetectFaceRectanglesRequest(completionHandler: detectedFaceRectangles)
        detectFaceRectanglesRequest.revision = VNDetectFaceRectanglesRequestRevision3

        let detectCaptureQualityRequest = VNDetectFaceCaptureQualityRequest(completionHandler: detectedFaceQualityRequest)
        detectCaptureQualityRequest.revision = VNDetectFaceCaptureQualityRequestRevision2
        
        let detectFaceLandmarkRequest = VNDetectFaceLandmarksRequest(completionHandler: detectedFaceLandmarkRequest)
        detectFaceLandmarkRequest.revision = VNDetectFaceLandmarksRequestRevision3


        currentFrameBuffer = pixelBuffer
        do {
            try sequenceHandler.perform(
                [detectFaceRectanglesRequest, detectCaptureQualityRequest, detectFaceLandmarkRequest],
                on: pixelBuffer,
                orientation: .leftMirrored // .up
            )
        } catch {
            print(error.localizedDescription)
        }
        
        let boundingBox = viewDelegate.convertFromMetadataToPreviewRect(rect: bBox)
        
        if isInvalidBoundingBox(boundingBox) {
            model.perform(action: .noFaceDetected)
            return
        }
        
        if let buffer = currentFrameBuffer {
            faceIDHandler(buffer: buffer)
            faceLivenessHandler(buffer: buffer)
        }
    }
}

// MARK: - Extensions

extension FaceDetector {
    
    
    func detectedFaceRectangles(request: VNRequest, error: Error?) {
        guard
            let model = cameraViewModel, let viewDelegate = viewDelegate
        else {
            return
        }
        
        guard
            let results = request.results as? [VNFaceObservation],
            let result = results.first
        else {
            model.perform(action: .noFaceDetected)
            return
        }

        let boundingBox = viewDelegate.convertFromMetadataToPreviewRect(rect: result.boundingBox)
        
        if isInvalidBoundingBox(boundingBox) {
            model.perform(action: .noFaceDetected)
            return
        }
        
        let faceGeometry = FaceGeometryModel(
            boundingBox: boundingBox,
            roll: result.roll ?? 0,
            pitch: result.pitch ?? 0,
            yaw: result.yaw ?? 0
        )
        
        model.perform(action: .faceGeometryDetected(faceGeometry))
    }
    
    
    func detectedFaceLandmarkRequest(request: VNRequest, error: Error?) {
        guard
            let model = cameraViewModel
        else {
            return
        }
        
        guard
            let results = request.results as? [VNFaceObservation],
            let result = results.first
        else {
            model.perform(action: .noFaceDetected)
            return
        }
        
        bBox = result.boundingBox
        if let landmarks = result.landmarks {
            faceLandmark = landmarks
        }
    }
    
    
    func detectedFaceQualityRequest(request: VNRequest, error: Error?) {
        guard
            let model = cameraViewModel
        else {
            return
        }

        guard
            let results = request.results as? [VNFaceObservation],
            let result = results.first
        else {
            model.perform(action: .noFaceDetected)
            return
        }

        let faceQuality = FaceQualityModel(
            quality: result.faceCaptureQuality ?? 0
        )

        model.perform(action: .faceQualityDetected(faceQuality))
    }
    
    func faceIDHandler(buffer: CVPixelBuffer) {
            
            guard
                let model = cameraViewModel
            else {
                return
            }
            
            if model.captureMode && model.facePosition == .Straight {
                if let resizedBuffer = createAlignInput(pixelBuffer: buffer) {
                    if let vector = try? faceIDModel.detectFaceID(buffer: resizedBuffer) {
                        model.perform(action: .faceVectorDetected(FaceVectorModel(vector: vector)))
                    }
                }
            }
        }
    
    func faceLivenessHandler(buffer: CVPixelBuffer) {
            
        guard
            let model = cameraViewModel,
            let maskBuffer = createAlignInput(pixelBuffer: buffer),
            let livenessBuffer2 = createLivenessInput(pixelBuffer: buffer, scaleOri: 2.7, width: FaceAntiSpoofingModel.InputImageSize, height: FaceAntiSpoofingModel.InputImageSize),
            let livenessBuffer4 = createLivenessInput(pixelBuffer: buffer, scaleOri: 4.0, width: FaceAntiSpoofingModel.InputImageSize, height: FaceAntiSpoofingModel.InputImageSize)
        else {
            return
        }
        
        var faceLiveness = FaceLivenessModel(spoofed: true, obstructed: true)
        if let maskResult = try? faceMaskModel.detectFaceMask(buffer: maskBuffer) {
            print("model - facemask", maskResult)
            if let idx = maskResult.argmax() {
                faceLiveness.obstructed = (
                    idx == FaceMaskModel.Label.facemask.rawValue ||
                    idx == FaceMaskModel.Label.sunglasses.rawValue
                )
            }
        }
        
        var spoofingVal2: Float32 = 0
        var spoofingVal4: Float32 = 0
            
        if let spoofingResult2 = try? faceAntiSpoofingModel.antiSpoofing2(buffer: livenessBuffer2) {
            print("model - liveness2", spoofingResult2)
            spoofingVal2 = spoofingResult2[1]
        }
        
        if let spoofingResult4 = try? faceAntiSpoofingModel.antiSpoofing4(buffer: livenessBuffer4) {
            print("model - liveness4", spoofingResult4)
            spoofingVal4 = spoofingResult4[1]
        }
        
        let avgSpoofingVal = (spoofingVal2 + spoofingVal4) / 2
    
        faceLiveness.spoofed = (avgSpoofingVal < FaceAntiSpoofingModel.AntiSpoofingThreshold) ? true : false
        model.perform(action: .faceLivenessDetected(faceLiveness))
    }
    
    
    
    func saveCapturedPhoto(from pixelBuffer: CVPixelBuffer) {
        guard
            let model = cameraViewModel
        else {
            return
        }
        
        imageProcessingQueue.async { [self] in
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                let uiImage = UIImage(cgImage: cgImage, scale: 1.5, orientation: .upMirrored)
                DispatchQueue.main.async {
                    model.perform(action: .savePhoto(uiImage))
                }
            }
        }
    }
}


extension FaceDetector {
    
    private func isInvalidBoundingBox(_ boundingBox: CGRect) -> Bool {
        
        return round(abs(UIScreen.midY - boundingBox.midY)) < 50 ||
        round(abs(UIScreen.midY - boundingBox.midY)) > 300 ||
        round(abs(UIScreen.midX - boundingBox.midX)) > 130 ||
        round(boundingBox.midY) > 450 ||
        round(boundingBox.midX) < 100 ||
        round(boundingBox.midX) > 300
    }
    
    // model 2: scale = 2.7, model 4: scale = 4.0
    private func createLivenessInput(pixelBuffer: CVPixelBuffer, scaleOri: Float, width: Int, height: Int) -> CVPixelBuffer? {
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let srcHeight = CGFloat(ciImage.extent.size.height)
        let srcWidth = CGFloat(ciImage.extent.size.width)
        let scale = min(1 / bBox.height, srcWidth / (srcHeight * bBox.height), CGFloat(scaleOri))
        let newHeight = bBox.height * scale
        let newWidth = bBox.height * scale * srcHeight / srcWidth
        
        var x1 = bBox.midX - newWidth / 2
        var y1 = bBox.midY - newHeight / 2
        var x2 = bBox.midX + newWidth / 2
        var y2 = bBox.midY + newHeight / 2
        
        if (x1 < 0) {
            x2 -= x1
            x1 = 0
        }
        if (y1 < 0) {
            y2 -= y1
            y1 = 0
        }
        if (x2 > 1) {
            x1 -= x2 - 1
            x2 = 1
        }
        if (y2 > 1) {
            y1 -= y2 - 1
            y2 = 1
        }
        let box = CGRect(x: x1*srcWidth, y: y1*srcHeight, width: (x2-x1)*srcWidth-1, height: (y2-y1)*srcHeight-1)
        let faceImage = ciImage.cropped(to: box)
        
        guard
            let cgImage = context.createCGImage(faceImage, from: faceImage.extent)
        else {
            return nil
        }
        
        guard
            let convertedBuffer = cgImage.pixelBuffer()
        else {
            return nil
        }
        
//        let normalizedBox = VNImageRectForNormalizedRect(bBox, Int(srcWidth), Int(srcHeight))
//        let faceImage2 = ciImage.cropped(to: normalizedBox)
//        let cgImage2 = context.createCGImage(faceImage2, from: faceImage2.extent)
//        let uiImage = UIImage(cgImage: cgImage)
//        DispatchQueue.main.async {
//            model.perform(action: .savePhoto(uiImage))
//        }

        return resizePixelBuffer(convertedBuffer, width: width, height: height)
    }
    
    
    private func createAlignInput(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        if (faceLandmark == nil) {
            return nil
        }
        let oriCIImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.left)
        let uiImage = UIImage(ciImage: oriCIImage)
        let flippedUIImage = uiImage.withHorizontallyFlippedOrientation()
        guard
            let ciImage = flippedUIImage.ciImage
        else {
            return nil
        }
        
        let srcHeight = CGFloat(ciImage.extent.size.height)
        let srcWidth = CGFloat(ciImage.extent.size.width)
        // le - re - nose - lm - rm
        let index5 = [6,13,49,26,34]

        // convert to original coordinate (ref source image)
        let allpoints = faceLandmark!.allPoints!.normalizedPoints
        var pointArray: [Float] = Array<Float>()
        var M: [Float] = Array(repeating: 0, count: 6)
        for idx in index5 {
            let point = VNImagePointForFaceLandmarkPoint(
                vector_float2(Float(allpoints[idx].x), Float(allpoints[idx].y)),
                bBox, Int(srcWidth), Int(srcHeight))
            pointArray.append(Float(point.x))
            pointArray.append(Float(point.y))
        }
         
         let wrapper = OpenCVWrapper()
         wrapper.estimateAffinePartial2D(pointArray, output: &M)
         let matrix = CGAffineTransform(CGFloat(M[0]), CGFloat(M[3]), CGFloat(M[1]), CGFloat(M[4]), CGFloat(M[2]), CGFloat(M[5]))
         let aligned = ciImage
            .transformed(by: matrix, highQualityDownsample: true)
            .cropped(to: CGRect(x: 0, y: 0, width: FaceIDModel.InputImageSize, height: FaceIDModel.InputImageSize))
         guard
             let cgImage = context.createCGImage(aligned, from: aligned.extent)
         else {
             return nil
         }
         guard
             let convertedBuffer = cgImage.pixelBuffer()
         else {
             return nil
         }
//         let toSave = UIImage(cgImage: cgImage)
//         DispatchQueue.main.async {
//             model.perform(action: .savePhoto(toSave))
//         }
         return convertedBuffer
     }
}
