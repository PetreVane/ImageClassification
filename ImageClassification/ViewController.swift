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
         Prepare for processing
         
         To output the frames of the video feed, we need to create an AVCaptureVideoDataOutput.
         
         */
        
        let output = AVCaptureVideoDataOutput()
        //
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        session.addOutput(output)
        session.addInput(input)
        session.startRunning()
    }
}
