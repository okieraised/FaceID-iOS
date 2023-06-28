//
//  HomeView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/13/23.
//

import SwiftUI

struct FaceCaptureView: View {
    
    // MARK: - Variables
    @ObservedObject private(set) var model: CameraViewModel
    
    // MARK: - View
    var body: some View {
        

        VStack {
            ZStack {

                Color(.black)
                    .ignoresSafeArea()

                CameraView(cameraViewModel: model)
                    .mask(
                        model.captureMode == true ? captureModeCameraView : AnyView(Rectangle().aspectRatio(1, contentMode: .fill))
                    )
                    .onReceive(model.$facePosition) { _ in
                        DispatchQueue.main.async {
                            model.perform(action: .takePhoto)
                        }
                    }

                if model.captureMode {
                    FaceCaptureProgressView(model: model)
                } else {
                    FaceCaptureBorderView()
                }

                FaceBoundingBoxView(model: model)

                captureStatusView
                
                if model.enrollFinished {
                    FaceEnrollCompletionView(capturedImage: model.capturedPhoto)
                }

            }
        }
        .padding(.top, -50)
    }
}

extension FaceCaptureView {
    
    // MARK: Views
    
    var captureModeCameraView: AnyView {
        AnyView(
            VStack {
                Circle()
                    .aspectRatio(0.45, contentMode: .fit)
                Spacer()
            }
                .padding(.top, FaceCaptureConstant.OffsetFromTop+40)
        )
    }
    
    var captureStatusView: some View {
        VStack(alignment: .center) {
            
            Spacer()
            
            Text(faceQualityCheckTitle())
                .font(.system(size: 24, weight: .bold))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.white)
                .offset(y: -FaceCaptureConstant.LayoutGuideWidth/2)
            
            Text(faceQualityCheckSubtitle())
                .font(.system(size: 16, weight: .medium))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.white)
                .offset(y: -FaceCaptureConstant.LayoutGuideWidth/2)
        }
    }
    
}

extension FaceCaptureView {
    
    // MARK: Functions
    
    private func faceQualityCheckTitle() -> String {
        if model.hasDetectedValidFace {
            if model.capturedIndices.count == FaceCaptureConstant.MaxProgress {
                return "Completed"
            }
            return "Move Your Head to Complete the Circle"
        } else {
            switch model.faceLiveness {
            case .faceObstructed:
                return "Face Obstructed"
            case .faceSpoofed:
                return "Face Spoofing Detected"
            case .faceOK:
                return "Face Not Valid"
            }
        }
    }
    
    private func faceQualityCheckSubtitle() -> String {
        if model.hasDetectedValidFace {
            return ""
        } else {
            switch model.faceLiveness {
            case .faceObstructed:
                return "Please remove anything that covers your face"
            case .faceSpoofed:
                return ""
            case .faceOK:
                return "Please keep your face within the frame"
            }
        }
    }
}
