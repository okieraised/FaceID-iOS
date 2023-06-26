//
//  WelcomeView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/23/23.
//

import SwiftUI

struct WelcomeView: View {
    
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
                            InstructionView(model: CameraViewModel())
                        } label: {
                            CustomTextView(text: "Enroll")
                        }
                        
                        NavigationLink {
                            EmptyView()
                        } label: {
                            CustomTextView(text: "Check-In")
                        }

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
