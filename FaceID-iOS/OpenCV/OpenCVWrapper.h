//
//  OpenCVWrapper.h
//  FaceID-iOS
//
//  Created by Tri Pham on 7/10/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenCVWrapper : NSObject
- (void) estimateAffinePartial2D :(const float*) from output:(float*) matrix;

@end

NS_ASSUME_NONNULL_END
