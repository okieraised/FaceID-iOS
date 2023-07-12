//
//  ViewExtension.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/21/23.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
