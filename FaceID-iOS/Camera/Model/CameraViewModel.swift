//
//  CameraViewModel.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/15/23.
//

import Combine
import Foundation
import os
import UIKit


/// FaceGeometryModel defines the numeric representation of the captured face
///  - boundingBox: [CGRect] The rectangle that defines the boundary of the captured face
///  - roll: [NSNumber] the roll value in radian
///  - pitch: [NSNumber] the pitch value in radian
///  - yaw: [NSNumber] the yaw value in radian
struct FaceGeometryModel {
    let boundingBox: CGRect
    let roll: NSNumber
    let pitch: NSNumber
    let yaw: NSNumber
}

/// FaceQualityModel defines the numeric representation of the face quality
/// - quality: [Float] The numeric value of face quality from 0 to 1
struct FaceQualityModel {
  let quality: Float
}

/// FaceLivenessModel defines the detection result of AntiSpoofing model and FaceMask model for the captured face
/// - spoofed: [Bool] Boolean value indicating if the face is spoofed
/// - obstructed: [Bool] Boolean value indicating if the face is covered
struct FaceLivenessModel {
    var spoofed: Bool
    var obstructed: Bool
}

/// FaceVectorModel defines the extracted array of the captured face
/// - vector: [Float32]: Array of 512 elements of float32 type that represents the captured face
struct FaceVectorModel {
    var vector: [Float32]
}

/// FaceBoundsState defines the state of the bounding box of the captured face
/// - faceNotFound: No face detected
/// - detectedFaceTooSmall: Face too small compared to the capture border
/// - detectedFaceTooLarge: Face too large compared to the captured border
/// - detectedFaceOffCentre: Face is not aligned to  the captured border
/// - faceOK: Face is appropriately within the capture border
enum FaceBoundsState {
    case faceNotFound
    case detectedFaceTooSmall
    case detectedFaceTooLarge
    case detectedFaceOffCentre
    case faceOK
}

/// FaceLivenessState defines the state of the captured face quality
/// - faceObstructed: face is covered/missing
/// - faceSpoofed: face is not real
/// - faceOK: Face is appropriate
enum FaceLivenessState {
    case faceObstructed
    case faceSpoofed
    case faceOK
}

/// FacePositionState defines the direction the captured face is facing
/// - Left: Face is looking left
/// - Right: Face is looking right
/// - Up: Face is looking up
/// - Down: Face is looking down
/// - Straight: Face is facing the camera directly
/// - FaceNotFound: No face detected
enum FacePositionState {
    case Left
    case Right
    case Up
    case Down
    case Straight
    case faceNotFound
}

/// FaceObservationState defines the observation stated of the captured face
/// - faceFound(T): Face is detected: can be quality, liveness, or geometry
/// - faceNotFound: No face detected
/// - errored(Error): Face detection encounters error
enum FaceObservationState<T> {
  case faceFound(T)
  case faceNotFound
  case errored(Error)
}

/// CameraAction defines the action to perform with detected face
/// - noFaceDetected: Do nothing
/// - faceGeometryDetected(FaceGeometryModel): Handles the numeric representation of the captured face geometry
/// - faceQualityDetected(FaceQualityModel): Handles the numeric representation of the captured face quality
/// - faceLivenessDetected(FaceLivenessModel): Handles the result of the captured face AI models
/// - faceVectorDetected(FaceVectorModel): Handles the result of the captured face vector array
/// - takePhoto: Takes the photo of the captured face
/// - savePhoto(UIImage): Saves the photo to the library
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
    
    // MARK: - Variables
    
    /// logger is the main logging variable
    private let logger = Logger(subsystem: "vinbigdata.face.id.log", category: "faceid")
    
    /// isEnrollMode indicates if the mode is enrollment. If true, the mode is enrollment, if false, the mode is checkin
    var isEnrollMode: Bool
    
    /// reEnroll indicates if we want to replace the current stored face vector. Only matters if isEnrollMode is true
    var reEnroll: Bool
    
    /// enrolled indicates if user has already enrolled his/her face
    @Published private(set) var enrolled: Bool
    
    /// enrollFinished indicates if the user has finished enrolling his/her face
    @Published var enrollFinished: Bool = false
    
    /// checkinFinished indicates if the user has finished checking-in his/her face
    @Published var checkinFinished: Bool = false
    
    /// checkinOK indicates if the captured face matched the face stored in the database.
    /// true if the checkin is successful, otherwise false
    @Published var checkinOK: Bool = false
    
    /// straightFacePositionTaken indicates if the picture of user looking directly to the camera is taken.
    private var straightFacePositionTaken: Bool = false
    
    /// leftSideFacePositionTaken indicates if the picture of user looking left to the camera is taken.
    private var leftSideFacePositionTaken: Bool = false
    
    /// rightSideFacePositionTaken indicates if the picture of user looking right to the camera is taken.
    private var rightSideFacePositionTaken: Bool = false
    
    /// captureMode indicates if the camera is in the capture mode with progress bar
    @Published var captureMode: Bool = false
    
    /// capturedIndices holds the angle values that the camera has captured
    @Published var capturedIndices: Set<Int>
    
    /// capturedPhoto holds the captured face as UIImage
    @Published private(set) var capturedPhoto: UIImage?
    
    /// hasDetectedValidFace indicates if the captured face is valid
    @Published private(set) var hasDetectedValidFace: Bool
    
    /// hasDetectedValidFaceUnthrottled publishes the valid face value
    @Published private var hasDetectedValidFaceUnthrottled: Bool = false
    
    /// faceLivenessUnthrottled publishes the face liveness detection
    @Published private var faceLivenessUnthrottled: FaceLivenessState = .faceObstructed
    
    /// faceVectorUnthrottled publishes the face vector
    @Published private var faceVectorUnthrottled: FaceVectorModel = FaceVectorModel(vector: [])
    
    /// shutterReleased used for taking and saving photo
    let shutterReleased = PassthroughSubject<Void, Never>()
    
    /// throttleDelay indicates the interval between each update
    private let throttleDelay = 1
    
    /// throttleSubscriber is the subscriber for throttling published values
    private var throttleSubscriber = Set<AnyCancellable>()
    
    /// savedVector keeps the captured face array in CoreData
    private var savedVector: [FaceVector]
    
    /// faceGeometryObservation publishes the face geometry values
    @Published private(set) var faceGeometryObservation: FaceObservationState<FaceGeometryModel> {
        didSet {
            processUpdatedFaceGeometry()
        }
    }
    
    /// faceQualityObservation publishes the face quality value
    @Published private(set) var faceQualityObservation: FaceObservationState<FaceQualityModel> {
        didSet {
            processUpdatedFaceQuality()
        }
    }
    
    /// faceLivenessObservation publishes the face liveness detection value
    @Published private(set) var faceLivenessObservation: FaceObservationState<FaceLivenessModel> {
        didSet {
            processUpdatedFaceLiveness()
        }
    }

    /// faceBounds publishes the state of the captured face bounding box
    @Published private(set) var faceBounds: FaceBoundsState {
        didSet {
            updateFaceValidity()
        }
    }

    /// faceLiveness publishes the state of the captured face AI model
    @Published private(set) var faceLiveness: FaceLivenessState {
        didSet {
            updateFaceValidity()
        }
    }
    
    /// faceQuality publishes the state of the face quality
    @Published private(set) var faceQuality: Bool {
        didSet {
            updateFaceValidity()
        }
    }
    
    /// faceVector publishes the state of the face vector
    @Published private(set) var faceVector: FaceVectorModel {
        didSet {
            updateFaceVector()
        }
    }
    
    /// facePosition publishes the state of the face position
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
            enrolled = false // User needs to enroll first
        } else {
            enrolled = true // User already enroll
        }
        
        //-------------------------------------------------------------------------------------------------
        // We throttle these variables to prevent flickering at the border value.
        // We only publish the latest value of these captured variables at 0.5 seconds interval
        //-------------------------------------------------------------------------------------------------
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
        //-------------------------------------------------------------------------------------------------
        // End
        //-------------------------------------------------------------------------------------------------
        
    }
    
    
    // MARK: - Functions
    
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
}

// MARK: - Extensions

extension CameraViewModel {
    
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
        }
    }
}

extension CameraViewModel {
    
    private func processUpdatedFaceGeometry() {
        
        switch faceGeometryObservation {
        case .faceFound(let faceGeometryModel):
            let boundingBox = faceGeometryModel.boundingBox
            let roll = faceGeometryModel.roll.doubleValue
            let pitch = faceGeometryModel.pitch.doubleValue
            let yaw = faceGeometryModel.yaw.doubleValue
            
            logger.info("roll: \(String(format: "%.2f", roll)) | pitch: \(String(format: "%.2f", pitch)) | yaw: \(String(format: "%.2f", yaw))")
            
            updateAcceptableBounds(using: boundingBox)
            
            if isValidStraightFace(roll: roll, pitch: pitch, yaw: yaw) {
                facePosition = .Straight
            } else {
                facePosition = .faceNotFound
            }
            
            // if enroll mode, we capture the progress. If checkin mode, we check if user has turned left to right
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
            logger.error("\(error.localizedDescription)")
            invalidateFaceGeometry()
        }
    }
    
    
    private func processUpdatedFaceQuality() {
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
            logger.error("\(error.localizedDescription)")
            faceQuality = false
        }
    }
    
    
    private func processUpdatedFaceLiveness() {
        switch faceLivenessObservation {
        case .faceFound(let livenessModel):
            updateAcceptableLiveness(using: livenessModel)
        case .faceNotFound:
            invalidateFaceGeometry()
        case .errored(let error):
            logger.error("\(error.localizedDescription)")
            invalidateFaceGeometry()
        }
    }
}

extension CameraViewModel {
    
    private func invalidateFaceGeometry() {
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
//        enrollFinished = false
//        checkinFinished = false
    }
    
    private func updateFaceValidity() {
        hasDetectedValidFaceUnthrottled = (faceBounds == .faceOK &&
                                           faceLiveness == .faceOK &&
                                           faceQuality)
    }
    
    private func updateFaceVector() {
        if isEnrollMode {
            if captureMode {
                if !enrolled && facePosition == .Straight {
                    PersistenceController.shared.saveFaceVector(vector: faceVector.vector)
                } else {
                    if reEnroll && facePosition == .Straight {
                        PersistenceController.shared.updateFaceVector(entity: savedVector[0], vector: faceVector.vector)
                        reEnroll = false
                    }
                }
            }
        } else {
            if !checkinFinished && leftSideFacePositionTaken &&
                rightSideFacePositionTaken && hasDetectedValidFace &&
                facePosition == .Straight && captureMode {
                
                let currentFaceVector = faceVector.vector
                
                if let enrolledFaceVector = savedVector[0].vector {
                    let similarity = round(cosineSim(A: enrolledFaceVector,
                                                     B: currentFaceVector) * 10) / 10.0
                    logger.info("similarity value: \(similarity)")
                    
                    if similarity >= 0.6 {
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
    
    private func updateAcceptableBounds(using boundingBox: CGRect) {
        if boundingBox.width > 1.3 * FaceCaptureConstant.LayoutGuideWidth {
            faceBounds = .detectedFaceTooLarge
        } else if boundingBox.width < FaceCaptureConstant.LayoutGuideHeight * 0.3 {
            faceBounds = .detectedFaceTooSmall
        } else {
            faceBounds = .faceOK
        }
    }
    
    private func updateAcceptableLiveness(using liveness: FaceLivenessModel) {
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
            
            logger.debug("capturedIndices len: \(self.capturedIndices.count)")
            logger.debug("capturedIndices: \(self.capturedIndices.sorted())")
        }
    }
}
