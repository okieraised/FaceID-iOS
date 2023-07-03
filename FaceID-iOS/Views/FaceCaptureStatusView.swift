//
//  FaceCaptureStatusView.swift
//  FaceID-iOS
//
//  Created by Tri Pham on 6/29/23.
//

import SwiftUI

struct FaceCaptureStatusView: View {
    
    @ObservedObject private(set) var model: CameraViewModel
    
    
    var body: some View {
        VStack(alignment: .center) {
            
            Spacer()
            
            Text(faceQualityCheckTitle())
                .font(.system(size: 24, weight: .bold))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.white)
                .offset(y: -FaceCaptureConstant.LayoutGuideWidth/2)
            
            Text(faceQualityCheckSubtitle())
                .font(.system(size: 16, weight: .medium))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.white)
                .offset(y: -FaceCaptureConstant.LayoutGuideWidth/2)
        }
    }
}

extension FaceCaptureStatusView {
    
    // MARK: Functions
    
    private func faceQualityCheckTitle() -> String {
        if model.hasDetectedValidFace {
            if model.isEnrollMode {
                switch model.faceLiveness {
                case .faceObstructed:
                    return "Face Obstructed"
                default:
                    if model.capturedIndices.count == FaceCaptureConstant.MaxProgress {
                        return "Completed"
                    }
                    return "Move Your Head to Complete the Circle"
                }
            } else {
                return "Move Your Head from Left to Right"
            }
        } else {
            switch model.faceLiveness {
            case .faceObstructed:
                return "Face Obstructed"
            case .faceSpoofed:
                return "Face Spoofing Detected"
            case .faceOK:
                return "Face Not Valid"
            }
        }
    }
    
    private func faceQualityCheckSubtitle() -> String {
        if model.hasDetectedValidFace {
            switch model.faceLiveness {
            case .faceObstructed:
                return "Please remove anything that covers your face"
            default:
                return ""
            }
        } else {
            switch model.faceLiveness {
            case .faceObstructed:
                return "Please remove anything that covers your face"
            case .faceSpoofed:
                return ""
            case .faceOK:
                return "Please keep your face within the frame"
            }
        }
    }
}


struct FaceCaptureStatusView_Previews: PreviewProvider {
    static var previews: some View {
        FaceCaptureStatusView(model: CameraViewModel(isEnrollMode: true, reEnroll: false))
    }
}
