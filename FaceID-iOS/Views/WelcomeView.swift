//
//  WelcomeView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/23/23.
//

import SwiftUI
import CoreData

struct WelcomeView: View {
    
    // MARK: - Variables
        
    @State private var faceVectorCount: Int = PersistenceController.shared.getFaceVector().count {
        didSet {
                faceVectorCount = PersistenceController.shared.getFaceVector().count
        }
    }
    
    // MARK: - View
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.black)
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    VStack(spacing: 80) {
                        Image("vbd")
                            .resizable()
                            .frame(width: 250, height: 150)
                            .scaledToFill()
                        
                        Text("FaceID SDK\nIn-App Enroll & Check-in")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .font(.system(size: 24, weight: .bold))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 24) {
                        NavigationLink {
                            FaceInstructionView()
                        } label: {
                            CustomTextView(text: faceVectorCount == 1 ? "Re-Enroll" : "Enroll")
                                .padding(.horizontal)
                        }
                        .isDetailLink(false)
                        
                        NavigationLink {
                            FaceCheckinView()
                        } label: {
                            CustomTextView(text: "Check-In",
                                           isDisabled: faceVectorCount == 1 ? false : true)
                                .padding(.horizontal)
                        }
                        .isDetailLink(false)
                        .disabled(faceVectorCount == 1 ? false : true)
                    }
                }
                .padding(.top, 100)
                .padding(.bottom, 20)
            }
        }
    }
}
