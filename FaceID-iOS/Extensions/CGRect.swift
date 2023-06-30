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
            x: self.origin.x * size.width / 2,
            y: self.origin.y * size.height,
            width: (self.size.width * size.width) * 2,
            height: (self.size.height * size.height) - PreviewLayerFrameConstant.YOffset
        )
        return rect
    }
}
