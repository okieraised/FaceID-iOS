//
//  CosineSimilarity.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/27/23.
//

import Foundation

func cosineSim(A: [Float32], B: [Float32]) -> Float32 {
    return dot(A: A, B: B) / (magnitude(A: A) * magnitude(A: B))
}

private func dot(A: [Float32], B: [Float32]) -> Float32 {
    var x: Float32 = 0
    for i in 0...A.count-1 {
        x += A[i] * B[i]
    }
    return x
}

/** Vector Magnitude **/
private func magnitude(A: [Float32]) -> Float32 {
    var x: Float32 = 0
    for elt in A {
        x += elt * elt
    }
    return sqrt(x)
}
