//
//  UINavigationControllerExtension.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/21/23.
//

import Foundation
import SwiftUI

extension UINavigationController {
    // Remove back button text
    open override func viewWillLayoutSubviews() {
        let button = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        button.tintColor = .white
        navigationBar.topItem?.backBarButtonItem = button
    }
}
