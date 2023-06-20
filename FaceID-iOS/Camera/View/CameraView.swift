//
//  CameraView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/13/23.
//

import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    typealias UIViewControllerType = CameraViewController
    
    private(set) var cameraViewModel: CameraViewModel

    func makeUIViewController(context: Context) -> CameraViewController {
        
        let faceDetector = FaceDetector()
        faceDetector.cameraViewModel = cameraViewModel
        
        
        let viewController = CameraViewController()
        viewController.faceDetector = faceDetector
        
        return viewController
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) { }
}

