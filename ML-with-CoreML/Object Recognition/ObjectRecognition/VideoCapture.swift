//
//  VideoCapture.swift
//  LanguageTutor
//
//  Created by Joshua Newnham on 29/11/2017.
//  Copyright © 2017 Josh Newnham. All rights reserved.
//

import UIKit
import AVFoundation

public protocol VideoCaptureDelegate: class {
    func onFrameCaptured(videoCapture: VideoCapture, pixelBuffer:CVPixelBuffer?, timestamp:CMTime)
    
    // VideoCapture will pass the captured video frames to a delegate
}

/**
 Class used to faciliate accessing each frame of the camera using the AVFoundation framework (and presenting
 the frames on a preview view)
 https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutput
 */
public class VideoCapture : NSObject{
    
    public weak var delegate: VideoCaptureDelegate?
    
    /**
     Frames Per Second; used to throttle capture rate. We assume that we can
     capture frames faster than we can process them, so we throtle the capture
     */
    public var fps = 15    
    
    // Used to calculate the elapsed time since we processed the last frame
    var lastTimestamp = CMTime()
    
    let captureSession = AVCaptureSession()
    let sessionQueue = DispatchQueue (label: "Session Queue")
    
    override init() {
        super.init()
        
    }
    
    // In this method, we want to set up the pipeline that will grab the frames from the
    // physical camera of the device and pass them onto our delegate method.
    
    // We do this by first getting a reference to the physical camera and then wrapping
    // it in an instance of the AVCaptureDeviceInput class, which takes care of managing
    // the connection and communication with the physical camera.
    
    // Finally, we add a destination for the frames, which is where we use an instance of
    // AVCaptureVideoDataOutput, assigning ourselves as the delegate for receiving these frames.
    // This pipeline is wrapped in something called AVCaptureSession, which is
    // responsible for coordinating and managing this pipeline.

    func initCamera() -> Bool{
        // Indicate that we want to make configuration changes
        captureSession.beginConfiguration()
        
        // Set the quality level of the output
        captureSession.sessionPreset = AVCaptureSession.Preset.medium
        
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            print ("[ERROR]: No video devices available")
            return false
        }
        
        // Try and create a AVCaptureDeviceInput (sub-class of AVCaptureInput) to capture data from the camera (captureDevice)
        
        guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("[ERROR] Could not open AVCaptureDeviceInput")
            return false
        }
        
        // Add the video feed to the session
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        /*
         A capture output that records video and provides access to video frames for processing.
         This will provide us with uncompressed frames, passed via the delegate method captureOutput(_:didOutput:from:).
         */
        let videoOutput = AVCaptureVideoDataOutput()
        
        // Request full colr
        // The kCVPixelFormatType_32RGBA does not work on iPhone Xs, Error says to
        // discover available types by using availableVideoCVPixelFormatTypes
        // This works: kCVPixelFormatType_32BGRA?
        let settings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        videoOutput.videoSettings = settings
        
        // Discard any frames that arrives while the dispatch queue is busy
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        // Assign ourselves as the delegate for handling incoming video frames
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        
        if captureSession.canAddOutput(videoOutput){
            captureSession.addOutput(videoOutput)
        }
        
        // We want the buffers to be in portrait orientation otherwise they are rotated by
        // 90 degrees (set this after addOutput:) has been called
        videoOutput.connection(with: AVMediaType.video)?.videoOrientation = .portrait
        
        // Commit all of these configurations so that they can take effect
        
        captureSession.commitConfiguration()
        return true
    }
    
    /**
     Start capturing frames
     This is a blocking call which can take some time, therefore you should perform session setup off
     the main thread to avoid blocking it.
     */
    public func asyncStartCapturing(completion: (() -> Void)? = nil){
        sessionQueue.async {
            // start flowing of data from the subscribed inputs (cameras)
            // to the the subscribed outputs (the delegate)
            
            // NB: The startRunning() method is the blocking call which can take some time, which is why it's run off the main queue
            
            if !self.captureSession.isRunning{
                self.captureSession.startRunning()
            }
        
            if let completion = completion{
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
    
    /**
     Stop capturing frames. It stops the camera session
     */
    public func asyncStopCapturing(completion: (() -> Void)? = nil){
        sessionQueue.async {
            if self.captureSession.isRunning{
                self.captureSession.stopRunning()
            }
            
            if let completion = completion{
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
// This is responsible for handling the frames that come from the camera

extension VideoCapture : AVCaptureVideoDataOutputSampleBufferDelegate{

    
    /**
     Called when a new video frame was written
     output - references the associated output this frame originated from
     samplBuffer - We use this to access the data from the current buffer
     connection - provides a reference to the connection associated with the current frame
     
     */
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // If no delegate assigned, then just return
        guard let delegate = self.delegate else {return}
        
        // Returns the earliest presentation timestamp of all the samples in a CMSampleBuffer
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        let elapsedTime = timestamp - lastTimestamp
        if elapsedTime >= CMTimeMake(1, Int32(fps)) {
            // Update time stamp
            lastTimestamp = timestamp
            // get sample buffer's CVImageBuffer
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            // pass onto the assigned delegate
            delegate.onFrameCaptured(videoCapture: self,
                                     pixelBuffer: imageBuffer,
                                     timestamp: timestamp)
        }
        
    }
    /**
     Called when a frame is dropped
     */
    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Ignore
    }
}

