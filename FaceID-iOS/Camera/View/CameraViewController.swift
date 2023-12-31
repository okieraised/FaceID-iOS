//
//  CameraViewController.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/13/23.
//

import Foundation
import AVFoundation
import UIKit

class CameraViewController: UIViewController {
    
    // MARK: - Enums
    
    enum CameraPermissionStatus {
        case unconfigured
        case configured
        case unauthorized
        case failed
    }
    
    // MARK: - Variables
    
    @Published var error: CameraError?
    private var cameraPermissionStatus = CameraPermissionStatus.unconfigured
    var faceDetector: FaceDetector?
    var previewLayer: AVCaptureVideoPreviewLayer?
    let session = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()
    let notificationCenter = NotificationCenter.default
    
    let videoOutputQueue = DispatchQueue(
      label: "Video Output Queue",
      qos: .userInitiated,
      attributes: [],
      autoreleaseFrequency: .workItem
    )
    
    let sessionQueue = DispatchQueue(
        label: "Video Session Queue",
        qos: .background,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    
    // MARK: - Controller Instance Method:
    
    override func viewDidLoad() {
        // Disable going to sleep
        UIApplication.shared.isIdleTimerDisabled = true
        super.viewDidLoad()
        faceDetector?.viewDelegate = self
        checkPermissions()
        configureCaptureSession()
        self.notificationCenter.addObserver(self, selector: #selector(willResignActive),
                                            name: UIApplication.didEnterBackgroundNotification,
                                            object: nil)
        sessionQueue.async {
            self.session.startRunning()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
        
    }
    
    @objc func willResignActive(_ notification: Notification) {
    }
}



// MARK: - Extensions

extension CameraViewController {
    
    private func set(error: CameraError?) {
        DispatchQueue.main.async {
            self.error = error
        }
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                if !authorized {
                    self.cameraPermissionStatus = .unauthorized
                    self.set(error: .deniedAuthorization)
                }
            }
        case .restricted:
            self.cameraPermissionStatus = .unauthorized
            self.set(error: .restrictedAuthorization)
        case .denied:
            self.cameraPermissionStatus = .unauthorized
            self.set(error: .deniedAuthorization)
        case .authorized:
            break
        @unknown default:
            self.cameraPermissionStatus = .unauthorized
            self.set(error: .unknownAuthorization)
        }
    }

    private func configureCaptureSession() {
        guard self.cameraPermissionStatus == .unconfigured else {
            return
        }
        
        session.beginConfiguration()
        
        defer {
            session.commitConfiguration()
        }
        
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        guard let camera = device else {
            set(error: .cameraUnavailable)
            self.cameraPermissionStatus = .failed
            return
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            
            if session.canAddInput(cameraInput) {
                session.addInput(cameraInput)
            } else {
                set(error: .cannotAddInput)
                self.cameraPermissionStatus = .failed
                return
            }
        } catch {
            set(error: .createCaptureInput(error))
            self.cameraPermissionStatus = .failed
            return
        }
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.setSampleBufferDelegate(faceDetector, queue: videoOutputQueue)
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            let videoConnection = videoOutput.connection(with: .video)
            videoConnection?.videoOrientation = .portrait
            
        } else {
            set(error: .cannotAddOutput)
            self.cameraPermissionStatus = .failed
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = PreviewLayerFrameConstant.Frame
        
        if let previewLayer = previewLayer {
            view.layer.insertSublayer(previewLayer, at: 0)
        }
        
        self.cameraPermissionStatus = .configured
    }
}

extension CameraViewController: FaceDetectorDelegate {
    
    func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect {
        guard
            let previewLayer = previewLayer
        else {
            return CGRect.zero
        }


        return previewLayer.layerRectConverted(fromMetadataOutputRect: rect)
    }
}
