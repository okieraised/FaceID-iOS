//
//  CameraViewModel.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/15/23.
//

import Combine
import Foundation
import UIKit


struct FaceGeometryModel {
    let boundingBox: CGRect
    let roll: NSNumber
    let pitch: NSNumber
    let yaw: NSNumber
}

struct FaceQualityModel {
  let quality: Float
}

struct FaceLivenessModel {
    var spoofed: Bool
    var obstructed: Bool
}

enum FaceBoundsState {
    case faceNotFound
    case detectedFaceTooSmall
    case detectedFaceTooLarge
    case detectedFaceOffCentre
    case faceObstructed
    case faceSpoofed
    case faceOK
}

enum FaceLivenessState {
    case faceNotFound
    case faceObstructed
    case faceSpoofed
    case faceOK
}


enum FaceObservationState<T> {
  case faceFound(T)
  case faceNotFound
  case errored(Error)
}

enum CameraAction {
    case noFaceDetected
    case faceGeometryDetected(FaceGeometryModel)
    case faceQualityDetected(FaceQualityModel)
    case faceLivenessDetected(FaceLivenessModel)
    case takePhoto
    case savePhoto(UIImage)
}

final class CameraViewModel: ObservableObject {
    
    let shutterReleased = PassthroughSubject<Void, Never>()
    
    // MARK: - Published Variables
    
    @Published private(set) var capturedPhoto: UIImage?
    
    @Published private(set) var isAcceptableQuality: Bool {
        didSet {
            print(isAcceptableQuality)
        }
    }
    
    
    @Published private(set) var faceGeometryObservation: FaceObservationState<FaceGeometryModel> {
        didSet {
            processUpdatedFaceGeometry()
        }
    }
    
    @Published private(set) var faceQualityObservation: FaceObservationState<FaceQualityModel> {
        didSet {
            processUpdatedFaceQuality()
        }
    }
    
    @Published private(set) var faceLivenessObservation: FaceObservationState<FaceLivenessModel> {
        didSet {
            processUpdatedFaceLiveness()
        }
    }


    @Published private(set) var faceBounds: FaceBoundsState {
        didSet {
            updateFaceValidity()
        }
    }

    @Published private(set) var faceLiveness: FaceLivenessState {
        didSet {
            print("haha")
        }
    }
    
    
    
    func processUpdatedFaceGeometry() {
        switch faceGeometryObservation {
        case .faceFound(let faceGeometry):
            let boundingBox = faceGeometry.boundingBox
            updateAcceptableBounds(using: boundingBox)
        case .faceNotFound:
            invalidateFaceGeometry()
        case .errored(let error):
            print("\(error.localizedDescription)")
            invalidateFaceGeometry()
        }
    }
    
    func processUpdatedFaceQuality() {
        switch faceQualityObservation {
        case .faceFound(let faceQuality):
            if faceQuality.quality < 0.3 {
                isAcceptableQuality = false
            } else {
                isAcceptableQuality = true
            }
        case .faceNotFound:
            isAcceptableQuality = false
        case .errored(let error):
            print("\(error.localizedDescription)")
            isAcceptableQuality = false
        }
    }
    
    func processUpdatedFaceLiveness() {
        switch faceLivenessObservation {
        case .faceFound(let liveness):
            updateAcceptableLiveness(using: liveness)
        case .faceNotFound:
            invalidateFaceGeometry()
        case .errored(let error):
            print("\(error.localizedDescription)")
            invalidateFaceGeometry()
        }
    }
    
    // MARK: - Init
    
    init() {
        faceGeometryObservation = .faceNotFound
        faceQualityObservation = .faceNotFound
        faceLivenessObservation = .faceNotFound
        
        
        
        isAcceptableQuality = false
        faceBounds = .faceNotFound
        faceLiveness = .faceNotFound
    }
    
    // MARK: - Public Methods
    
    func perform(action: CameraAction) {
        switch action {
        case .faceGeometryDetected(let faceGeometry):
            publishFaceGeometryObservation(faceGeometry)
        case .faceQualityDetected(let faceQuality):
            publishFaceQualityObservation(faceQuality)
        case .faceLivenessDetected(let faceLiveness):
            publishFaceLivenessObservation(faceLiveness)
        case .takePhoto:
            takePhoto()
        case .savePhoto(let image):
            savePhoto(image)
        case .noFaceDetected:
            publishNoFaceObserved()
        }
    }
    
    // MARK: - Private Methods
    
    private func takePhoto() {
        shutterReleased.send()
    }
    
    private func savePhoto(_ photo: UIImage) {
        UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)
        DispatchQueue.main.async { [self] in
            capturedPhoto = photo
        }
    }
    
    private func publishNoFaceObserved() {
        DispatchQueue.main.async { [self] in
            faceGeometryObservation = .faceNotFound
            faceQualityObservation = .faceNotFound
            faceLivenessObservation = .faceNotFound
        }
    }
    
    private func publishFaceGeometryObservation(_ faceGeometry: FaceGeometryModel) {
        DispatchQueue.main.async { [self] in
            faceGeometryObservation = .faceFound(faceGeometry)
        }
    }
    
    private func publishFaceQualityObservation(_ faceQuality: FaceQualityModel) {
        DispatchQueue.main.async { [self] in
            faceQualityObservation = .faceFound(faceQuality)
        }
    }
    
    
    private func publishFaceLivenessObservation(_ faceLiveness: FaceLivenessModel) {
        DispatchQueue.main.async { [self] in
            faceLivenessObservation = .faceFound(faceLiveness)
        }
    }
    
}

// MARK: - Extensions

extension CameraViewModel {
    
    func invalidateFaceGeometry() {
//        faceGeometryObservation = .faceNotFound
//        faceQualityObservation = .faceNotFound
//        faceLivenessObservation = .faceNotFound
//        faceBounds = .faceNotFound
    }
    
    func updateFaceValidity() {
        
    }
    
    func updateAcceptableBounds(using boundingBox: CGRect) {
        if boundingBox.width > 1.1 * FaceCaptureConstant.LayoutGuideWidth {
            faceBounds = .detectedFaceTooLarge
            print("TOO BIG")
        } else if boundingBox.width  < FaceCaptureConstant.LayoutGuideHeight * 0.5 {
            faceBounds = .detectedFaceTooSmall
            print("TOO SMALL")
        } else {
            faceBounds = .faceOK
            print("OK")
        }
    }
    
    func updateAcceptableLiveness(using liveness: FaceLivenessModel) {
        if liveness.spoofed {
            faceLiveness = .faceSpoofed
        } else {
            if liveness.obstructed {
                faceLiveness = .faceObstructed
            } else {
                faceLiveness = .faceOK
            }
        }
    }
    
    func updateFaceCaptureProgress(yaw: Double, pitch: Double) {
        
    }
    
}
