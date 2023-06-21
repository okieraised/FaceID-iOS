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
    func draw(image: CIImage)
}

class FaceDetector: NSObject {
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
    var isCapturingPhoto = true
    var currentFrameBuffer: CVImageBuffer?
    var subscriptions = Set<AnyCancellable>()
    
    var rect = CGRect()

    let imageProcessingQueue = DispatchQueue(
        label: "Image Processing Queue",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
}


extension FaceDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else {
            return
        }
        
//        do {
//            try FaceIDModel().detectFaceID(buffer: imageBuffer)
//        } catch {
//            print("\(error.localizedDescription)")
//        }
//

        if isCapturingPhoto {
//            isCapturingPhoto = false
            saveCapturedPhoto(from: imageBuffer)
        }
        
        /// Vision Model to detect face angles and quality
        let detectFaceRectanglesRequest = VNDetectFaceRectanglesRequest(completionHandler: detectedFaceRectangles)
        detectFaceRectanglesRequest.revision = VNDetectFaceRectanglesRequestRevision3

        let detectCaptureQualityRequest = VNDetectFaceCaptureQualityRequest(completionHandler: detectedFaceQualityRequest)
        detectCaptureQualityRequest.revision = VNDetectFaceCaptureQualityRequestRevision2

        currentFrameBuffer = imageBuffer
        do {
            try sequenceHandler.perform(
                [detectFaceRectanglesRequest, detectCaptureQualityRequest],
                on: imageBuffer,
                orientation: .leftMirrored)
        } catch {
            print(error.localizedDescription)
        }
    }
}

// MARK: - Extensions

extension FaceDetector {
    
    // detectedFaceRectangles detect the roll, pitch, and yaw values of the detected faces
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
        
        rect = result.boundingBox
        
        
        
        let convertedBoundingBox = viewDelegate.convertFromMetadataToPreviewRect(rect: result.boundingBox)
        
        let faceGeometry = FaceGeometryModel(
            boundingBox: convertedBoundingBox,
            roll: result.roll ?? 0,
            pitch: result.pitch ?? 0,
            yaw: result.yaw ?? 0
        )
        
        model.perform(action: .faceGeometryDetected(faceGeometry))
    }
    
    
    /// detectedFaceQualityRequest returns the captured face quality between 0 and 1.
    /// - Parameters:
    ///     - request: a vision framework VNRequest
    ///     - error: error, if any
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
    
    
    func saveCapturedPhoto(from pixelBuffer: CVPixelBuffer) {
        guard
            let model = cameraViewModel
        else {
            return
        }
        
        
        imageProcessingQueue.async { [self] in
            let originalImage = CIImage(cvPixelBuffer: pixelBuffer)

            let coreImageWidth = originalImage.extent.width
            let coreImageHeight = originalImage.extent.height
            let desiredImageHeight = coreImageWidth * 4 / 3

            // Calculate frame of photo
            let yOrigin = (coreImageHeight - desiredImageHeight) / 2
            let photoRect = CGRect(x: 0, y: yOrigin, width: coreImageWidth, height: desiredImageHeight)
            
  
            let context = CIContext()
            if let cgImage = context.createCGImage(originalImage, from: photoRect) {
                
                
                
                switch model.faceObservationState {
                case .faceFound(let faceGeo):
                    
                    let capturedPhoto = UIImage(cgImage: cgImage, scale: 1, orientation: .upMirrored)
                    let imageViewScale = max(capturedPhoto.size.width / UIScreen.screenWidth,
                                             capturedPhoto.size.height / UIScreen.screenHeight / 2)
                    
                    let cropZone = CGRect(
                        x:(faceGeo.boundingBox.origin.x + PreviewLayerFrameConstant.yOffset),
                        y: (UIScreen.screenHeight - faceGeo.boundingBox.origin.y)/2,
                        width:faceGeo.boundingBox.size.width * imageViewScale + PreviewLayerFrameConstant.yOffset,
                        height:(faceGeo.boundingBox.size.height + PreviewLayerFrameConstant.yOffset) * imageViewScale)
                    
                    if let cutImageRef: CGImage = capturedPhoto.cgImage?.cropping(to:cropZone) {
                        let cropped = UIImage(cgImage: cutImageRef)
                        DispatchQueue.main.async {
                            model.perform(action: .savePhoto(cropped))
                        }
                    }
                    
                default:
                    break
                }
            }
        }
    }
}

