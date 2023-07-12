//
//  CGSize+Extensions.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 7/12/23.
//

import CoreGraphics

extension CGSize {
    
    // MARK: - Initializers
    init(_ width: CGFloat, _ height: CGFloat) {
        self.init()
        self.width = width
        self.height = height
    }

    init(_ width: Int, _ height: Int) {
        self.init()
        self.width = CGFloat(width)
        self.height = CGFloat(height)
    }

    func ceilled() -> CGSize {
        return CGSize(CoreGraphics.ceil(width), CoreGraphics.ceil(height))
    }

    func floored() -> CGSize {
        return CGSize(CoreGraphics.floor(width), CoreGraphics.floor(height))
    }

    func rounded() -> CGSize {
        return CGSize(CoreGraphics.round(width), CoreGraphics.round(height))
    }
}

func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
    return CGSize(lhs.width * rhs, lhs.height * rhs)
}
