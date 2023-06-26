//
//  DefaultProgressCircle.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/23/23.
//

import SwiftUI

struct DefaultProgressCircle: View {
    
    // MARK: - Variables
    
    var offset: CGFloat //= UIScreen.screenSize.width / 2 - 60
    var opacity: Double
    
    var height: CGFloat {
        30
    }
    var width: CGFloat {
        CGFloat(FaceCaptureConstant.FullCircle / FaceCaptureConstant.MaxProgress) * 0.9
    }
    
    func degrees(for index: Int) -> Double {
        Double(((index+1) * (FaceCaptureConstant.FullCircle / FaceCaptureConstant.MaxProgress)))
    }
    
    // MARK: - View
    
    var body: some View {
        ZStack {
            ForEach(0 ..< FaceCaptureConstant.MaxProgress, id: \.self) { i in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(.white)
                    .background(.white)
                    .frame(width: width, height: height, alignment: .center)
                    .opacity(opacity)
                    .offset(y: offset)
                    .rotationEffect(.degrees(degrees(for: i)), anchor: .center)
            }
        }
    }
}

struct DefaultProgressCircle_Previews: PreviewProvider {
    static var previews: some View {
        DefaultProgressCircle(offset: UIScreen.screenSize.width / 2 - 60, opacity: 0.4)
    }
}
