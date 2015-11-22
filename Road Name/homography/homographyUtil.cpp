//
//  homography.cpp
//  This file is not in use
//
//  Created by Yuhan Long on 11/22/15.
//  Copyright © 2015 Yuhan Long. All rights reserved.
//

#include "homographyUtil.hpp"
void fitHomography(const vector<Point2f> &fromPts, const vector<Point2f> &toPts, const Mat homography_mat)
{
    // We are estimation homography from the fromPts to the toPts
    //The current points are hardcoded
    //
    
    
    if((fromPts.size()!=4)||(toPts.size()!=4))
    {
        cerr<<"Need four points for homography estimation"<<endl;
        return;
    }
    // [TODO] add a check of the size of the homography_mat
    
}

void projHomography(const Mat &srcImg, const Mat &tarImg, const Mat homography_mat)
{
    // We warp the tarImg with the homography_mat
    //and then we project tarImg into srcImg
    //
    
    
}

Mat cvMatFromString_cv(const string &text)
{
    // This function is for using opencv function to convert text into cvMat
    
    Mat text_image;
    return text_image;
}