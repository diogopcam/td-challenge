//
//  CameraService.swift
//  CameraAndBlenderPOC
//
//  Created by Gabriel Barbosa on 21/11/25.
//

import Foundation
import AVFoundation
import UIKit

class CameraServiceMF: NSObject {
    
    private var captureSession: AVCaptureSession?
    private var captureDevice: AVCaptureDevice?
    private let context = CIContext()
    
    var onFrameCaptured: ((UIImage) -> Void)?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .vga640x480
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            print("Erro: Câmera não disponível.")
            return
        }
        
        self.captureDevice = device
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.feed.queue"))
        
        output.alwaysDiscardsLateVideoFrames = true
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        self.captureSession = session
    }
    
    func start() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
        }
    }
    
    func stop() {
        self.captureSession?.stopRunning()
    }
    
    // MARK: - Controle de Hardware
    
    func setExposureBias(_ bias: Float) {
        guard let device = captureDevice else { return }
        
        do {
            try device.lockForConfiguration()
            let clampedBias = max(device.minExposureTargetBias, min(device.maxExposureTargetBias, bias))
            device.setExposureTargetBias(clampedBias, completionHandler: nil)
            device.unlockForConfiguration()
        } catch {
            print("Erro ao ajustar exposição: \(error)")
        }
    }
}

// MARK: - Delegate de Vídeo
extension CameraServiceMF: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let uiImage = imageFromSampleBuffer(sampleBuffer) else { return }
        
        DispatchQueue.main.async {
            self.onFrameCaptured?(uiImage)
        }
    }
    
    private func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        
        var ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        let deviceOrientation = UIDevice.current.orientation
        switch deviceOrientation {
        case .landscapeLeft:
            ciImage = ciImage.oriented(.left)
        case .landscapeRight:
            ciImage = ciImage.oriented(.right)
        case .portrait:
            ciImage = ciImage.oriented(.right)
        default:
            ciImage = ciImage.oriented(.right)
        }
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
    }
}
