//
//  HomeView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/13/23.
//

import SwiftUI

struct HomeView: View {
    
    
    @ObservedObject private(set) var model: CameraViewModel

    init(model: CameraViewModel) {
      self.model = model
    }
    
    var body: some View {
        ZStack {
            
            CameraView(cameraViewModel: model)
            FaceBoundingBoxView(model: model)
        }
        
    }
}

//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView()
//    }
//}
