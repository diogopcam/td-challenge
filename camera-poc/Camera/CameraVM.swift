//
//  CameraVM.swift
//  camera-poc
//
//  Created by Diogo Camargo on 06/11/25.
//

import SwiftUI
import AVFoundation
import Combine
import SwiftUI
import AVFoundation

class CameraVM: NSObject, ObservableObject {

    @Published var isCameraAuthorized = false
    @Published var capturedImage: UIImage?
    @Published var errorMessage: String?

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

    func takePhoto() {
        let settings = AVCapturePhotoSettings()

        if let connection = output.connection(with: .video) {
            connection.videoOrientation = .landscapeRight
        }

        output.capturePhoto(with: settings, delegate: self)
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

}

extension CameraVM: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {

        if let error = error {
            errorMessage = "Erro ao capturar foto: \(error.localizedDescription)"
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            errorMessage = "Não foi possível processar a imagem"
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
