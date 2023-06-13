//
//  FaceDetection.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/13/23.
//

import Foundation

enum FaceBoundsState {
    case unknown
    case detectedFaceTooSmall
    case detectedFaceTooLarge
    case faceObstructed
    case detectedFaceOK
}

enum FaceObservationState<T> {
    case faceFound(T)
    case faceNotFound
    case errored(Error)
}

enum FaceDetectedState {
    case faceDetected
    case noFaceDetected
    case faceDetectionErrored
}
