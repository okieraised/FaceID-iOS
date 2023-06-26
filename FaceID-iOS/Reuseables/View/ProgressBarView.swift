//
//  ProgressBarView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/26/23.
//

import SwiftUI

struct ProgressBarView: View {
    
    var index: Int
    var color: Color
    var offset: CGFloat
    var opacity: Double
    
    var height: CGFloat
    var width: CGFloat {
        CGFloat(FaceCaptureConstant.FullCircle / FaceCaptureConstant.MaxProgress) * 0.9
    }
    
    func degrees(for index: Int) -> Double {
        Double(((index+1) * (FaceCaptureConstant.FullCircle / FaceCaptureConstant.MaxProgress)))
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(color)
            .background(.white)
            .frame(width: width, height: height, alignment: .center)
            .opacity(opacity)
            .offset(y: offset)
            .rotationEffect(.degrees(degrees(for: index)), anchor: .center)
    }
}

struct ProgressBarView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBarView(index: 1, color: .white, offset: UIScreen.screenSize.width / 2 - 60, opacity: 1, height: 10)
    }
}
