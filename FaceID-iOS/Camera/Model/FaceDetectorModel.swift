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
    
    // MARK: - Processing Queue

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

        if isCapturingPhoto {
            isCapturingPhoto = false
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
                orientation: .leftMirrored
            )
        } catch {
            print(error.localizedDescription)
        }
        
        faceIDHandler(buffer: imageBuffer)
        faceLivenessHandler(buffer: imageBuffer)
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
        
        bBox = result.boundingBox
        
        let boundingBox = viewDelegate.convertFromMetadataToPreviewRect(rect: result.boundingBox)
        if round(abs(UIScreen.midY - boundingBox.midY)) < 50 ||
            round(abs(UIScreen.midY - boundingBox.midY)) > 300 ||
            round(abs(UIScreen.midX - boundingBox.midX)) > 130 ||
            round(boundingBox.midY) > 450 || round(boundingBox.midX) < 100 || round(boundingBox.midX) > 300 {
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
        
        if model.captureMode {
            if let resizedBuffer = scaleImage(pixelBuffer: buffer, width: FaceIDModel.InputImageSize, height: FaceIDModel.InputImageSize) {
                if let result = try? faceIDModel.detectFaceID(buffer: resizedBuffer) {
                    
                }
            }
        }
        
    }
    
    
    func faceLivenessHandler(buffer: CVPixelBuffer) {
        guard
            let model = cameraViewModel,
            let maskBuffer = scaleImage(pixelBuffer: buffer, width: FaceMaskModel.InputImageSize, height: FaceMaskModel.InputImageSize)
        else {
            return
        }
        
        var faceLiveness = FaceLivenessModel(spoofed: true, obstructed: true)
        if let maskResult = try? faceMaskModel.detectFaceMask(buffer: maskBuffer) {
            if let maxVal = maskResult.max() {
                faceLiveness.obstructed = (maxVal == maskResult[1] && maxVal != 0) ? false : true
            }
        }
        
        if let spoofingResult = try? faceAntiSpoofingModel.antiSpoofing(buffer: buffer) {
            faceLiveness.spoofed = (spoofingResult[1] < FaceAntiSpoofingModel.AntiSpoofingThreshold) ? true : false
        }
        
        print("faceLiveness: \(faceLiveness)")
        
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
            let width = ciImage.extent.width
            let height = ciImage.extent.height
            let desiredImageHeight = width * 4 / 3
            let yOrigin = (height - desiredImageHeight) / 2
            let photoRect = CGRect(x: 0, y: yOrigin, width: width, height: desiredImageHeight)

            let context = CIContext()
            if let cgImage = context.createCGImage(ciImage, from: photoRect) {
                let uiImage = UIImage(cgImage: cgImage, scale: 1, orientation: .upMirrored)
                DispatchQueue.main.async {
                    model.perform(action: .savePhoto(uiImage))
                }
            }
        }
    }
}

extension FaceDetector {
    private func scaleImage(pixelBuffer: CVPixelBuffer, width: Int, height: Int) -> CVPixelBuffer? {
        guard
            let viewDelegate = viewDelegate
        else {
            return nil
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let imageViewScale = max(ciImage.extent.width / UIScreen.screenWidth,
                                 ciImage.extent.size.height / UIScreen.screenHeight / 2)
        
        let converted = viewDelegate.convertFromMetadataToPreviewRect(rect: bBox)
        let cropZone = CGRect(
            x: (converted.origin.x + PreviewLayerFrameConstant.YOffset) + PreviewLayerFrameConstant.YOffset/2,
            y: (UIScreen.screenHeight - converted.origin.y + PreviewLayerFrameConstant.YOffset)/2,
            width: converted.size.width * imageViewScale + PreviewLayerFrameConstant.YOffset,
            height: (converted.size.height + PreviewLayerFrameConstant.YOffset) * imageViewScale)

        let cropped = ciImage.cropped(to: cropZone)
        let context = CIContext()
        
        guard
            let cgImage = context.createCGImage(cropped, from: cropped.extent)
        else {
            return nil
        }
        
        guard
            let convertedBuffer = cgImage.pixelBuffer()
        else {
            return nil
        }
        
        return resizePixelBuffer(convertedBuffer, width: width, height: height)
    }
}
