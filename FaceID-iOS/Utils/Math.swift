//
//  RadToDegree.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/23/23.
//

import Foundation

func rad2deg(_ number: Double) -> Double {
    return number * 180 / .pi
}

func rad2deg(_ value: Float) -> Float {
    return value * 180 / Float.pi
}

func rad2deg(_ value: CGFloat) -> CGFloat {
    return value * 180 / CGFloat.pi
}

func deg2rad(_ value: Double) -> Double {
    return value * Double.pi / 180
}

func deg2rad(_ value: CGFloat) -> CGFloat {
    return value * CGFloat.pi / 180
}

func deg2rad(_ value: Float) -> Float {
    return value * Float.pi / 180
}
