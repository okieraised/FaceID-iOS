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

struct FaceVectorModel {
    var vector: [Float32]
}

enum FaceBoundsState {
    case faceNotFound
    case detectedFaceTooSmall
    case detectedFaceTooLarge
    case detectedFaceOffCentre
    case faceOK
}

enum FaceLivenessState {
    case faceObstructed
    case faceSpoofed
    case faceOK
}

enum FacePositionState {
    case Left
    case Right
    case Up
    case Down
    case Straight
    case faceNotFound
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
    case faceVectorDetected(FaceVectorModel)
    case takePhoto
    case savePhoto(UIImage)
}

final class CameraViewModel: ObservableObject {
    
    
    var isEnrollMode: Bool
    var reEnroll: Bool
    
    var straightFacePositionTaken: Bool = false
    var leftSideFacePositionTaken: Bool = false
    var rightSideFacePositionTaken: Bool = false
    
    
    
    // MARK: - Variables
    @Published var capturedIndices: Set<Int>
    @Published var captureMode: Bool = false
    
    
    @Published private(set) var capturedPhoto: UIImage?
    @Published private(set) var hasDetectedValidFace: Bool
    @Published private var hasDetectedValidFaceUnthrottled: Bool = false
    @Published private var faceLivenessUnthrottled: FaceLivenessState = .faceObstructed
    @Published private var faceVectorUnthrottled: FaceVectorModel = FaceVectorModel(vector: [])
    
    
    // These three variables handles the throttling of face liveliness and geometry
    // so the screen does not flicker at boundary values
    let shutterReleased = PassthroughSubject<Void, Never>()
    let throttleDelay = 0.5
    let throttleReleased = PassthroughSubject<Bool, Never>()
    var throttleSubscriber = Set<AnyCancellable>()
    
    
    @Published private(set) var enrolled: Bool
    private var savedVector: [FaceVector]
    
    @Published var enrollFinished: Bool = false
    @Published var checkinFinished: Bool = false
    @Published var checkinOK: Bool = false
    
    
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
            updateFaceValidity()
        }
    }
    
    
    
    @Published private(set) var faceQuality: Bool {
        didSet {
            updateFaceValidity()
        }
    }
    
    @Published private(set) var faceVector: FaceVectorModel {
        didSet {
            updateFaceVector()
        }
    }
    
    @Published private(set) var facePosition: FacePositionState
    
    // MARK: - Init
    
    init(isEnrollMode: Bool, reEnroll: Bool) {
        self.isEnrollMode = isEnrollMode
        self.reEnroll = reEnroll
        
        
        faceGeometryObservation = .faceNotFound
        faceQualityObservation = .faceNotFound
        faceLivenessObservation = .faceNotFound
        
        hasDetectedValidFace = false
        captureMode = false
        faceQuality = false
        faceBounds = .faceNotFound
        faceLiveness = .faceObstructed
        facePosition = .faceNotFound
        capturedIndices = []
        faceVector = FaceVectorModel(vector: [])
        
        savedVector = PersistenceController.shared.getFaceVector()
        
        if savedVector.count == 0 {
            enrolled = false
        } else {
            enrolled = true
        }
        
        $hasDetectedValidFaceUnthrottled
            .throttle(for: .seconds(throttleDelay), scheduler: DispatchQueue.main, latest: true)
            .sink(receiveValue: { [weak self] value in
                self?.hasDetectedValidFace = value
                if value {
                    self?.captureMode = true
                } else {
                    self?.captureMode = false
                }
            })
            .store(in: &throttleSubscriber)
        
        $faceLivenessUnthrottled
            .throttle(for: .seconds(throttleDelay), scheduler: DispatchQueue.main, latest: true)
            .sink(receiveValue: { [weak self] value in
                self?.faceLiveness = value
            })
            .store(in: &throttleSubscriber)
        
        $faceVectorUnthrottled
            .throttle(for: .seconds(throttleDelay), scheduler: DispatchQueue.main, latest: true)
            .sink(receiveValue: { [weak self] value in
                self?.faceVector = value
            })
            .store(in: &throttleSubscriber)
        
    }
    
    // MARK: - Functions
    
    func processUpdatedFaceGeometry() {
        switch faceGeometryObservation {
        case .faceFound(let faceGeometryModel):
            let boundingBox = faceGeometryModel.boundingBox
            let roll = faceGeometryModel.roll.doubleValue
            let pitch = faceGeometryModel.pitch.doubleValue
            let yaw = faceGeometryModel.yaw.doubleValue
            
            print("roll: \(String(format: "%.2f", roll)) | pitch: \(String(format: "%.2f", pitch)) | yaw: \(String(format: "%.2f", yaw))")
            
            updateAcceptableBounds(using: boundingBox)
            
            if isValidStraightFace(roll: roll, pitch: pitch, yaw: yaw) {
                facePosition = .Straight
            } else {
                facePosition = .faceNotFound
            }
            
            if isEnrollMode {
                updateFaceCaptureProgress(yaw: yaw, pitch: pitch)
                
            } else {
                if isValidLeftFace(yaw: yaw) {
                    leftSideFacePositionTaken = true
                }
                
                if isValidRightFace(yaw: yaw) {
                    rightSideFacePositionTaken = true
                }
            }
        
        case .faceNotFound:
            invalidateFaceGeometry()
        case .errored(let error):
            print("\(error.localizedDescription)")
            invalidateFaceGeometry()
        }
    }
    
    func processUpdatedFaceQuality() {
        switch faceQualityObservation {
        case .faceFound(let faceQualityModel):
            if faceQualityModel.quality < 0.2 {
                faceQuality = false
            } else {
                faceQuality = true
            }
        case .faceNotFound:
            faceQuality = false
        case .errored(let error):
            print("\(error.localizedDescription)")
            faceQuality = false
        }
    }
    
    func processUpdatedFaceLiveness() {
        switch faceLivenessObservation {
        case .faceFound(let livenessModel):
            updateAcceptableLiveness(using: livenessModel)
        case .faceNotFound:
            invalidateFaceGeometry()
        case .errored(let error):
            print("\(error.localizedDescription)")
            invalidateFaceGeometry()
        }
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
        case .faceVectorDetected(let faceVector):
            publishFaceVectorObservation(faceVector)
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
        switch facePosition {
        case .Straight:
            if !straightFacePositionTaken && captureMode {
                shutterReleased.send()
                straightFacePositionTaken = true
            }
        default:
            break
        }
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
    
    private func publishFaceVectorObservation(_ faceVector: FaceVectorModel) {
        DispatchQueue.main.async { [self] in
            
            faceVectorUnthrottled = faceVector
            
            if isEnrollMode {
                if captureMode {
                    if !enrolled && facePosition == .Straight {
                        
                        PersistenceController.shared.saveFaceVector(vector: faceVector.vector)
                        print("got here 1")
                    } else {
                        if reEnroll && facePosition == .Straight {
                            PersistenceController.shared.updateFaceVector(entity: savedVector[0], vector: faceVector.vector)
                            print("got here 2")
                            reEnroll = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Extensions

extension CameraViewModel {
    
    func invalidateFaceGeometry() {
        hasDetectedValidFace = false
        captureMode = false
        faceQuality = false
        faceBounds = .faceNotFound
        faceLiveness = .faceObstructed
        facePosition = .faceNotFound
        straightFacePositionTaken = false
        leftSideFacePositionTaken = false
        rightSideFacePositionTaken = false
        capturedIndices = []
        enrollFinished = false
        checkinFinished = false
    }
    
    func updateFaceValidity() {
        hasDetectedValidFaceUnthrottled = (faceBounds == .faceOK &&
                                           faceLiveness == .faceOK &&
                                           faceQuality)
    }
    
    func updateFaceVector() {
        if !checkinFinished {
            if leftSideFacePositionTaken && rightSideFacePositionTaken && hasDetectedValidFace {
                if facePosition == .Straight {
                    if let enrolledFaceVector = savedVector[0].vector {
                        let currentFaceVector = faceVector.vector
                        let similarity = cosineSim(A: enrolledFaceVector, B: currentFaceVector)
                        print("similarity: \(round(similarity * 10) / 10.0)")
                        if round(similarity * 10) / 10.0 >= 0.6 {
                            checkinFinished = true
                            checkinOK = true
                        } else {
                            checkinFinished = true
                            checkinOK = false
                        }
                    }
                }
            }
        }
    }
    
    func updateAcceptableBounds(using boundingBox: CGRect) {
        if boundingBox.width > 1.3 * FaceCaptureConstant.LayoutGuideWidth {
            faceBounds = .detectedFaceTooLarge
        } else if boundingBox.width < FaceCaptureConstant.LayoutGuideHeight * 0.5 {
            faceBounds = .detectedFaceTooSmall
        } else {
            faceBounds = .faceOK
        }
    }
    
    func updateAcceptableLiveness(using liveness: FaceLivenessModel) {
        if liveness.spoofed && liveness.obstructed {
            faceLivenessUnthrottled = .faceObstructed
        } else {
            if liveness.spoofed {
                faceLivenessUnthrottled = .faceSpoofed
            } else {
                if liveness.obstructed {
                    faceLivenessUnthrottled = .faceObstructed
                } else {
                    faceLivenessUnthrottled = .faceOK
                }
            }
        }
    }
}

extension CameraViewModel {
    
    private func isValidStraightFace(roll: Double, pitch: Double, yaw: Double) -> Bool {
        return (
            hasDetectedValidFace &&
            isValidNeutralPitch(pitch: pitch) &&
            isValidNeutralYaw(yaw: yaw) &&
            isValidNeutralRoll(roll: roll)
        )
    }
    
    private func isValidTopFace() {
        
    }
    
    private func isValidBottomFace() {
        
    }
    
    private func isValidRightFace(yaw: Double) -> Bool {
        return yaw > 0.2
    }
    
    private func isValidLeftFace(yaw: Double) -> Bool {
        return yaw < -0.1
    }
    

    private func isValidNeutralRoll(roll: Double) -> Bool {
        return (roll >= 1.4 && roll <= 1.70)
    }
    
    
    func isValidNeutralYaw(yaw: Double) -> Bool  {
        return (yaw >= -0.1 && yaw <= 0.2)
    }
    
    func isValidNeutralPitch(pitch: Double) -> Bool {
        return (pitch >= -0.2 && pitch <= 0.2)
    }
    
    private func updateFaceCaptureProgress(yaw: Double, pitch: Double) {
        if captureMode {
            
            let localCoord = atan2(yaw, pitch)
            let dLocalCoord = rad2deg(localCoord) + 180
            let dProgress = dLocalCoord / Double(FaceCaptureConstant.FullCircle / FaceCaptureConstant.MaxProgress)
            
            if abs(Int(dProgress)) > FaceCaptureConstant.MaxProgress - 1 {
                return
            }
            
            capturedIndices.insert(abs(Int(dProgress)))
            
            if capturedIndices.count == FaceCaptureConstant.MaxProgress && straightFacePositionTaken {
                enrollFinished = true
            }
            
            print("capturedIndices len: \(self.capturedIndices.count)")
            print("capturedIndices: \(self.capturedIndices.sorted())")
        }
    }
}
