//
//  ViewController.swift
//  LanguageTutor
//
//  Created by Joshua Newnham on 16/12/2017.
//  Copyright © 2017 Method. All rights reserved.
//

import UIKit
import CoreVideo
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var previewView: CapturePreviewView!
    @IBOutlet weak var classifiedLabel: UILabel!
    
    let model = Inceptionv3()
    
    let videoCapture : VideoCapture = VideoCapture()
    let context = CIContext()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize ourselves to as the delegate to receive frames
        // Without this the model will not get data to Analyze
        
        self.videoCapture.delegate = self
        
        if self.videoCapture.initCamera(){
            // Assign the capture session instance being previewed
            (self.previewView.layer as! AVCaptureVideoPreviewLayer).session = self.videoCapture.captureSession
            // You use the videoGravity property to influence how content is viewed relative to the layer bounds;
            // in this case setting it to full the screen while respecting the aspec
            (self.previewView.layer as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravity.resizeAspectFill
            
            self.videoCapture.asyncStartCapturing()
        } else {
            fatalError("[ERROR] Failed to init Video Capture")
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - VideoCaptureDelegate

extension ViewController : VideoCaptureDelegate{
    
    func onFrameCaptured(videoCapture: VideoCapture,
                         pixelBuffer:CVPixelBuffer?,
                         timestamp:CMTime){
        // Unwrap the pixel butter - return early if it is NULL
        guard let pixelBuffer = pixelBuffer else{ return }
        
        // This is the method from where we feed the data to the model
        // to classify the dominant object in the frame
    
        // Prepare our image for the model (resizing)
        // resize to 299 x 299
        // If this is succesful we will have image to pass to the model
        guard let scaledPixelBuffer = CIImage(cvImageBuffer: pixelBuffer)
            .resize(size: CGSize(width: 299, height: 299))
            .toPixelBuffer(context: context) else {return}
        
        // Perform inference
        let prediction = try? self.model.prediction(image: scaledPixelBuffer)
        
        // Update the label
        DispatchQueue.main.sync {
            classifiedLabel.text = prediction?.classLabel ?? "Unknown"
        }
    }
}

