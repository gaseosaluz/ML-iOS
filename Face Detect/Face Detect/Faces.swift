//
//  AppDelegate.swift
//  Face Detect
//
//  Created by Ed Martinez on 1/20/20.
//  Copyright © 2020 Ed Martinez. All rights reserved.
//

// BEGIN FD_starter_ext_uii_imports
import UIKit
import Vision
// END FD_starter_ext_uii_imports

// BEGIN FD_starter_ext_uii
// If you are typing this code following the book's guidance you will have a build
// error in the "orientation: self.cgImageOrientation" line. This is because "cgImageOrientation"
// has not been defined yet. It will be defined when you create the file "Views.swift"

extension UIImage {
    func detectFaces(completion: @escaping ([VNFaceObservation]?) -> ()) {
        
        guard let image = self.cgImage else { return completion(nil) }
        let request = VNDetectFaceRectanglesRequest()
        
        // DispatchQueue.global runs the Image Request on a globla thread
        // this keeps the UI from being locked while the request is serviced
        DispatchQueue.global().async {
            let handler = VNImageRequestHandler(
                cgImage: image,
                orientation: self.cgImageOrientation
            )

            try? handler.perform([request])
            
            guard let observations =
                request.results as? [VNFaceObservation] else {
                    return completion(nil)
            }

            completion(observations)
        }
    }
}
// END FD_starter_ext_uii

