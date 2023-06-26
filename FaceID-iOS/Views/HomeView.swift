//
//  HomeView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/13/23.
//

import SwiftUI

struct HomeView: View {
    
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
                        AnyView(
                            VStack {
                                Circle()
                                    .aspectRatio(0.6, contentMode: .fit)
                                Spacer()
                            }
                                .padding(.top, FaceCaptureConstant.OffsetFromTop+50/2)
                        )
                    )
                
                
                    .onReceive(model.$facePosition) { _ in
                        DispatchQueue.main.async {
                            model.perform(action: .takePhoto)
                        }
                    }
                
                FaceBoundingBoxView(model: model)
                
                FaceCaptureBorderView()
                FaceCaptureProgressView(model: model)
                
                VStack {
                    
                    Spacer()
                    
                    Text(faceQualityCheckTitle())
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.top, -50)
        
    }
}

extension HomeView {
    private func faceQualityCheckTitle() -> String {
        if model.hasDetectedValidFace {
            print("hereee: \(Date())")
            return "Move your head to complete the circle"
        } else {
            switch model.faceLiveness {
            case .faceObstructed:
                return "Face Obstructed"
            case .faceSpoofed:
                return "Face Spoofing Detected"
            case .faceOK:
                return "Face not Valid"
            }
        }
    }
}

//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView()
//    }
//}
