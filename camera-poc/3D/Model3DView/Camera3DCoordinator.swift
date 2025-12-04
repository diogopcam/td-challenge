//
//  Coordinator.swift
//  camera-poc
//
//  Created by Diogo Camargo on 27/11/25.
//

import SwiftUI
import Combine
import RealityKit

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
        // Busca o PhotoPlane
        guard let photoPlaneEntity = findModelEntity(named: "PhotoPlane", in: root) else { return }
        
        // Tenta carregar a imagem 'fundotela' dos Assets ou usa um ícone de sistema como fallback
        let placeholderImage = UIImage(named: "placeholderImage") ?? UIImage(systemName: "camera.fill")
        
        guard let cgImage = placeholderImage?.cgImage else { return }
        
        do {
            // Cria a textura e o material
            let texture = try TextureResource.generate(from: cgImage, options: .init(semantic: .color))
            var material = UnlitMaterial()
            material.color = .init(tint: .white, texture: .init(texture))
            
            // Aplica o material ao PhotoPlane
            photoPlaneEntity.model?.materials = [material]
        } catch {
            print("Erro ao aplicar placeholder: \(error)")
        }
    }
    
    func applyCameraImage(_ image: UIImage, to root: Entity) {
        guard let photoPlaneEntity = findModelEntity(named: "PhotoPlane", in: root) else { return }
        guard let cgImage = image.cgImage else { return }
        
        do {
            let texture = try TextureResource.generate(from: cgImage, options: .init(semantic: .color))
            var material = UnlitMaterial()
            material.color = .init(tint: .white, texture: .init(texture))
            photoPlaneEntity.model?.materials = [material]
        } catch { print(error) }
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
