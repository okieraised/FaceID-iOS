//
//  PreviewLayerFrameConstant.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/19/23.
//

import Foundation
import SwiftUI

struct PreviewLayerFrameConstant {
    static let Frame: CGRect = CGRect(
        x: UIScreen.x,
        y: UIScreen.y+YOffset,
        width: UIScreen.screenWidth,
        height: UIScreen.screenHeight/2
    )
    
    static let YOffset = UIScreen.screenHeight/9
}

struct FaceCaptureConstant {
    static let LayoutGuideWidth: CGFloat = 300
    static let LayoutGuideHeight: CGFloat = 300
    
    static let MaxProgress: Int = 60
    static let FullCircle: Int = 360
    
    static let OffsetFromTop = PreviewLayerFrameConstant.YOffset + 60
}

