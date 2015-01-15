//
//  CVWrapper.h
//  CodeScanner
//
//  Created by gbmobile on 1/14/15.
//  Copyright (c) 2015 gbmobile. All rights reserved.
//

#ifndef CodeScanner_CVWrapper_h
#define CodeScanner_CVWrapper_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>

@interface CVWrapper : NSObject


//+(bool )CheckIfFaceIsRecognized :( UIImage*) image;
//+(void )CreateLBPHFaceRecognizer:( NSString * ) csv;
//+(void )LoadLBPHFaceRecognizer;
//+(void ) ForceSaveRecognizer;
+(bool )CheckIfCodeIsRecognized :( UIImage*) image;

@end


#endif
