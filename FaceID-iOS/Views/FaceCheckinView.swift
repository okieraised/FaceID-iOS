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
    
    
    var body: some View {
        
        ZStack {
            VStack {
                ZStack {
                    
                    Color(.black)
                        .ignoresSafeArea()
                    
                    
                    
                    CameraView(cameraViewModel: model)
                        .onReceive(model.$facePosition) { _ in
                            DispatchQueue.main.async {
                                model.perform(action: .takePhoto)
                            }
                        }
                    FaceCaptureBorderView()
                    FaceBoundingBoxView(model: model)
                    FaceCaptureStatusView(model: model)
                    
                }
            }
            .padding(.top, -50)
            
            if model.checkinFinished {
                FaceCheckinCompletionView(model: model)
            }
            
        }
        
        
    }
}

//struct FaceCheckinView_Previews: PreviewProvider {
//    static var previews: some View {
//        FaceCheckinView(model: CameraViewModel(isEnrollMode: true, reEnroll: false))
//    }
//}
