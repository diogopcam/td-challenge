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
        
        if (self.capturedImage != nil) {
            print("You can't take another photo before revealing the current one.")
        }
        
        let settings = AVCapturePhotoSettings()

        if let connection = output.connection(with: .video) {
            connection.videoOrientation = .landscapeRight
        }

        output.capturePhoto(with: settings, delegate: self)
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
            self.capturedImage = image
            print("Photo stored!")
        }
    }
}
