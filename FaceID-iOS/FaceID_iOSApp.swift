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
            HomeView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
