//
//  AnimationView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/14/23.
//

import SwiftUI

enum FaceIDEnum: String {
    case middle
    case top
    case right
    case bottom
    case left
    
    var image: String {
        switch self {
        case .middle:
            return "Middle"
        case .top:
            return "LookUp"
        case .right:
            return "LookRight"
        case .bottom:
            return "LookDown"
        case .left:
            return "LookLeft"
        }
    }
}

struct FaceInstructionView: View {
    
    // MARK: - Variables
    @State var order: Int = 0
    
    // MARK: - Private variables
    private var imgs: [FaceIDEnum] = [.middle, .top, .middle, .right, .middle, .bottom, .middle, .left]
    private var height: CGFloat = 30
    private var width: CGFloat = 4.5 * 0.9
    private var transition: AnyTransition {
        switch order {
        case 0:
            return .asymmetric(insertion: .scale, removal: .opacity)
        default:
            return .identity
        }
    }
    
    // MARK: - Constant variable
    let imageSwitchTimer = Timer.publish(every: 0.75, on: .main, in: .common).autoconnect()
    
    // MARK: - View
    var body: some View {

        ZStack {
            Color(.black)
                .ignoresSafeArea()
            
            VStack(spacing: 60) {
                VStack {
                    ZStack {
                        DefaultProgressCircle(offset: UIScreen.screenSize.width / 2 - 60, opacity: 0.4, height: 30)
                        faceIDView
                    }
                }
                
                VStack {
                    Text(InstructionText.Title)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.all)
                        .padding(.top, 24)
                    
                    Text(InstructionText.Instruction)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.all)
                    
                    Spacer()
                    
                    NavigationLink {
                        FaceEnrollView()
                    } label: {
                        CustomTextView(text: "Start")
                    }
                    .isDetailLink(false)
                }
                .padding(.all)
            }
            .padding(.top, 100)
        }
        
    }
}

// MARK: - Extension
extension FaceInstructionView {
    
    var faceIDView: some View {
        Image(imgs[order].image)
            .resizable()
            .frame(width: 120, height: 120)
            .font(.title2)
            .transition(.asymmetric(insertion: .scale, removal: .opacity))
            .animation(.interpolatingSpring(mass: 1,
                                            stiffness: 1,
                                            damping: 0.5,
                                            initialVelocity: 10),
                       value: 1)
            .onReceive(imageSwitchTimer) { _ in
                self.order = (self.order + 1) % self.imgs.count
            }
    }
}

//struct InstructionView_Previews: PreviewProvider {
//    static var previews: some View {
//        FaceInstructionView(model: CameraViewModel())
//    }
//}

