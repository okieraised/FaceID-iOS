//
//  ColorExtension.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/23/23.
//

import SwiftUI

extension Color {
    static let theme = ColorTheme()
}


struct ColorTheme {
    let primaryTextColor = Color("PrimaryTextColor")
    let backgroundColor = Color("BackgroundColor")
    let secondaryBackgroundColor = Color("SecondaryBackgroundColor")
    let systemBackgroundColor = Color("SystemBackgroundColor")
}
