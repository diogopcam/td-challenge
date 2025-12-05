//
//  Coordinator.swift
//  camera-poc
//
//  Created by Diogo Camargo on 27/11/25.
//

import SwiftUI
import Combine
import RealityKit
import CoreImage

class Camera3DCoordinator: NSObject, UIGestureRecognizerDelegate {
    weak var arView: ARView?
    var rootModelEntity: Entity? {
        didSet {
                // Assim que o modelo for carregado, se não houver frame da câmera, aplica o placeholder
                if let root = rootModelEntity, cameraVM.currentFrame == nil {
                    applyPlaceholder(to: root)
                }
            }
    }
    
    var onDismissAction: (() -> Void)?

    let cameraVM: CameraVM
    var exposureButton: ExposureButton?
    var timerSlider: TimerSlider?
    var captureButton: CaptureButton?
    var flashButton: FlashButton?
    
    private var activeKnob: ExposureButton?
    private var activeSlider: TimerSlider?
    
    var cancellables = Set<AnyCancellable>()
    
    init(cameraVM: CameraVM) {
        self.cameraVM = cameraVM
        super.init()
        
        cameraVM.$currentFrame
            .receive(on: RunLoop.main)
            .sink { [weak self] image in
                guard let self = self,
                      let image = image,
                      let root = self.rootModelEntity else { return }

                self.applyCameraImage(image, to: root)
            }
            .store(in: &cancellables)
    }

    func setupControls(root: Entity) {
        if let expBtn = ExposureButton(rootEntity: root, entityName: "Cylinder") {
            self.exposureButton = expBtn
            expBtn.onValueChange = { [weak self] newValue in
                self?.cameraVM.setExposureBias(to: -newValue)
            }
        }
        if let timer = TimerSlider(rootEntity: root) {
            self.timerSlider = timer
            timer.onValueChange = { [weak self] val in
                guard let self = self else { return }
                self.cameraVM.timerDelay = Int(val)
                print("⏱ Novo timer: \(self.cameraVM.timerDelay)s")
            }
        }
        if let flash = FlashButton(rootEntity: root, entityName: "FlashSelector") {
            self.flashButton = flash
            flash.onToggle = { [weak self] isOn in
                self?.cameraVM.toggleFlash()
            }
        }
        if let capture = CaptureButton(rootEntity: root, entityName: "CaptureButton") {
            self.captureButton = capture
            capture.onCapture = { [weak self] in
                guard let self = self else { return }
                
                // Se houver delay, desabilitar botão ANTES de iniciar o countdown
                if self.cameraVM.timerDelay > 0 {
                    capture.disable()
                    
                    // Quando o countdown terminar, reabilita o botão
                    self.cameraVM.onCountdownFinished = {
                        capture.enable()
                    }
                }

                self.cameraVM.takePhoto()
            }

        }
    }
    
    func applyPlaceholder(to root: Entity) {
        guard let photoPlaneEntity = findModelEntity(named: "PhotoPlane", in: root) else { return }
        
        let placeholderImage = UIImage(named: "emptyImage") ?? UIImage(systemName: "camera.fill")
        
        guard let cgImage = placeholderImage?.cgImage else { return }
        
        do {
            let texture = try TextureResource.generate(from: cgImage, options: .init(semantic: .color))
            var material = UnlitMaterial()
            material.color = .init(tint: .white, texture: .init(texture))
            
            photoPlaneEntity.model?.materials = [material]
        } catch {
            print("Erro ao aplicar placeholder: \(error)")
        }
    }
    
    func applyCameraImage(_ image: UIImage, to root: Entity) {
        guard let photoPlaneEntity = findModelEntity(named: "PhotoPlane", in: root) else { return }
        
        // Processa a imagem para manter a proporção correta
        let processedImage = processImageForTexture(image)
        guard let cgImage = processedImage.cgImage else { return }
        
        do {
            let texture = try TextureResource.generate(from: cgImage, options: .init(semantic: .color))
            var material = UnlitMaterial()
            material.color = .init(tint: .white, texture: .init(texture))
            photoPlaneEntity.model?.materials = [material]
        } catch { print(error) }
    }
    
    /// Processa a imagem para manter a proporção correta, cortando para caber no modelo
    private func processImageForTexture(_ image: UIImage) -> UIImage {
        // O modelo PhotoPlane provavelmente é quadrado (1:1), então vamos cortar a imagem para quadrado
        let targetAspectRatio: CGFloat = 1.0 // Quadrado
        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height
        
        var cropRect: CGRect
        
        if imageAspectRatio > targetAspectRatio {
            // Imagem é mais larga - corta as laterais
            let newWidth = imageSize.height * targetAspectRatio
            let xOffset = (imageSize.width - newWidth) / 2
            cropRect = CGRect(x: xOffset, y: 0, width: newWidth, height: imageSize.height)
        } else {
            // Imagem é mais alta - corta o topo e fundo
            let newHeight = imageSize.width / targetAspectRatio
            let yOffset = (imageSize.height - newHeight) / 2
            cropRect = CGRect(x: 0, y: yOffset, width: imageSize.width, height: newHeight)
        }
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image // Retorna original se não conseguir cortar
        }
        
        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        
        // Aplica filtro de polaroid (overlay cinza)
        return applyPolaroidFilter(to: croppedImage) ?? croppedImage
    }
    
    /// Aplica filtro de polaroid antiga usando Core Image
    private func applyPolaroidFilter(to image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return image }
        
        guard let filteredImage = applyPolaroidEffect(to: ciImage) else { return image }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(filteredImage, from: filteredImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    /// Aplica efeito de polaroid antiga usando Core Image filters
    private func applyPolaroidEffect(to inputImage: CIImage) -> CIImage? {
        // 1. Aplicar efeito instantâneo (look vintage)
        let instantFilter = CIFilter.photoEffectInstant()
        instantFilter.inputImage = inputImage
        
        guard let instantOutput = instantFilter.outputImage else {
            return nil
        }
        
        // 2. Aplicar vinheta suave (cantos levemente escurecidos, mais autêntico)
        let vignetteFilter = CIFilter.vignette()
        vignetteFilter.inputImage = instantOutput
        vignetteFilter.intensity = 0.5  // Reduzido de 1.0 para menos escuro
        vignetteFilter.radius = 1.2     // Aumentado de 2.0 para vinheta mais suave
        
        return vignetteFilter.outputImage
    }
    
    private func findModelEntity(named name: String, in root: Entity) -> ModelEntity? {
        if let entity = root.findEntity(named: name) {
            if let model = entity as? ModelEntity { return model }
            return entity.children.first(where: { $0 is ModelEntity }) as? ModelEntity
        }
        return nil
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func handlePress(_ recognizer: UILongPressGestureRecognizer) {
        guard cameraVM.isCameraAuthorized else { return }
        
        guard let arView = arView else { return }
        let location = recognizer.location(in: arView)
        
        switch recognizer.state {
        case .began:
            if let hitEntity = arView.entity(at: location) {
                if let capture = captureButton, capture.represents(hitEntity) {
                    capture.press()
                }
            }
        case .ended, .cancelled:
            captureButton?.release()
            if let hitEntity = arView.entity(at: location) {
                if let flash = flashButton, flash.represents(hitEntity) {
                    flash.handleTap()
                }
            }
        default: break
        }
    }
    
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard cameraVM.isCameraAuthorized else { return }
        
        guard let arView = arView else { return }
        switch recognizer.state {
        case .began:
            let location = recognizer.location(in: arView)
            activeKnob = nil
            activeSlider = nil
            
            if let hitEntity = arView.entity(at: location) {
                if let expBtn = exposureButton, expBtn.represents(hitEntity) {
                    activeKnob = expBtn
                    activeKnob?.handlePan(recognizer, in: arView)
                    return
                }
                if let slider = timerSlider, slider.represents(hitEntity) {
                    activeSlider = slider
                    activeSlider?.handlePan(recognizer, in: arView)
                    return
                }
            }
        case .changed, .ended, .cancelled:
            if let knob = activeKnob { knob.handlePan(recognizer, in: arView) }
            else if let slider = activeSlider { slider.handlePan(recognizer, in: arView) }
            
            if recognizer.state != .changed {
                activeKnob = nil; activeSlider = nil;
            }
        default: break
        }
    }
}
