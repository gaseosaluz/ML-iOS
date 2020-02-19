//
//  YOLOFacade.swift
//  ObjectDetection
//

import UIKit
import Photos
import CoreML
import Vision

class YOLOFacade{
    
    // Input size (of image)
    var targetSize = CGSize(width: 416, height: 416)
    
    // Grid size
    let gridSize = CGSize(width: 13, height: 13)
    
    // Number of classes
    let numberOfClasses = 20
    
    // Number of anchor boxes
    let numberOfAnchorBoxes = 5
    
    // Anchor shapes (describing aspect ratio)
    let anchors : [Float] = [1.08, 1.19, 3.42, 4,41, 6.63, 11.38, 9.42, 5.11, 16.62, 10.52]
    
    // We will use the Vision Framework to work with the Model
    lazy var model : VNCoreMLModel = {
        do{
            // Get the model
            let model = try VNCoreMLModel(
                for: tinyyolo_voc2007().model)
            return model
        } catch{
            fatalError("Failed to obtain tinyyolo_voc2007")
        }
    }()
    
    // Entry point of the class and called by PhotoSearcher for each
    // image it receives from the Photo Framework
    
    func asyncDetectObjects(photo:UIImage, completionHandler: @escaping (_ result:[ObjectBounds]?) -> Void){
        DispatchQueue.global(qos: .background).sync {
            
            self.detectObjects(photo: photo, completionHandler: { (result) -> Void in
                DispatchQueue.main.async {
                    completionHandler(result)
                }
            })
        }
    }
    
}

// MARK: - Core ML
// functionality to perform inference
extension YOLOFacade{
    // This is responsible for performing inferernce via the tinyyolo_voc2007 call and
    // VNImageRequestHandler. Then it passes the model's output to the detectObjectBounds
    // method and finally transforms the normalized bounds to the dimentions of the
    // original image.
    
    func detectObjects(photo:UIImage, completionHandler:(_ result:[ObjectBounds]?) -> Void){
        guard let cgImage = photo.cgImage else{
            completionHandler(nil)
            return
        }
        
        // reprocess image and pass to model
        let request = VNCoreMLRequest(model: self.model)
        request.imageCropAndScaleOption = .centerCrop
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform classification. \n\(error.localizedDescription)")
            completionHandler(nil)
            return
        }
        
        // Pass models results to detectObjectsBounds(::)
        
        guard let observations = request.results as? [VNCoreMLFeatureValueObservation] else {
            completionHandler(nil)
            return
        }
        var detectedObjects = [ObjectBounds]()
        
        for observation in observations{
            guard let multiArray = observation.featureValue.multiArrayValue else{
                continue
            }
            
            if let observationDetectedObjects = self.detectObjectsBounds(array: multiArray) {
                for detectedOject in observationDetectedObjects.map({$0.transformFromCenteredCropping(from: photo.size, to: self.targetSize)}){
                    detectedObjects.append(detectedOject)
                }
            }
        
        }
        completionHandler(detectedObjects)
        
    }
    
    func detectObjectsBounds(array:MLMultiArray, objectThreshold:Float = 0.3) -> [ObjectBounds]?{
        
        // Interpret the models output
        // This method receives a MLMultiArray with shape of (125, 13, 13). The (13,13) is the
        // shape of the grid. The 125 represents the encoding of five blocks each containing the
        // bounding box, the probability of an object being present and the probabioity distribution
        // across 20 classes.
        let gridStride = array.strides[0].intValue
        let rowStride = array.strides[1].intValue
        let colStride = array.strides[2].intValue
        
        let arrayPointer = UnsafeMutablePointer<Double>(OpaquePointer(array.dataPointer))
        
        var objectsBounds = [ObjectBounds]()
        var objectConfidences = [Float]()
        
        // iterate through the model's output and process each grid cell and anchor boxes
        
        for row in 0..<Int(gridSize.height) {
            for col in 0..<Int(gridSize.width) {
                for b in 0..<numberOfAnchorBoxes {
                    // Gives relevant offet for the specific grid cell
                    let gridOffset = row * rowStride + col * colStride
                    // Gives index of the associatd anchor box
                    let anchorBoxOffset = b * (numberOfClasses + numberOfAnchorBoxes)
                    
                    // Calculate the confidence of each class ignoring if under threshold
                    // We apply sigmoid to squash the values so that their sume is equal 1.0
                    // implementation of "sigmoid" is in the Math.swift ile
                    let confidence = sigmoid(x: Float(arrayPointer[(anchorBoxOffset+4) * gridStride + gridOffset]))
                    var classes = Array<Float>(repeating: 0.0, count: numberOfClasses)
                    for c in 0..<numberOfClasses{
                        classes[c] = Float(arrayPointer[(anchorBoxOffset + 5 + c) * gridStride + gridOffset])
                    }
                    classes = softmax(z: classes)
                    
                    let classIdx = classes.argmax
                    let classScore = classes[classIdx]
                    let classConfidence = classScore * confidence
                    
                    if classConfidence < objectThreshold {
                        continue
                    }
                    
                    // Obtain bounding box and transforms to image dimensions.
                    // Get four values from the grid's anchor box segment
                    let tx = CGFloat(arrayPointer[anchorBoxOffset * gridStride + gridOffset])
                    let ty = CGFloat(arrayPointer[(anchorBoxOffset + 1) * gridStride + gridOffset])
                    let tw = CGFloat(arrayPointer[(anchorBoxOffset + 2) * gridStride + gridOffset])
                    let th = CGFloat(arrayPointer[(anchorBoxOffset + 3) * gridStride + gridOffset])
                    
                    // Transform into from grid coordinate system to the image coordinate system
                    let cx = (sigmoid(x: tx) + CGFloat(col)) / gridSize.width
                    let cy = (sigmoid(x: ty) + CGFloat(row)) / gridSize.height
                    let w = CGFloat(anchors[2 * b + 0]) * exp(tw) / gridSize.width
                    let h = CGFloat(anchors[2 * b + 1]) * exp(th) / gridSize.height
                    
                    // Create a ObjectBounds instance and store it in our array of candidates.
                    guard let detectableObject = DetectableObject.objects.filter({$0.classIndex == classIdx}).first else {
                        continue
                    }
                    
                    let objectBounds = ObjectBounds(
                        object: detectableObject,
                        origin: CGPoint(x: cx - w/2, y: cy - h/2),
                        size: CGSize(width: w, height: h))
                    
                    objectsBounds.append(objectBounds)
                    objectConfidences.append(classConfidence)
                    
                    // By this time we have an array populatd with our candidae detected Objects
                    // Now we need to filter them
                    
                    return self.filterDetectedObjects(objectsBounds: objectsBounds, objectsConfidence: objectConfidences)
                    
                }
            }
        }
        return nil
    }
}

// MARK: - Non-Max Suppression
// Implementing the Non-Max Supression algorithm
// 1. Order detected boxes from most confident to least confident
// 2. As long as there are valid boxes (a) Pick the box with the highest confidence value
//    (this should be the top of the ordered array) and (b) iterate through all of the
//    remaining boxes descarding any with an IoU value greater than a predefined threshold.

extension YOLOFacade{
    
    func filterDetectedObjects(objectsBounds:[ObjectBounds],
                                 objectsConfidence:[Float],
                                 nmsThreshold : Float = 0.3) -> [ObjectBounds]?{
        
        // If there are no bounding boxes do nothing
        guard objectsBounds.count > 0 else{
            return []
        }
        
        // Implement Non-Max Suppression
        
        var detectionConfidence = objectsConfidence.map{(confidence) -> Float in
            return confidence
        }
        
        let sortedIndices = detectionConfidence.indices.sorted { detectionConfidence[$0] > detectionConfidence[$1]
            
        }
        
        var bestObjectBounds = [ObjectBounds]()
        
        // Iterate through each box
        
        for i in 0..<sortedIndices.count{
            let objectBounds = objectsBounds[sortedIndices[i]]
            guard detectionConfidence[sortedIndices[i]] > 0 else {
                continue
            }
            bestObjectBounds.append(objectBounds)
            
            for j in (i+1)..<sortedIndices.count{
                guard detectionConfidence[sortedIndices[j]] > 0 else {
                    continue
                }
                let otherObjectBounds = objectsBounds[sortedIndices[j]]
                
                // Calculate IoU and compare against our threshold.
                if Float(objectBounds.bounds.computeIOU(other: otherObjectBounds.bounds)) > nmsThreshold{detectionConfidence[sortedIndices[j]] = 0.0
                }
            }
        }
        
        return bestObjectBounds
    }
}
