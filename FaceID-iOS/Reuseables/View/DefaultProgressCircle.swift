//
//  DefaultProgressCircle.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/23/23.
//

import SwiftUI

struct DefaultProgressCircle: View {
    
    private var height: CGFloat = 30
    private var width: CGFloat {
        CGFloat(FaceCaptureConstant.FullCircle / FaceCaptureConstant.MaxProgress) * 0.9
    }
    private var offset: CGFloat = UIScreen.screenSize.width / 2 - 60
    
    var body: some View {
        ZStack {
            Color(.black)
                .ignoresSafeArea()
            
            ForEach(0 ..< FaceCaptureConstant.MaxProgress, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(.white)
                    .background(.white)
                    .frame(width: width, height: height, alignment: .center)
                    .opacity(0.4)
                    .offset(y: offset)
                    .rotationEffect(.degrees(Double((i+1) * (FaceCaptureConstant.FullCircle / FaceCaptureConstant.MaxProgress))), anchor: .center)
            }
//            .padding(.bottom, 200)
        }
        
    }
}

struct DefaultProgressCircle_Previews: PreviewProvider {
    static var previews: some View {
        DefaultProgressCircle()
    }
}
