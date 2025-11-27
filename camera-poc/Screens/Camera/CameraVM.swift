//
//  CameraVM.swift
//  camera-poc
//
//  Created by Diogo Camargo on 06/11/25.
//

import SwiftUI
import AVFoundation
import Combine

class CameraVM: NSObject, ObservableObject, CameraVMProtocol {

    override init() {
        super.init()
        checkCameraPermission()
    }
    
    @Published var isCameraAuthorized = false
    @Published var isCapturing = false
    @Published var capturedImage: UIImage?
    @Published var errorMessage: String?
    @Published var isFlashOn: Bool = false
    @Published var timerDelay: Int = 0
    @Published var countdown: Int? = nil
    @Published var currentFrame: UIImage?
    @Published var showCapturedPhoto: Bool = false
    
    var currentFramePublisher: Published<UIImage?>.Publisher { $currentFrame }
    
    @Published var exposure: Float = 0.0 {
        didSet {
            setExposureBias(to: exposure)
        }
    }

    let session = AVCaptureSession()
    let output = AVCapturePhotoOutput()
    let videoOutput = AVCaptureVideoDataOutput()
    private let context = CIContext()
    
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
    
    func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            errorMessage = "It wasn't possible to access the camera"
            return
        }

        session.beginConfiguration()

        if session.canSetSessionPreset(.hd1280x720) {
            session.sessionPreset = .hd1280x720
        }

        session.inputs.forEach { session.removeInput($0) }

        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
        
        setupVideoFeed()
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
    
    func setupVideoFeed() {
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.feed.queue"))
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        if let videoConnection = videoOutput.connection(with: .video) {
            videoConnection.videoOrientation = .landscapeRight
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
    
    func startCountdown() {
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
            
            self.showCapturedPhoto = true
        }
    }
}

extension CameraVM: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        processVideoFrame(sampleBuffer)
    }
    
    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        let transform = CGAffineTransform(rotationAngle: .pi/2)
        let rotatedImage = ciImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(rotatedImage, from: rotatedImage.extent) else { return }
        
        let processedImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
        
        DispatchQueue.main.async {
            self.currentFrame = processedImage
        }
    }
}

// MARK: Button actions
extension CameraVM {
    func takePhoto() {
        guard !isCapturing else { return }
        isCapturing = true
        
        if timerDelay > 0 {
            startCountdown()
        } else {
            captureNow()
        }
    }
    
    func captureNow() {
        let settings = AVCapturePhotoSettings()

        if output.supportedFlashModes.contains(.on) {
            settings.flashMode = isFlashOn ? .on : .off
        }

        if let connection = output.connection(with: .video) {
            connection.videoOrientation = .landscapeRight
        }

        output.capturePhoto(with: settings, delegate: self)
        print("Photo captured!")
        self.isCapturing = false
    }
    
    func toggleFlash() {
        isFlashOn.toggle()
        print("The flash state is \(isFlashOn ? "on" : "off")")
    }
    
    func setExposureBias(to value: Float) {
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
