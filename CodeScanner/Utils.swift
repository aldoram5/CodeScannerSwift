//
//  Utils.swift
//  CodeScanner
//
//  Created by gbmobile on 1/14/15.
//  Copyright (c) 2015 gbmobile. All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage
import UIKit

 class Utils {
    
// MARK: - AVCapture Utils
    
    class func convertImageFromCMSampleBufferRef(sampleBuffer:CMSampleBuffer) -> CIImage{
        
        let pixelBuffer:CVPixelBufferRef  = CMSampleBufferGetImageBuffer(sampleBuffer);
        var ciImage:CIImage  = CIImage(CVPixelBuffer: pixelBuffer)
        
        //NSDictionary *imageOptions = [self dictionaryOptionsForImage];
        
        return ciImage;
    }
  
// MARK: - UIImage Utils
    
    class func cropImage(image:UIImage, toRect:CGRect) -> UIImage{
        let ref:CGImageRef = CGImageCreateWithImageInRect(image.CGImage, toRect);
        let cropped:UIImage = UIImage(CGImage: ref)!;
        return cropped;
        
    }
    
    class func rotateUIImage(sourceImage:UIImage, clockwise:Bool)->UIImage
    {
        let size:CGSize = sourceImage.size;
        UIGraphicsBeginImageContext(CGSize(width: size.height, height: size.width));
        UIImage(CGImage: sourceImage.CGImage, scale: 1.0, orientation: clockwise ? UIImageOrientation.Right : UIImageOrientation.Left)?.drawInRect(CGRect(origin: CGPointZero, size: CGSize(width: size.height, height: size.width)))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return newImage;
    }

}