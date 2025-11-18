//
//  PreviewView.swift
//  camera-poc
//
//  Created by Diogo Camargo on 11/11/25.
//
import SwiftUI
import AVFoundation

class PreviewView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer!

    init(session: AVCaptureSession) {
        super.init(frame: .zero)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
        previewLayer.connection?.videoOrientation = .landscapeRight
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
