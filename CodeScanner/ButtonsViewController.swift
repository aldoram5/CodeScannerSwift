//
//  ButtonsViewController.swift
//  CodeScanner
//
//  Created by gbmobile on 1/16/15.
//  Copyright (c) 2015 gbmobile. All rights reserved.
//

import Foundation
import UIKit


class Buttons: UIViewController {
    
    @IBAction func openUrlXBOX(){
        UIApplication.sharedApplication().openURL(NSURL(string: "http://xbox.com/")!)
        
    }
    @IBAction func openUrlDuckMedia(){
        UIApplication.sharedApplication().openURL(NSURL(string: "http://duckmedia.com.mx/")!)
        
    }
    @IBAction func openUrlGoogle(){
        UIApplication.sharedApplication().openURL(NSURL(string: "http://google.com.mx/")!)
        
    }
    
    
}
