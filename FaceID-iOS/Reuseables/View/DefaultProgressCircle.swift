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
    var height: CGFloat
    
    // MARK: - View
    
    var body: some View {
        ZStack {
            ForEach(0 ..< FaceCaptureConstant.MaxProgress, id: \.self) { i in
                ProgressBarView(index: i, color: .white, offset: offset, opacity: opacity, height: height)
            }
        }
    }
}

struct DefaultProgressCircle_Previews: PreviewProvider {
    static var previews: some View {
        DefaultProgressCircle(offset: UIScreen.screenSize.width / 2 - 60, opacity: 0.4, height: 30)
    }
}
