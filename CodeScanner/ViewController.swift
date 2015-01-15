//
//  ViewController.swift
//  CodeScanner
//
//  Created by gbmobile on 1/14/15.
//  Copyright (c) 2015 gbmobile. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{
    //UI related properties
    var previewView : UIView!;
    
    
    //Camera Capture requiered properties
    var videoDataOutput: AVCaptureVideoDataOutput!;
    var videoDataOutputQueue : dispatch_queue_t!;
    var previewLayer:AVCaptureVideoPreviewLayer!;
    var captureDevice : AVCaptureDevice!
    var session : AVCaptureSession! = AVCaptureSession();
    var currentFrame:CIImage!
    var prcocessFrame:Bool = false

    //IB references
    @IBOutlet var instructionsView:UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var screenSize = UIScreen.mainScreen().bounds.size;
        self.previewView = UIView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height));
        self.previewView.contentMode = UIViewContentMode.ScaleAspectFit
        self.view.addSubview(previewView);
        
        self.setupAVCapture();
        self.view.bringSubviewToFront(instructionsView)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldAutorotate() -> Bool {
        if (UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeLeft ||
            UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeRight ||
            UIDevice.currentDevice().orientation == UIDeviceOrientation.Unknown) {
                return false;
        }
        else {
            return true;
        }
    }
    
    //IBActions
    
    @IBAction func checkForCode(){
        UIGraphicsBeginImageContext(currentFrame.extent().size)
        UIImage(CIImage: currentFrame)?.drawAtPoint(CGPointZero)
        let tempUIImage: UIImage =  UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        CVWrapper.CheckIfCodeIsRecognized(tempUIImage);
    }

}

// AVCaptureVideoDataOutputSampleBufferDelegate protocol and related methods

extension ViewController:  AVCaptureVideoDataOutputSampleBufferDelegate{
     
    func setupAVCapture(){
        //session = AVCaptureSession();
        session.sessionPreset = AVCaptureSessionPreset640x480;
        
        let devices = AVCaptureDevice.devices();
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the front camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice;
                    if captureDevice != nil {
                        beginSession();
                        break;
                    }
                }
            }
        }
    }

    func beginSession(){
        var err : NSError? = nil
        var deviceInput:AVCaptureDeviceInput = AVCaptureDeviceInput(device: captureDevice, error: &err);
        if err != nil {
            println("error: \(err?.localizedDescription)");
        }
        if self.session.canAddInput(deviceInput){
            self.session.addInput(deviceInput);
        }
        
        self.videoDataOutput = AVCaptureVideoDataOutput();
        var rgbOutputSettings = [NSNumber(integer: kCMPixelFormat_32BGRA):kCVPixelBufferPixelFormatTypeKey];
        //self.videoDataOutput.videoSettings=rgbOutputSettings;
        self.videoDataOutput.alwaysDiscardsLateVideoFrames=true;
        self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        self.videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue);
        if session.canAddOutput(self.videoDataOutput){
            session.addOutput(self.videoDataOutput);
        }
        self.videoDataOutput.connectionWithMediaType(AVMediaTypeVideo).enabled = true;
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session);
        //self.previewLayer.backgroundColor = viewMessage.backgroundColor!.CGColor
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        
        var rootLayer :CALayer = self.previewView.layer;
        rootLayer.masksToBounds=true;
        self.previewLayer.frame = rootLayer.bounds;
        rootLayer.addSublayer(self.previewLayer);
        session.startRunning();
        
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        currentFrame =   Utils.convertImageFromCMSampleBufferRef(sampleBuffer);
        if(prcocessFrame){
        }
        // TODO: Detect blobs here
        
    }
    
    
    // clean up AVCapture
    func teardownAVCapture(){
        self.videoDataOutput = nil;
        self.previewLayer.removeFromSuperlayer();
        self.previewLayer = nil;
    }

    
    
    
    
}
