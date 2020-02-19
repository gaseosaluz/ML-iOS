//
//  CaptureVideoPreviewView.swift
//  LanguageTutor
//
//  Created by Joshua Newnham on 30/11/2017.
//  Copyright © 2017 Josh Newnham. All rights reserved.
//

import AVFoundation
import UIKit

// Will be used to present captured video frames

class CapturePreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self

    }

}

