//
//  HomeView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/13/23.
//

import SwiftUI

struct FaceEnrollView: View {

    // MARK: - Variables
    
    @StateObject private var model = CameraViewModel(
        isEnrollMode: true,
        reEnroll: PersistenceController.shared.getFaceVector().count == 1 ? true : false
    )
    
    // MARK: - View
    var body: some View {
        
        ZStack {
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
                    FaceCaptureStatusView(model: model)

                }
            }
            .padding(.top, -50)
            
            if model.enrollFinished {
                FaceEnrollCompletionView(model: model)
                    .navigationBarBackButtonHidden(true)
            }
        }
        
        
    }
}

// MARK: - Extension

extension FaceEnrollView {
    
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
}
