//
//  CameraVM.swift
//  camera-poc
//
//  Created by Diogo Camargo on 06/11/25.
//

import SwiftUI
import AVFoundation
import Combine

class CameraVM: NSObject, ObservableObject {

    @Published var isCameraAuthorized = false
    @Published var capturedImage: UIImage?
    @Published var errorMessage: String?
    @Published var isFlashOn: Bool = false
    @Published var timerDelay: Int = 0
    @Published var countdown: Int? = nil
    @Published var exposure: Float = 0.0 {
        didSet {
            setExposureBias(to: exposure)
        }
    }

    let session = AVCaptureSession()
    let output = AVCapturePhotoOutput()

    override init() {
        super.init()
        checkCameraPermission()
    }

    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
            isCameraAuthorized = true

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                        self?.isCameraAuthorized = true
                    } else {
                        self?.errorMessage = "Permissão da câmera negada"
                    }
                }
            }

        default:
            errorMessage = "Permissão da câmera não concedida"
        }
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            errorMessage = "Não foi possível acessar a câmera"
            return
        }

        session.beginConfiguration()

        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        }

        session.inputs.forEach { session.removeInput($0) }

        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }

        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
    
    func cropToSquare(image: UIImage) -> UIImage? {
        let originalWidth  = image.size.width
        let originalHeight = image.size.height
        let squareSize = min(originalWidth, originalHeight)

        let x = (originalWidth - squareSize) / 2
        let y = (originalHeight - squareSize) / 2

        let cropRect = CGRect(x: x, y: y, width: squareSize, height: squareSize)

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    private func startCountdown() {
        countdown = timerDelay
        var remaining = timerDelay

        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            remaining -= 1
            DispatchQueue.main.async {
                if remaining > 0 {
                    self.countdown = remaining
                } else {
                    timer.invalidate()
                    self.countdown = nil
                    self.captureNow()
                }
            }
        }
    }

}

extension CameraVM: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {

        if let error = error {
            errorMessage = "Error to capture photo: \(error.localizedDescription)"
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            errorMessage = "It wasn't possible to render the image"
            return
        }
        
        DispatchQueue.main.async {
            if let squared = self.cropToSquare(image: image) {
                self.capturedImage = squared
            } else {
                self.capturedImage = image
            }
        }
    }
}

// MARK: Button actions
extension CameraVM {
    func takePhoto() {
        if timerDelay > 0 {
            startCountdown()
        } else {
            captureNow()
        }
    }
    
    private func captureNow() {
        let settings = AVCapturePhotoSettings()

        // Flash
        if output.supportedFlashModes.contains(.on) {
            settings.flashMode = isFlashOn ? .on : .off
        }

        if let connection = output.connection(with: .video) {
            connection.videoOrientation = .landscapeRight
        }

        output.capturePhoto(with: settings, delegate: self)
        print("Photo captured!")
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
        print("The flash state is \(isFlashOn ? "on" : "off")")
    }
    
    private func setExposureBias(to value: Float) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        do {
            try device.lockForConfiguration()
            device.setExposureTargetBias(value, completionHandler: nil)
            device.unlockForConfiguration()
        } catch {
            print("Error setting exposure bias: \(error)")
        }
    }
}
