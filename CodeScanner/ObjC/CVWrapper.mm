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

    Mat photo = [CVWrapper CVMatFromUIImage:image];
    Mat photo2 = [CVWrapper CVMatFromUIImage:image];
    vector<vector<cv::Point> > squares = detectSquaresInImage(photo2, 20.0, 50, 7, 0);
    if(squares.size()< 4)
        return NO;
    
    cout <<  "More than 4 RECTS" << endl;
    vector<cv::Point> biggest = squares[0];
    int biggestPosition = 0;
    cv::Rect biggestRect = transformPointsToRect(biggest);
    
    cout <<  biggestRect << endl;
    cout <<  biggestRect.tl() << endl;
    cout <<  biggestRect.br() << endl;
    for (int i = 0 ; i < squares.size() -1 ; i++) {
        cv::Rect tempR2 = transformPointsToRect(squares[i+1]);
        if(biggestRect.width <= tempR2.width ){
            
            biggest = squares[i + 1];
            biggestPosition =  i+1;
            biggestRect = tempR2;
        }
    }
    
    
    cout <<  "RECTS" << endl;
    squares.erase(squares.begin() + biggestPosition);
    biggestRect = transformPointsToRect(biggest);
    vector<cv::Rect> rects;
    for (int i = 0 ; i < squares.size() ; i++) {
        cv::Rect tempR2 = transformPointsToRect(squares[i]);
        if( !(biggestRect.contains(tempR2.br()) && biggestRect.contains(tempR2.tl())) ){
            return NO;
        }
        else{
            rects.push_back(tempR2);
            cout <<  tempR2 << endl;
           
        }
    }
    
    BOOL orange= NO;
    BOOL green= NO;
    BOOL blue= NO;
    vector<cv::Scalar> colors;
    //colors.push_back(Scalar(8,170,80));
    colors.push_back(Scalar(0,80,50));
    colors.push_back(Scalar(39,80,50));
    colors.push_back(Scalar(75,190,80));
    vector<cv::Scalar> colors2;
    //colors2.push_back(Scalar(18,190,102));
    colors2.push_back(Scalar(26,255,255));
    colors2.push_back(Scalar(80,255,255));
    colors2.push_back(Scalar(130,255,255));
    Mat HSV;
    cvtColor(photo,HSV,CV_BGR2HSV);
    cout <<  "Color detection" << endl;
    for(int i = 0 ; i < rects.size() ; i++){
        cv::Mat croppedImage = HSV(rects[i]);
        
        Mat imgThresholded;
        
        cout <<  "Color detection about to do more stuff" << endl;
        for(int j = 0 ; j < colors.size() ; j++) {
        
            inRange(croppedImage,colors[j],colors2[j],imgThresholded);
            
            //morphological opening (removes small objects from the foreground)
            //erode(imgThresholded, imgThresholded, getStructuringElement(MORPH_ELLIPSE, cv::Size(5, 5)) );
            //dilate( imgThresholded, imgThresholded, getStructuringElement(MORPH_ELLIPSE, cv::Size(5, 5)) );
            
            //morphological closing (removes small holes from the foreground)
            //dilate( imgThresholded, imgThresholded, getStructuringElement(MORPH_ELLIPSE, cv::Size(5, 5)) );
            //erode(imgThresholded, imgThresholded, getStructuringElement(MORPH_ELLIPSE, cv::Size(5, 5)) );
            
            //Calculate the moments of the thresholded image
            Moments oMoments = moments(imgThresholded);
            
            double dArea = oMoments.m00;
            NSString *str = [NSString stringWithFormat: @"Image%d%d.png", i +3, j +3];
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:str];
            
            // Save image.
            [UIImagePNGRepresentation([CVWrapper UIImageFromCVMat:imgThresholded]) writeToFile:filePath atomically:YES];
            
            // if the area <= 10000, I consider that the there are no object in the image and it's because of the noise, the area is not zero
            if (dArea > 10)
            {
                if(j == 0)
                {
                    orange = YES;
                }
                if(j == 1)
                {
                    green = YES;
                }
                if(j == 2)
                {
                    blue = YES;
                }
            }
        }
        
        
    }
    
    //TODO:
    //Find the biggest one
    //Crop image to that rect
    //Detect blobs on the others
    //check colors
    
    
    return (blue && orange && green);
    //return YES;

}

static cv::Rect transformPointsToRect(vector<cv::Point> points)
{
    int x = points[0].x,y = points[0].y,x2 = points[0].x,y2 = points[0].y;
    for(int i = 0; i<3; i++){
        if(x > points[i+1].x){
            x = points[i+1].x;
        }
        if(y > points[i+1].y){
            y = points[i+1].y;
        }
        if(x2 < points[i+1].x){
            x2 = points[i+1].x;
        }
        if(y2 < points[i+1].y){
            y2 = points[i+1].y;
        }
    
    }
    return cv::Rect(x, y, x2 - x, y2 -y);
}


//this public function performs the role of
//main{} in the original file
static vector<vector<cv::Point> >  detectSquaresInImage (cv::Mat image, float tol, int threshold, int levels, int acc)
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
    
    return squares;
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





/*
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
}*/

@end

