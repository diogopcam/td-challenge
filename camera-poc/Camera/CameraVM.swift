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
    var objectWillChange: ObservableObjectPublisher
    
    @Published var isCameraAuthorized = false
    @Published var capturedImage: UIImage?
    @Published var errorMessage: String?
    
    // Abre a camera e define configuracoes
    public let session = AVCaptureSession()
    
    // Responsavel por capturar as fotos, aplicar configuracoes (flash, resolucao, HDR, entregar a foto como Data, UIImage, lidar com Delegate
    public let output = AVCapturePhotoOutput()
    
    override init() {
        objectWillChange = nil as ObservableObjectPublisher? ?? ObservableObjectPublisher()
        super.init()  // Agora o objectWillChange já está inicializado
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

        // Preset seguro para todas as lentes do iPhone 16
        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        }

        if !session.inputs.isEmpty {
            for oldInput in session.inputs {
                session.removeInput(oldInput)
            }
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()

        // Sempre iniciar em background, mas usando a mesma queue
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func takePhoto() {
        // Aqui é onde definiremos o estilo da foto
        //        flash (on/off/auto)
        //        HDR
        //        qualidade
        //        depthData
        //        estabilização
        //        formato (HEIC, JPEG)
        //        resolução
        //        filtros
        
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraVM: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
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
            print("Imagem foi armazenada!")
        }
    }
}
