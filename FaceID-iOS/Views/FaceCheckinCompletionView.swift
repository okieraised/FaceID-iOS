//
//  FaceCheckinCompletionView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/29/23.
//

import SwiftUI

struct FaceCheckinCompletionView: View {
    // MARK: - Variables
    
    @State var model: CameraViewModel
    
    // MARK: - View

    var body: some View {
        
        ZStack {
            
            Color(.black)
                .ignoresSafeArea()
            
            VStack {
                Circle()
                    .stroke(model.checkinOK == true ? .green : .red, lineWidth: 8)
                    .aspectRatio(0.45, contentMode: .fit)
                    .overlay {
                        if let uiImage = model.capturedPhoto {
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
                
                Image(systemName: model.checkinOK == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .scaledToFill()
                    .font(.system(size: 36))
                    .frame(width: 120, height: 120, alignment: .bottom)
                    .foregroundColor(model.checkinOK == true ? .green : .red)
                
                Text(model.checkinOK == true ? "Checkin Completed" : "Checkin Failed")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .font(.system(size: 18, weight: .bold))
                    .padding()
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.top, 240)
            .padding()
            
            VStack {
                
                Spacer()
                
                Button {
                    NavigationUtil.popToRootView()
                } label: {
                    CustomTextView(text: model.checkinOK == true ? "Done" : "Try Again")
                }
            }
            .padding()
            
        }
    }
}

struct FaceCheckinCompletionView_Previews: PreviewProvider {
    static var previews: some View {
        FaceCheckinCompletionView(model: CameraViewModel(isEnrollMode: false, reEnroll: false))
    }
}
