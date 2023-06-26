//
//  FaceCaptureProgressView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/21/23.
//

import SwiftUI

struct FaceCaptureProgressView: View {
    
    // MARK: - Variables
    @ObservedObject private(set) var model: CameraViewModel
    
    // MARK: - View
    
    var body: some View {
        
        VStack {
            ZStack {
                DefaultProgressCircle(offset: UIScreen.screenSize.width / 2 - 40, opacity: 0.4, height: 10)
                
                ForEach(model.capturedIndices.sorted(), id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .offset(y: UIScreen.screenSize.width / 2 - 30)
                        .fill(.green)
                        .frame(width: CGFloat(FaceCaptureConstant.FullCircle / FaceCaptureConstant.MaxProgress) * 0.9, height: 30, alignment: .center)
                        .animation(.easeInOut, value: 30)
                        .rotationEffect(.degrees(Double(-1 * ((i+1) * (FaceCaptureConstant.FullCircle / FaceCaptureConstant.MaxProgress) - 180))))
                }
            }
            
            Spacer()
        }
        .padding(.top, 2*FaceCaptureConstant.OffsetFromTop)
    }
}

struct FaceCaptureProgressView_Previews: PreviewProvider {
    static var previews: some View {
        FaceCaptureProgressView(model: CameraViewModel())
    }
}
