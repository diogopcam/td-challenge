//
//  Model3DViewMF.swift
//  camera-poc
//
//  Created by Gabriel Barbosa on 21/11/25.
//

import SwiftUI
import RealityKit

struct Model3DViewMF: UIViewRepresentable {
    @EnvironmentObject var cameraVM: CameraVM
    
    // MARK: - Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(cameraVM: cameraVM)
    }
    
    // MARK: - Make UIView
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(
            frame: .zero,
            cameraMode: .nonAR,
            automaticallyConfigureSession: false
        )
        
        arView.environment.background = .color(.black)
        
        do {
            let modelEntity = try Entity.load(named: "cameraModel")
            
            let scaleFix: Float = 3.0
            modelEntity.scale = SIMD3<Float>(repeating: scaleFix)
            
            let rotationX = simd_quatf(angle: .pi, axis: SIMD3<Float>(1, 0, 0))
            let rotationY = simd_quatf(angle: .pi/2, axis: SIMD3<Float>(0, 1, 0))
            let rotationZ = simd_quatf(angle: .pi + .pi/2, axis: SIMD3<Float>(0, 0, 1))
            
            modelEntity.orientation = rotationX * rotationZ * rotationY
            
            modelEntity.generateCollisionShapes(recursive: true)
            
            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(modelEntity)
            arView.scene.addAnchor(anchor)
            
            let bounds = modelEntity.visualBounds(relativeTo: anchor)
            let center = bounds.center
            let distance: Float = -50.0
            
            modelEntity.position = SIMD3<Float>(-center.x, -center.y, distance)
            
            context.coordinator.arView = arView
            context.coordinator.rootModelEntity = modelEntity
            context.coordinator.setupControls(root: modelEntity)

            let panGesture = UIPanGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handlePan(_:))
            )
            arView.addGestureRecognizer(panGesture)
            
            let pressGesture = UILongPressGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handlePress(_:))
            )
            pressGesture.minimumPressDuration = 0
            pressGesture.delegate = context.coordinator
            arView.addGestureRecognizer(pressGesture)
            
            context.coordinator.startCameraService()
            
        } catch {
            print("Erro ao carregar modelo .usdz: \(error)")
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    // MARK: - Coordinator Class
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var arView: ARView?
        var rootModelEntity: Entity?
        
        var onDismissAction: (() -> Void)?
        
        let cameraService = CameraServiceMF()
        let cameraVM: CameraVM
        var exposureButton: ExposureButtonMF?
        var timerSlider: TimerSliderMF?
        var captureButton: CaptureButtonMF?
        var flashButton: FlashButtonMF?
        
        private var activeKnob: ExposureButtonMF?
        private var activeSlider: TimerSliderMF?
        
        init(cameraVM: CameraVM) {
            self.cameraVM = cameraVM
        }
   
        func setupControls(root: Entity) {
            if let expBtn = ExposureButtonMF(rootEntity: root, entityName: "Cylinder") {
                self.exposureButton = expBtn
                expBtn.onValueChange = { [weak self] newValue in
                    self?.cameraVM.setExposureBias(to: -newValue)
                }
            }
            if let timer = TimerSliderMF(rootEntity: root) {
                self.timerSlider = timer
                timer.onValueChange = { val in
                    print("Timer: \(val)s")
                }
            }
            if let flash = FlashButtonMF(rootEntity: root, entityName: "FlashSelector") {
                self.flashButton = flash
                flash.onToggle = { isOn in
                    print("Flash: \(isOn)")
                }
            }
            if let capture = CaptureButtonMF(rootEntity: root, entityName: "CaptureButton") {
                self.captureButton = capture
                capture.onCapture = {
                    print("📸 Click")
                    self.cameraVM.captureNow()
//                    self.cameraVM.capturedImage = image
                    print("Foto capturada: \(self.cameraVM.capturedImage ?? UIImage())")
//                    self.cameraVM.capturedImage = image
                    self.cameraVM.showCapturedPhoto = true
                }
            }
        }
        
        func startCameraService() {
            cameraService.onFrameCaptured = { [weak self] image in
                guard let self = self, let root = self.rootModelEntity else { return }
                self.applyCameraImage(image, to: root)
            }
            cameraService.start()
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
}

