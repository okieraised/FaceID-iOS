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

    // MARK: - Init
    init(model: CameraViewModel) {
        self.model = model
    }
    
    // MARK: - View
    var body: some View {
        ZStack {
            CameraView(cameraViewModel: model)
            FaceBoundingBoxView(model: model)
            FaceCaptureBorderView()
        }
        
    }
}

//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView()
//    }
//}
