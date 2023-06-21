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

enum FaceBoundsState {
    case unknown
    case detectedFaceTooSmall
    case detectedFaceTooLarge
    case detectedFaceOffCentre
    case faceObstructed
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
    case takePhoto
    case savePhoto(UIImage)
}

final class CameraViewModel: ObservableObject {
    
    let shutterReleased = PassthroughSubject<Void, Never>()
    
    // MARK: - Published Variables
    
    @Published private(set) var passportPhoto: UIImage?
    @Published private(set) var faceObservationState: FaceObservationState<FaceGeometryModel> {
        didSet {
            processUpdatedFaceGeometry()
            print(faceObservationState)
            
        }
    }
    
    @Published private(set) var faceQualityState: FaceObservationState<FaceQualityModel> {
      didSet {
          print(faceQualityState)
      }
    }
    
    func processUpdatedFaceGeometry() {
        switch faceObservationState {
        case .faceFound(let faceGeometryModel):
            let boundingBox = faceGeometryModel.boundingBox
            let roll = faceGeometryModel.roll.doubleValue
            let pitch = faceGeometryModel.pitch.doubleValue
            let yaw = faceGeometryModel.yaw.doubleValue
        case .faceNotFound:
            break
        case .errored(let error):
            print("\(error.localizedDescription)")
            break
        }

    }
    
    // MARK: - Init
    
    init() {
        faceObservationState = .faceNotFound
        faceQualityState = .faceNotFound
    }
    
    // MARK: - Public Methods
    
    func perform(action: CameraAction) {
        switch action {
        case .faceGeometryDetected(let faceGeometry):
            publishFaceGeometryObservation(faceGeometry)
            print(faceGeometry)
            break
        case .faceQualityDetected(let faceQuality):
            publishFaceQualityObservation(faceQuality)
            print(faceQuality)
            break
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
            passportPhoto = photo
        }
    }
    
    private func publishNoFaceObserved() {
        DispatchQueue.main.async { [self] in
            faceObservationState = .faceNotFound
            faceQualityState = .faceNotFound
        }
    }
    
    private func publishFaceGeometryObservation(_ faceGeometry: FaceGeometryModel) {
        DispatchQueue.main.async { [self] in
            faceObservationState = .faceFound(faceGeometry)
        }
    }
    
    private func publishFaceQualityObservation(_ faceQuality: FaceQualityModel) {
        DispatchQueue.main.async { [self] in
            faceQualityState = .faceFound(faceQuality)
        }
    }
    
}

// MARK: - Extensions

extension CameraViewModel {
    
}