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
//    let boundingBox: CGRect
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
    
    @Published private(set) var passportPhoto: UIImage?
    @Published private(set) var faceObservationState: FaceObservationState<FaceGeometryModel> {
        didSet {
            print(faceObservationState)
        }
    }
    
    @Published private(set) var faceQualityState: FaceObservationState<FaceQualityModel> {
      didSet {
          print(faceQualityState)
      }
    }
    
    init() {
        print("init camera view model")
        faceObservationState = .faceNotFound
        faceQualityState = .faceNotFound
    }
    
    func perform(action: CameraAction) {
        switch action {
        case .faceGeometryDetected(let faceGeometry):
            print(faceGeometry)
            break
        case .faceQualityDetected(let faceQuality):
            print(faceQuality)
            break
        case .takePhoto:
            takePhoto()
        case .savePhoto(let image):
            savePhoto(image)
        case .noFaceDetected:
            break
        }
    }
    
    private func takePhoto() {
        shutterReleased.send()
    }
    
    private func savePhoto(_ photo: UIImage) {
        UIImageWriteToSavedPhotosAlbum(photo, nil, nil, nil)
        DispatchQueue.main.async { [self] in
            passportPhoto = photo
        }
    }
    
    
    
    
}
