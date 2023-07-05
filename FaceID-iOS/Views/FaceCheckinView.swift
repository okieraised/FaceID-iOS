//
//  FaceCheckinView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/29/23.
//

import SwiftUI

struct FaceCheckinView: View {
    
    // MARK: - Variables
    
    @StateObject private var model = CameraViewModel(isEnrollMode: false, reEnroll: false)
    
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
                        VStack {
                            Circle()
                                .stroke(.white, lineWidth: 2)
                                .aspectRatio(0.45, contentMode: .fit)
                            Spacer()
                        }
                            .padding(.top, FaceCaptureConstant.OffsetFromTop+40)
                    } else {
                        FaceCaptureBorderView()
                    }
                    
                    FaceBoundingBoxView(model: model)
                    FaceCaptureStatusView(model: model) 
                }
            }
            .padding(.top, -50)
            
            if model.checkinFinished {
                FaceCheckinCompletionView(model: model)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}

extension FaceCheckinView {
    
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
