//
//  ContentView.swift
//  machinelearning
//
//  Created by Nicky on 15/11/2023.
//

import SwiftUI
import CoreML
import PhotosUI

extension UIImage{
    func toCVPixelBuffer() -> CVPixelBuffer?{
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.size.width), Int(self.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(self.size.width), height: Int(self.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer
    }
}


struct ContentView: View {
    let images = ["Persian_14", "Bengal_10", "Birman_7", "Bombay_4", "British_Shorthair_18", "Egyptian_Mau_1", "Abyssinian_6", "Ragdoll_5", "Siamese_17", "Sphynx_1"]
    var imageClassifier: CatBreedClassifier1_1?
    @State private var currentIndex = 0
    @State private var classLabel: String = ""
    @State var selectedItems: PhotosPickerItem? = nil
    init() {
        do {
            if let modelURL = Bundle.main.url(forResource: "CatBreedClassifier1_1", withExtension: "mlmodelc") {
                imageClassifier = try CatBreedClassifier1_1(contentsOf: modelURL, configuration: MLModelConfiguration())
            } else {
                print("Error: Model file not found in the app bundle.")
            }
        } catch {
            print("Error initializing the model: \(error)")
        }
    }

    var  isPreviousButtonValid: Bool {
        currentIndex != 0
    }
    
    var isNextButtonValid: Bool {
        currentIndex < images.count - 1
    }
    
        var body: some View {
            VStack {
                PhotosPicker(selection: $selectedItems,
                                    matching: .images) {
                           Text("Select a Cat")
                       }
                Image(images[currentIndex]).resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 300, height: 400, alignment: .topLeading)
                    .border(.blue)
                    .clipped()
                
                Button("Predict") {
                    // uiImage
                    guard let uiImage = UIImage(named: images[currentIndex]) else { return }

                    // pixelBuffer
                    guard let pixelBuffer = uiImage.toCVPixelBuffer() else { return }

                    do {
                        let result = try imageClassifier?.prediction(image: pixelBuffer)

                        // Access the predicted cat breed label
                        if let predictedBreed = result?.target {
                            classLabel = predictedBreed
                        } else {
                            classLabel = "Unknown"
                        }
                    } catch {
                        print(error)
                    }
                }.buttonStyle(.borderedProminent)
                Text(classLabel)
                HStack {
                    Button("Previous") {
                            currentIndex -= 1
                    }.disabled(!isPreviousButtonValid)
                    Button("Next") {
                            currentIndex += 1
                        }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isNextButtonValid)
                    .padding()
                    }
                
            }
            .padding()
        }
    }
    
struct Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

