//
//  ContentView.swift
//  Face Detect
//
//  Created by Ed Martinez on 1/20/20.
//  Copyright © 2020 Ed Martinez. All rights reserved.
//

import SwiftUI
import Vision

struct ContentView: View {
    @State private var imagePickerOpen: Bool = false
    @State private var cameraOpen: Bool = false
    @State private var image: UIImage? = nil
    @State private var faces: [VNFaceObservation]? = nil
    
    private var faceCount: Int {return faces?.count ?? 0 }
    private let placeholderImage = UIImage(named: "placeholder")!
    
    private var cameraEnabled: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    private var detectionEnabled: Bool { image != nil && faces == nil}
    
    var body: some View {
        if imagePickerOpen {return imagePickerView() }
        if cameraOpen {return cameraView() }
        return mainView()
    }
    
    private func getFaces() {
        print("Getting Faces ...")
        self.faces = []
        self.image?.detectFaces { result in
            self.faces = result
        }
    }
    
    private func summonImagePicker() {
        print("Summoning Image Picker ...")
        imagePickerOpen = true
    }
    
    private func summonCamera() {
        print("Summoning Camera...")
        cameraOpen = true
    }
    
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension ContentView {
    private func mainView() -> AnyView {
        return AnyView(NavigationView {
            MainView(
                image: image ?? placeholderImage,
                text: "\(faceCount) face\(faceCount == 1 ? "" : "S")") {
                    TwoStateButton (
                        text: "Detect Faces",
                        disabled: !decttionEnabled,
                        action: getFaces
                    )
            }
            .padding()
            .navigationBarTitle(Text("Face Detect Demo"), displayMode: . inline)
            .navigationBarItems(
                leading: Button(action: summonImagePicker) {
                Text("Select")
                },
            trailing: Button(action: summonCamera) {
                Image(systemName: "camera")
            }.disabled(!cameraEnabled)
        )
        })
    }
    
    private func imagePickerView() -> AnyView {
        return AnyView(ImagePicker { result in
            self.controlReturned(image: result)
            self.imagePickerOpen = false
        })
    }
    
    private func cameraView() -> AnyView {
        return AnyView(ImagePicker(camera: true) { result in
            self.controlReturned(image: result)
            self.cameraOpen = false
        })
    }
}
