//: Playground - noun: a place where people can play

import UIKit
import Vision
import CoreML
import PlaygroundSupport

// Required to run tasks in the background
PlaygroundPage.current.needsIndefiniteExecution = true

// Required to run tasks in the background
PlaygroundPage.current.needsIndefiniteExecution = true
var images = [UIImage]()
for i in 1...3 {
    guard let image = UIImage(named:"images/joshua_newnham_\(i).jpg")
        else {
            fatalError("Failed to extract features")
    }
    images.append(image)
}

let faceIdx = 0
let imageView = UIImageView(image: images[faceIdx])
imageView.contentMode = .scaleAspectFit

// Set up the type of analysis
let faceDetectionRequest = VNDetectFaceRectanglesRequest()
// Handler to execute the request
let faceDetectionRequestHandler = VNSequenceRequestHandler()

try?faceDetectionRequestHandler.perform([faceDetectionRequest], on: images[faceIdx].cgImage!, orientation: CGImagePropertyOrientation(images[faceIdx].imageOrientation))

// Once the analysis is done we can look at the observation
// boundingbox property gives us the bounding box for the face. The result is normalized
// so it needs to be scaled to fit the actual face in the picture we provided.
// the image object has properties that allows us to do this. For example
// the the width of the image is bbox.width * imagesize.width

if let faceDetectionResults = faceDetectionRequest.results as? [VNFaceObservation]{
    for face in faceDetectionResults {
        if let currentImage = imageView.image {
            let bbox = face.boundingBox
            
            let imageSize = CGSize(width: currentImage.size.width, height: currentImage.size.height)
            
            let w = bbox.width * imageSize.width
            let h = bbox.height * imageSize.height
            let x = bbox.origin.x * imageSize.width
            let y = bbox.origin.y * imageSize.height
            
            let faceRect = CGRect(x: x, y: y, width: w, height: h)
            
            // The coordinate system of Quartz 2D is inverted from UIKit.
            // We fix this by subtracting the bounding box's origin and height from height of the image
            // and then passing this to our UIImageView to render the rectangle.
            
            let invertedY = imageSize.height - (faceRect.origin.y + faceRect.height)
            
            let invertedFaceRect = CGRect(x: x, y: invertedY, width: w, height: h)
            
            imageView.drawRect(rect: invertedFaceRect)
            
        }
    }
}

// Try a new way of detecting faces. This method while it does detect the face
// it also detects facial landmarks such as eyes, ears, etc.

imageView.image = images[faceIdx]
let faceLandMarkRequest = VNDetectFaceLandmarksRequest()

try? faceDetectionRequestHandler.perform([faceLandMarkRequest],
                                         on: images[faceIdx].cgImage!,
                                        orientation: CGImagePropertyOrientation(images[faceIdx].imageOrientation))

// Let's iterate through some of the images and extract the landmarks
if let faceLandMarkDetectionResults = faceLandMarkRequest.results as? [VNFaceObservation]{
    for face in faceLandMarkDetectionResults{
        if let currentImage = imageView.image{
        let bbox = face.boundingBox
        let imageSize = CGSize(width: currentImage.size.width, height: currentImage.size.height)
            
        let w = bbox.width * imageSize.width
        let h = bbox.height * imageSize.height
        let x = bbox.origin.x * imageSize.width
        let y = bbox.origin.y * imageSize.height
        
        let faceRect = CGRect(x: x, y:y, width: w, height: h)
        
        func getTransformedPoints(
            landmark: VNFaceLandmarkRegion2D,
            faceRect: CGRect,
            imageSize:CGSize) -> [CGPoint]{
            return landmark.normalizedPoints.map({ (np) -> CGPoint in
                return CGPoint(
                    x: faceRect.origin.x + np.x * faceRect.size.width,
                    y: imageSize.height - (np.y * faceRect.size.height + faceRect.origin.y))
            })
            }
            let landmarkWidth : CGFloat = 1.5
            let landmarkColor : UIColor = UIColor.red
            
            if let landmarks = face.landmarks?.leftEye {
                let transformedPoints = getTransformedPoints(
                    landmark: landmarks,
                    faceRect: faceRect,
                    imageSize: imageSize)
                imageView.drawPath(pathPoints: transformedPoints, closePath: true, color: landmarkColor, lineWidth: landmarkWidth, vFlip: false)
             var center = transformedPoints
                .reduce(CGPoint.zero, { (result, point) -> CGPoint in
                    return CGPoint(
                        x:result.x + point.x,
                        y:result.y + point.y)
                })
                
            center.x /= CGFloat(transformedPoints.count)
            center.y /= CGFloat(transformedPoints.count)
            imageView.drawCircle(center: center,
                                 radius: 2,
                                 color: landmarkColor,
                                 lineWidth: landmarkWidth,
                                 vFlip: false)
            }
            
            if let landmarks = face.landmarks?.rightEye {
                let transformedPoints = getTransformedPoints(landmark: landmarks,
                                                             faceRect: faceRect,
                                                             imageSize: imageSize)
                imageView.drawPath(pathPoints: transformedPoints,
                                   closePath: true,
                                   color: landmarkColor,
                                   lineWidth: landmarkWidth,
                                   vFlip: false)
                
                var center = transformedPoints.reduce(CGPoint.zero, { (result, point) -> CGPoint in
                    return CGPoint (
                        x:result.x + point.x,
                        y:result.y + point.y)
                    
               
                })
                
                center.x /= CGFloat(transformedPoints.count)
                center.y /= CGFloat(transformedPoints.count)
                imageView.drawCircle(center: center,
                                     radius: 2,
                                     color: landmarkColor,
                                     lineWidth: landmarkWidth,
                                     vFlip: false)
            }
            
            if let landmarks = face.landmarks?.faceContour {
                let transformedPoints = getTransformedPoints(
                    landmark: landmarks,
                    faceRect: faceRect,
                    imageSize: imageSize)
                
                imageView.drawPath(pathPoints: transformedPoints,
                                   closePath: false,
                                   color: landmarkColor,
                                   lineWidth: landmarkWidth,
                                   vFlip: false)
                
                if let landmarks = face.landmarks?.nose {
                    let transformedPoints = getTransformedPoints(landmark: landmarks,
                                                                 faceRect: faceRect,
                                                                 imageSize: imageSize)
                    imageView.drawPath(pathPoints: transformedPoints,
                                      closePath: false,
                                      color: landmarkColor,
                                      lineWidth: landmarkWidth, vFlip: false)
                }
                
            
            if let landmarks = face.landmarks?.noseCrest {
                let transformedPoints = getTransformedPoints(landmark: landmarks,
                                                             faceRect: faceRect,
                                                             imageSize: imageSize)
                
                imageView.drawPath(pathPoints: transformedPoints,
                                   closePath: false,
                                   color: landmarkColor,
                                   lineWidth: landmarkWidth,
                                   vFlip: false)
            }
            
        imageView.image = images[faceIdx]
        let model = ExpressionRecognitionModelRaw()
                
                if let faceDetectionResults = faceDetectionRequest.results as? [VNFaceObservation]{
                    for face in faceDetectionResults{
                        if let currentImage = imageView.image{
                            let bbox = face.boundingBox
                            
                        let imageSize = CGSize(width: currentImage.size.width, height: currentImage.size.height)
                        let w = bbox.width * imageSize.width
                        let h = bbox.height * imageSize.height
                        let x = bbox.origin.x * imageSize.width
                        let y = bbox.origin.y * imageSize.height
                            
                        let faceRect = CGRect(x: x,
                                              y: y,
                                              width: w,
                                              height: h)
                            
                        }
                    }
                }
                
            // Similar to what we wrote before execpt the instatiation of the model.
            
            // Next we want to crop the face from the rest of the image.
            // we will write that code in a seprate file so that it can taken
            // to another app. The code will be an extension to CIImage. Code is
            // not in this notebook, but rather in a seprate file in the
            // 'sources' folder.
            
        let ciImage = CIImage(cgImage: images[faceIdx].cgImage!)
        
        let cropRect = CGRect(x: max(x - (faceRect.width * 0.15),0),
                              y: max(y - (faceRect.height * 0.1),0),
                              width: min(w + (faceRect.width * 0.3), imageSize.height),
                              height: min(h + (faceRect.height * 0.6), imageSize.height))
        guard let croppedCIImage = ciImage.crop(rect: cropRect)
            else{
                fatalError("Failed to crop image")
                }
        //
        
        let resizedCroppedCIImage = croppedCIImage.resize(size: CGSize(width: 48, height: 48))
        
        // Get raw pixels from cropped image, and rescale them by
        // dividig them by the max value (255)
        guard let resizedCroppedCIImageData =
            resizedCroppedCIImage.getGrayScalePixelData() else {
                fatalError("Failed to get GrayScale Image")
                }
                let scaledImageData = resizedCroppedCIImageData.map( {(pixel) -> Double in return Double(pixel)/255.0
                })
         
        guard let array = try? MLMultiArray(shape: [1, 48, 48], dataType: .double) else {
                fatalError("Unable to create MLMultiArray")
            }
        
        for (index, element) in scaledImageData.enumerated() {
                array[index] = NSNumber(value: element)
                }

        DispatchQueue.global(qos: .background).async {
            let prediction = try? model.prediction(
                image: array)
             if let classPredictions = prediction?.classLabelProbs{
                DispatchQueue.main.sync {
                    for (k, v) in classPredictions{
                        print("\(k) \(v)")
                    }
                }
            }
        }  
            }
        }
    }


}




