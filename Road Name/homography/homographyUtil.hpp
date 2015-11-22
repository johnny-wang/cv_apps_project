//
//  homography.hpp
//  Homography utilities for the project
//
//  Created by Yuhan Long on 11/22/15.
//  Copyright © 2015 Yuhan Long. All rights reserved.
//

#ifndef homography_hpp
#define homography_hpp

#include <iostream>
#include <opencv2/opencv.hpp>

using namespace cv;
using namespace std;



// Function for fitting a homography warp from four points
void fitHomography(const vector<Point2f> &fromPts, const vector<Point2f> &toPts, const Mat homography_mat);

// Function for projecting a homography warp
void projHomography(const Mat &srcImg, const Mat &tarImg, const Mat homography_mat);

// convert matrix to string
Mat cvMatFromString_cv(const string &text);


#endif /* homography_hpp */
