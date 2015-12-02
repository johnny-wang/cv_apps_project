//
//  homography.cpp
//  Implementation of homography estimation
//
//  Created by Yuhan Long on 11/22/15.
//  Copyright © 2015 Yuhan Long. All rights reserved.
//

#include "homographyUtil.hpp"
void fitHomography(const vector<Point2f> &fromPts, const vector<Point2f> &toPts,  Mat &homography_mat)
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
    
    homography_mat = findHomography(fromPts,toPts,0);
    
    
}

void projHomography( Mat &srcImg, const Mat &tarImg, Mat &resultImg, const Mat &homography_mat)
{
    // We warp the tarImg with the homography_mat
    //and then we project tarImg into srcImg
    //
    
    Mat textImageWarped;

    
    warpPerspective(tarImg,textImageWarped,homography_mat,srcImg.size() );
    if (textImageWarped.channels()!=1)
        cvtColor(textImageWarped, textImageWarped, CV_BGR2GRAY);
    threshold(textImageWarped,textImageWarped,0,255,CV_THRESH_BINARY);
    
    srcImg = ~srcImg;
    srcImg.copyTo(resultImg,~textImageWarped);
    
    resultImg = ~resultImg;
}

Mat cvMatFromString_cv(const string &text)
{
    // This function is for using opencv function to convert text into cvMat
    
    
    double fontScale = 1;
    int baseline=0;
    int thickness = 4;
    int fontFace = FONT_HERSHEY_SIMPLEX;
    
    Size textSize = getTextSize(text, fontFace,
                                fontScale, thickness, &baseline);
    
    Mat text_image=Mat::zeros(textSize.height,textSize.width,CV_8U);
    
    putText(text_image, text, Point2f(0.0f,0.0f), fontFace, fontScale, Scalar(255,255,255),1,8,true);
    
    flip(text_image,text_image,0);
    
    cout<<textSize<<endl;
    
    
    return text_image;
}