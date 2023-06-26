//
//  FaceCaptureProgressView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/21/23.
//

import SwiftUI

struct FaceCaptureProgressView: View {
    private var height: CGFloat = 10
    private var width: CGFloat {
        CGFloat(FaceCaptureConstant.FullCircle / FaceCaptureConstant.MaxProgress) * 0.9
    }
    
    func degrees(for index: Int) -> Double {
        Double(((index+1) * 3))
    }
    
    var body: some View {
        VStack {
//            DefaultProgressCircle(offset: UIScreen.screenSize.width / 2 - 15, opacity: 0.8)
            ZStack {
                // Base progress circle
                ForEach(0 ..< FaceCaptureConstant.MaxProgress, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .offset(y: UIScreen.screenSize.width / 2 - 15)
                        .fill(.gray)
                        .frame(width: width, height: height, alignment: .center)
                        .opacity(0.8)
                        .rotationEffect(.degrees(Double((i+1) * (FaceCaptureConstant.FullCircle / FaceCaptureConstant.MaxProgress))), anchor: .center)
                }
            }
            
            Spacer()
        }
        .padding(.top, 2*FaceCaptureConstant.OffsetFromTop)
        
        
    }
}

struct FaceCaptureProgressView_Previews: PreviewProvider {
    static var previews: some View {
        FaceCaptureProgressView()
    }
}
