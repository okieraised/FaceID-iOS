//
//  WelcomeView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/23/23.
//

import SwiftUI

struct WelcomeView: View {
    
    
    
    private var enrollText: String {
        if PersistenceController.shared.getFaceVector().count == 1 {
            return "Re-Enroll"
        } else {
            return "Enroll"
        }
    }
    
    private var reEnroll: Bool {
        if PersistenceController.shared.getFaceVector().count == 1 {
            return true
        } else {
            return false
        }
    }
    
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
//                            FaceInstructionView(model: CameraViewModel(isEnrollMode: true, reEnroll: reEnroll))
                            FaceInstructionView()
                        } label: {
                            CustomTextView(text: enrollText)
                                .padding(.horizontal)
                        }
                        .isDetailLink(false)
                        
                        NavigationLink {
                            FaceCheckinView()

                        } label: {
                            CustomTextView(text: "Check-In", isDisabled: PersistenceController.shared.getFaceVector().count == 1 ? false : true)
                                .padding(.horizontal)
                        }
                        .isDetailLink(false)
                        .disabled(PersistenceController.shared.getFaceVector().count == 1 ? false : true)

                    }
                }
                .padding(.top, 100)
                .padding(.bottom, 20)
                
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
