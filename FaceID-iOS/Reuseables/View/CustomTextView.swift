//
//  CustomTextView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/23/23.
//

import SwiftUI

struct CustomTextView: View {
    
    var text: String
    var isDisabled: Bool? = false
    
    var body: some View {
        Text(text)
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(.horizontal, 20)
            .font(.system(size: 18, weight: .bold))
            .padding()
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isDisabled == true ? Color.gray : Color.blue, lineWidth: 0.5)
            )
            .background(RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(
                    gradient: Gradient(colors: isDisabled == true ? [Color.gray] :
                                        [Color(UIColor(red: 31/255, green: 95/255, blue: 196/255, alpha: 1))]),
                    startPoint: .leading,
                    endPoint: .trailing)
                )
            )
    }
}

struct NavigationButton_Previews: PreviewProvider {
    static var previews: some View {
        CustomTextView(text: "hahaha")
    }
}
