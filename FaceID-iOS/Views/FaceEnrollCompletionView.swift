//
//  FaceEnrollCompletionView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/28/23.
//

import SwiftUI

struct FaceEnrollCompletionView: View {
    
    // MARK: - Variables
    
    @State var capturedImage: UIImage?
    
    // MARK: - View

    var body: some View {
        
        ZStack {
            
            Color(.black)
                .ignoresSafeArea()
            
            VStack {
                Circle()
                    .stroke(.green, lineWidth: 8)
                    .aspectRatio(0.45, contentMode: .fit)
                    .overlay {
                        if let uiImage = capturedImage {
                            Image(uiImage: uiImage)
                                .resizable()
                                .clipped()
                                .clipShape(Circle())
                        }
                    }
                    
                Spacer()
            }
            .padding(.top, FaceCaptureConstant.OffsetFromTop+40)
            
            VStack {
                
                Spacer()
                
                Button {
                    NavigationUtil.popToRootView()
                } label: {
                    CustomTextView(text: "Done")
                }
            }
            .padding()
            
        }
    }
}

struct FaceEnrollCompletionView_Previews: PreviewProvider {
    static var previews: some View {
        FaceEnrollCompletionView()
    }
}
