//
//  FaceBoundingBoxView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/19/23.
//

import SwiftUI

struct FaceBoundingBoxView: View {
    
    @ObservedObject var model: CameraViewModel
    
    var body: some View {
        
        
        switch model.faceGeometryObservation {
        case .faceNotFound, .errored:
            Rectangle().fill(Color.clear)
            
        case .faceFound(let faceGeometryModel):
            ZStack {
                Rectangle()
                    .path(in: CGRect(
                        x: faceGeometryModel.boundingBox.origin.x,
                        y: faceGeometryModel.boundingBox.origin.y + PreviewLayerFrameConstant.YOffset,
                        width: faceGeometryModel.boundingBox.width,
                        height: faceGeometryModel.boundingBox.height
                    ))
                .stroke(Color.green, lineWidth: 3.0)
            }
        }
    }
}

struct FaceBoundingBoxView_Previews: PreviewProvider {
    static var previews: some View {
        FaceBoundingBoxView(model: CameraViewModel(isEnrollMode: true, reEnroll: false))
    }
}
