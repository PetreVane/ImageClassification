//
//  ViewController.swift
//  ImageClassification
//
//  Created by Petre Vane on 03/12/2020.
//

import UIKit
import AVKit
import Vision
import CoreML

class ViewController: UIViewController {
    
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var backgroundView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        customizeBackgroundView()
        setupAVSession()
    }


    
    func customizeBackgroundView() {
        backgroundView.layer.cornerRadius = 25
    }
}

//  This ViewController conforms to the AVCaptureVideoDataOutputSampleBufferDelegate, so that it can receive each frame to process it individually from the live video feed
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func setupAVSession() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        // this session set its bitrate and resolution to Ultra High-Definition (4K)
        let session = AVCaptureSession()
        session.sessionPreset = .hd4K3840x2160
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        // set the previewLayer boundaries to your view boundaries
        previewLayer.frame = view.frame
        //set the asptect ration
        previewLayer.videoGravity = .resizeAspectFill
        // add the preview layer to a view you declared
        imageView.layer.addSublayer(previewLayer)
        
        /*
         README
         
         To output the frames of the video feed, we need to create an AVCaptureVideoDataOutput.
         
         A pixel buffer is a way to store a small amount of image data shortly before it needs to be used.
         In this app, we’ll use a pixel buffer to store individual frames of our video feed to later feed them into the image classification model.
         
         AVCaptureVideoDataOutputSampleBufferDelegate helps with extracting individual frames from video output and transform them into pixel buffer, that is compatible with
         our Core ML model.
         
         */
        
        let output = AVCaptureVideoDataOutput()
        //
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        session.addOutput(output)
        session.addInput(input)
        session.startRunning()
    }
    
    // The sampleBuffer parameter of this method is where the delegate passes in an image buffer.
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // cast the camera output (image) buffer into pixel buffer
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // create a VNCoreMLModel version of the MLmodel you imported in your project
        guard let model = try? VNCoreMLModel(for: MobileNetV2(configuration: MLModelConfiguration()).model) else { return }
        
        // create a request
        let request = VNCoreMLRequest.init(model: model) { [self] (data, error) in
            guard error == nil else { return }
            guard let result = data.results as? [VNClassificationObservation] else { return }
            guard let firstObject = result.first else { return }
            
            DispatchQueue.main.async {
                if firstObject.confidence * 100 >= 20 {
                  
                    self.predictionLabel.text = firstObject.identifier.capitalized
                    self.confidenceLabel.text = String(firstObject.confidence * 100) + "%"
                    
                } else {
                    self.predictionLabel.text = "--"
                    self.confidenceLabel.text = "--"
                }
            }
        }
        
        // run your request
        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        } catch (let error) {
            print("VNImageRequestHandler thrown an error: \(error.localizedDescription)")
        }
       
    }
}
