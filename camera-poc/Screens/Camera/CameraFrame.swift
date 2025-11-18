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

    func makeUIView(context: Context) -> PreviewView {
        return PreviewView(session: session)
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

