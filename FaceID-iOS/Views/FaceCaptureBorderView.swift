//
//  FaceCaptureBorderView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/21/23.
//

import SwiftUI

struct FaceCaptureBorderView: View {
    
    // MARK: - View
    
    var body: some View {
        VStack {
            Image("Bounding")
                .resizable()
                .frame(width: FaceCaptureConstant.LayoutGuideWidth, height: FaceCaptureConstant.LayoutGuideHeight)
            Spacer()
        }
        .padding(.top, FaceCaptureConstant.OffsetFromTop)
    }
}

struct FaceCaptureBorderView_Previews: PreviewProvider {
    static var previews: some View {
        FaceCaptureBorderView()
    }
}
