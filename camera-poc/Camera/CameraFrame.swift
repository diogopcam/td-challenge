//
//  CameraFrame.swift
//  camera-poc
//
//  Created by Diogo Camargo on 06/11/25.
//

import SwiftUI
import AVFoundation

struct CameraFrame: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.frame
        previewLayer.connection?.videoOrientation = .landscapeRight
        
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
