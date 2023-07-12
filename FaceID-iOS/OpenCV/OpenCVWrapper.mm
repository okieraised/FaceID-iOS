//
//  OpenCVWrapper.m
//  FaceID-iOS
//
//  Created by Tri Pham on 7/10/23.
//

#ifdef __cplusplus

#import <opencv2/opencv.hpp>

#import <opencv2/imgcodecs/ios.h>

#import <opencv2/videoio/cap_ios.h>

#endif

#import "OpenCVWrapper.h"

using namespace std;

@implementation OpenCVWrapper

#pragma mark Public

- (void) estimateAffinePartial2D :(const float*) from output:(float*) matrix
{
    std::vector<cv::Point2f> template5 {
        cv::Point2f(38.2946  , 112-51.6963),
        cv::Point2f(73.5318  , 112-51.5014),
        cv::Point2f(56.0252  , 112-71.7366),
        cv::Point2f(41.5493  , 112-92.3655),
        cv::Point2f(70.7299  , 112-92.2041)
    };
    std::vector<cv::Point2f> src;
    for (int i=0; i<5; ++i) {
        src.push_back(cv::Point2f(from[i*2], from[i*2+1]));
    }
    cv::Mat M = cv::estimateAffinePartial2D(src, template5);
    M.convertTo(M, CV_32F);
    for(int i=0; i<M.rows; i++)
        for(int j=0; j<M.cols; j++)
        {
            matrix[i*M.cols+j] = M.at<float>(i,j);
        }
    
    return;
}

#pragma mark Private
@end
