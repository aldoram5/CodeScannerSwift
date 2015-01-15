//
//  CVWrapper.m
//  CodeScanner
//
//  Created by gbmobile on 1/14/15.
//  Copyright (c) 2015 gbmobile. All rights reserved.
//

#import "CVWrapper.h"


using namespace std;
using namespace cv;

@implementation CVWrapper

static int thresh = 50, N = 11;
static float tolerance = 0.01;
static int accuracy = 0;

//adding declarations at top of file to allow public function  at top
static void findSquares(  const Mat& image,   vector<vector<cv::Point> >& squares );
    
+ (cv::Mat) CVMatFromUIImage:(UIImage *)image
    {
        CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
        CGFloat cols = image.size.width;
        CGFloat rows = image.size.height;
        
        cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
        
        CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                        cols,                       // Width of bitmap
                                                        rows,                       // Height of bitmap
                                                        8,                          // Bits per component
                                                        cvMat.step[0],              // Bytes per row
                                                        colorSpace,                 // Colorspace
                                                        kCGImageAlphaNoneSkipLast |
                                                        kCGBitmapByteOrderDefault); // Bitmap info flags
        
        CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
        CGContextRelease(contextRef);
        
        return cvMat;
    }
    
    
+(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
    {
        NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
        CGColorSpaceRef colorSpace;
        
        if (cvMat.elemSize() == 1) {
            colorSpace = CGColorSpaceCreateDeviceGray();
        } else {
            colorSpace = CGColorSpaceCreateDeviceRGB();
        }
        
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
        
        // Creating CGImage from cv::Mat
        CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                            cvMat.rows,                                 //height
                                            8,                                          //bits per component
                                            8 * cvMat.elemSize(),                       //bits per pixel
                                            cvMat.step[0],                            //bytesPerRow
                                            colorSpace,                                 //colorspace
                                            kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                            provider,                                   //CGDataProviderRef
                                            NULL,                                       //decode
                                            false,                                      //should interpolate
                                            kCGRenderingIntentDefault                   //intent
                                            );
        
        
        // Getting UIImage from CGImage
        UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpace);
        
        return finalImage;
    }



+(bool )CheckIfCodeIsRecognized :( UIImage*) image
{

    
    detectSquaresInImage([CVWrapper CVMatFromUIImage:image], 20.0, 50, 7, 0);
    return YES;

}




//this public function performs the role of
//main{} in the original file
static cv::Mat detectSquaresInImage (cv::Mat image, float tol, int threshold, int levels, int acc)
{
    vector<vector<cv::Point> > squares;
    
    if( image.empty() )
    {
        cout << "CVSquares.m: Couldn't load " << endl;
    }
    
    tolerance = tol;
    thresh = threshold;
    N = levels;
    accuracy = acc;
    findSquares(image, squares);
    
    return image;
}

static double angle( cv::Point pt1, cv::Point pt2, cv::Point pt0 )
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

// returns sequence of squares detected on the image.
// the sequence is stored in the specified memory storage
//static void findSquares( const Mat& image, vector<vector<Point> >& squares )

static void findSquares(  const Mat& image,   vector<vector<cv::Point> >& squares )

{
    // blur will enhance edge detection
    Mat blurred(image);
    medianBlur(image, blurred, 9);
    
    Mat gray0(blurred.size(), CV_8U), gray;
    vector<vector<cv::Point> > contours;
    
    // find squares in every color plane of the image
    for (int c = 0; c < 3; c++)
    {
        int ch[] = {c, 0};
        mixChannels(&blurred, 1, &gray0, 1, ch, 1);
        
        // try several threshold levels
        const int threshold_level = 2;
        for (int l = 0; l < threshold_level; l++)
        {
            // Use Canny instead of zero threshold level!
            // Canny helps to catch squares with gradient shading
            if (l == 0)
            {
                Canny(gray0, gray, 10, 20, 3); //
                
                // Dilate helps to remove potential holes between edge segments
                dilate(gray, gray, Mat(), cv::Point(-1,-1));
            }
            else
            {
                gray = gray0 >= (l+1) * 255 / threshold_level;
            }
            
            // Find contours and store them in a list
            findContours(gray, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
            
            // Test contours
            vector<cv::Point> approx;
            for (size_t i = 0; i < contours.size(); i++)
            {
                // approximate contour with accuracy proportional
                // to the contour perimeter
                approxPolyDP(Mat(contours[i]), approx, arcLength(Mat(contours[i]), true)*0.02, true);
                
                // Note: absolute value of an area is used because
                // area may be positive or negative - in accordance with the
                // contour orientation
                if (approx.size() == 4 &&
                    fabs(contourArea(Mat(approx))) > 1000 &&
                    isContourConvex(Mat(approx)))
                {
                    double maxCosine = 0;
                    
                    for (int j = 2; j < 5; j++)
                    {
                        double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
                        maxCosine = MAX(maxCosine, cosine);
                    }
                    
                    if (maxCosine < 0.3)
                        squares.push_back(approx);
                }
            }
        }
    }
    for (int i = 0 ; i < squares.size() ; i++) {
        int tempX, tempY, radius = 50;
        tempX = (squares[i])[0].x;
        tempY = (squares[i])[0].y;
        cv::Rect tempR = cv::Rect(tempX-radius,tempY-radius,radius*2,radius*2);
        
        for (int j = i+1 ; j < squares.size(); j++) {
            if( tempR.contains(squares[j][0]) ){
                squares.erase(squares.begin() + j);
                j--;
            }
        }
        cout << squares[i] <<endl;
    }
    
            
        
    
    
    cout << squares.size() <<endl;
}

@end

