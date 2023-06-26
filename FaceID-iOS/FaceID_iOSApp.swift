//
//  FaceID_iOSApp.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/13/23.
//

import SwiftUI

@main
struct FaceID_iOSApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
//            CameraView(cameraViewModel: CameraViewModel())
            WelcomeView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
