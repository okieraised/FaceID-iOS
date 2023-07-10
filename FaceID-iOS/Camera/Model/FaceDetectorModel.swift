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


        currentFrameBuffer = pixelBuffer
        do {
            try sequenceHandler.perform(
                [detectFaceRectanglesRequest, detectCaptureQualityRequest],
                on: pixelBuffer,
                orientation: .leftMirrored
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
//        faceIDHandler(buffer: pixelBuffer)
//        faceLivenessHandler(buffer: pixelBuffer)
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
            if let resizedBuffer = scaleImage(pixelBuffer: buffer, width: FaceIDModel.InputImageSize, height: FaceIDModel.InputImageSize) {
                if let vector = try? faceIDModel.detectFaceID(buffer: resizedBuffer) {
                    model.perform(action: .faceVectorDetected(FaceVectorModel(vector: vector)))
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
        
        model.perform(action: .faceLivenessDetected(faceLiveness))
    }
    
    
    
    func saveCapturedPhoto(from pixelBuffer: CVPixelBuffer) {
        guard
            let model = cameraViewModel, let viewDelegate = viewDelegate
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
            
            
            let newSize = CGSize(width: PreviewLayerFrameConstant.Frame.width, height: PreviewLayerFrameConstant.Frame.height)
            let newImage = ciImage.transformed(by: CGAffineTransform(scaleX: newSize.width / ciImage.extent.width, y: newSize.height / ciImage.extent.height))

            let bbox = viewDelegate.convertFromMetadataToPreviewRect(rect: bBox)
            let cropped = newImage.cropped(to: bbox)


            if let cgImage = context.createCGImage(newImage, from: cropped.extent) {
                let uiImage = UIImage(cgImage: cgImage, scale: 1.5, orientation: .upMirrored)
                DispatchQueue.main.async {
                    model.perform(action: .savePhoto(uiImage))
                }
            }
            
            
            //-----------------------------------------------------------
            
//            let ciImage = CIImage(cvPixelBuffer: currentFrameBuffer!)
//            let resizeFilter = CIFilter(name:"CILanczosScaleTransform")!
//
//            // Desired output size
//
//            // Compute scale and corrective aspect ratio
//            let scale = PreviewLayerFrameConstant.Frame.height / (ciImage.extent.height)
//            let aspectRatio = PreviewLayerFrameConstant.Frame.width / ((ciImage.extent.width) * scale)
//
//            // Apply resizing
//            resizeFilter.setValue(ciImage, forKey: kCIInputImageKey)
//            resizeFilter.setValue(scale, forKey: kCIInputScaleKey)
//            resizeFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey) // kCIInputAspectRatioKey
//            if let outputImage = resizeFilter.outputImage {
//                let bbox = viewDelegate.convertFromMetadataToPreviewRect(rect: bBox)
//                let cropped = outputImage.cropped(to: bbox)
//                if let cgImage = context.createCGImage(outputImage, from: cropped.extent) {
//                    let uiImage = UIImage(cgImage: cgImage, scale: 1, orientation: .upMirrored)
//                    DispatchQueue.main.async {
//                        model.perform(action: .savePhoto(uiImage))
//                    }
//                }
//            }
            
            //-----------------------------------------------------------
            // Current OK
            //-----------------------------------------------------------
//            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//            let width = ciImage.extent.width
//            let height = ciImage.extent.height
//
//            let desiredImageHeight = width * 4 / 3
//            let yOrigin = (height - desiredImageHeight) / 2
//            let photoRect = CGRect(x: 0, y: yOrigin, width: width, height: desiredImageHeight)
//
//            let context = CIContext()
//
//            if let cgImage = context.createCGImage(ciImage, from: photoRect) {
//                let uiImage = UIImage(cgImage: cgImage, scale: 1, orientation: .upMirrored)
//                DispatchQueue.main.async {
//                    model.perform(action: .savePhoto(uiImage))
//                }
//            }
            //-----------------------------------------------------------
            // End current
            //-----------------------------------------------------------
            
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
    
    private func scaleImage(pixelBuffer: CVPixelBuffer, width: Int, height: Int) -> CVPixelBuffer? {
        
        guard
            let viewDelegate = viewDelegate
        else {
            return nil
        }
        
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        
        let newSize = CGSize(width: PreviewLayerFrameConstant.Frame.width, height: PreviewLayerFrameConstant.Frame.height)
        let newImage = ciImage.transformed(by: CGAffineTransform(scaleX: newSize.width / ciImage.extent.width, y: newSize.height / ciImage.extent.height))
        
        let bbox = viewDelegate.convertFromMetadataToPreviewRect(rect: bBox)
        let cropped = newImage.cropped(to: bbox)
        
        
        if let cgImage = context.createCGImage(newImage, from: cropped.extent) {
            guard
                let convertedBuffer = cgImage.pixelBuffer()
            else {
                return nil
            }

            return resizePixelBuffer(convertedBuffer, width: width, height: height)
        }
        
        return nil
    }
    
    private func scaleImage2(pixelBuffer: CVPixelBuffer, width: Int, height: Int) -> CVPixelBuffer? {
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        let box = bBox.scaledForCropping(to: ciImage.extent.size)
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

        return resizePixelBuffer(convertedBuffer, width: width, height: height)
    }
    
    private func scaleImage3(pixelBuffer: CVPixelBuffer, width: Int, height: Int) -> CVPixelBuffer? {
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        guard
            let resizeFilter = CIFilter(name:"CILanczosScaleTransform"), let viewDelegate = viewDelegate
        else {
            return nil
        }

        let scale = PreviewLayerFrameConstant.Frame.height / (ciImage.extent.height)
        let aspectRatio = PreviewLayerFrameConstant.Frame.width / ((ciImage.extent.width) * scale)

        resizeFilter.setValue(ciImage, forKey: kCIInputImageKey)
        resizeFilter.setValue(scale, forKey: kCIInputScaleKey)
        resizeFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
        
        if let resizedCIImage = resizeFilter.outputImage {
            let bbox = viewDelegate.convertFromMetadataToPreviewRect(rect: bBox)
            
            let cropped = resizedCIImage.cropped(to: bbox)
            
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
        
        return nil
    }
}
