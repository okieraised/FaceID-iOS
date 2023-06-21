//
//  FaceCaptureBorderView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/21/23.
//

import SwiftUI

struct FaceCaptureBorderView: View {
    var body: some View {
        VStack {
            Image("Bounding")
                .resizable()
                .frame(width: FaceCaptureConstant.LayoutGuideWidth, height: FaceCaptureConstant.LayoutGuideHeight)
            Spacer()
        }
        .padding(.top, 50 + PreviewLayerFrameConstant.YOffset)
    }
}

struct FaceCaptureBorderView_Previews: PreviewProvider {
    static var previews: some View {
        FaceCaptureBorderView()
    }
}
