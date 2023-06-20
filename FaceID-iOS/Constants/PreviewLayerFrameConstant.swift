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
        y: UIScreen.y+yOffset,
        width: UIScreen.screenWidth,
        height: UIScreen.screenHeight/2
    )
    
    static let yOffset = UIScreen.screenHeight/9
}
