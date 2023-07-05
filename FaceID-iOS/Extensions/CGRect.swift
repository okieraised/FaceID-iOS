//
//  CGRect.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/30/23.
//

import Foundation

extension CGRect {
    func scaledForCropping(to size: CGSize) -> CGRect {
        
        let rect = CGRect(
            x: self.origin.x * size.width / 2 - PreviewLayerFrameConstant.YOffset / 2,
            y: self.origin.y * size.height + 2*PreviewLayerFrameConstant.YOffset,
            width: (self.size.width * size.width) * 2,
            height: (self.size.width * size.width) * 2  + PreviewLayerFrameConstant.YOffset / 2 // (self.size.height * size.height) - 2 * PreviewLayerFrameConstant.YOffset
        )
        
        return rect
    }
}
