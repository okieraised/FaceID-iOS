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

    func makeUIViewController(context: Context) -> CameraViewController {
        
        let viewController = CameraViewController()
        return viewController
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) { }
}

