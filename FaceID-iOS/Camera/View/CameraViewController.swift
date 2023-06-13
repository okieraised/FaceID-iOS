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
    
    let notificationCenter = NotificationCenter.default
    private let context = CIContext()
    private let cameraManager = CameraManager.shared
    private let frameManager = FrameManager.shared
    
    override func viewDidLoad() {
        
        UIApplication.shared.isIdleTimerDisabled = true
        super.viewDidLoad()
        
        self.cameraManager.session.sessionPreset = .high
        self.notificationCenter.addObserver(self, selector: #selector(willResignActive), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        self.cameraManager.previewLayer = AVCaptureVideoPreviewLayer(session: self.cameraManager.session)
        self.cameraManager.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.cameraManager.previewLayer?.frame = CGRect(x: view.bounds.origin.x, y: view.bounds.origin.y + 40, width: view.bounds.width, height: view.bounds.height/2)
        if let previewLayer = self.cameraManager.previewLayer {
            view.layer.insertSublayer(previewLayer, at: 0)
        }
        
    }
    
    @objc func willResignActive(_ notification: Notification) {
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.cameraManager.sessionQueue.async {
            if self.cameraManager.session.isRunning {
                self.cameraManager.session.stopRunning()
            }
        }
    }
}
