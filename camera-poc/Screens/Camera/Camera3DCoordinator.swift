//
//  Coordinator.swift
//  camera-poc
//
//  Created by Diogo Camargo on 24/11/25.
//

import SwiftUI
import RealityKit
import AVFoundation
import Combine

class Camera3DCoordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    var vm: any CameraVMProtocol
    
    private var cancellables = Set<AnyCancellable>()

    // MAR: Root of the 3D model
    var rootModelEntity: Entity?

    var cameraBody: Entity?
    
//    var exposureButton: ExposureButtonMF?
    var timerSlider: TimerSliderMF?
    var captureButton: Entity?
    var flashButton: FlashButtonMF?
    
    weak var arView: ARView?
    private let context = CIContext()
    
    // MARK: Exposure's knob
    var knobEntity: Entity?
    var baseKnobOrientation: simd_quatf?
    var dragStartAngle: Float = 0.0
    var lastAngle: Float = 0.0
    var knobValue: Float = 0.0
    var knobCenterScreen: CGPoint = .zero
    var currentExposure: Float = 0.0

    private var isDraggingKnob = false
    private var dragStartX: CGFloat = 0
    private var exposureAtDragStart: Float = 0

    init(vm: any CameraVMProtocol) {
        self.vm = vm
        super.init()
        
        vm.currentFramePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] frame in
                if let frame = frame, let root = self?.rootModelEntity {
                    self?.applyCameraImage(frame, to: root)
                } else {
                    if frame == nil { print("Frame is nil") }
                    if self?.rootModelEntity == nil { print("rootModelEntity is nil") }
                }
            }
            .store(in: &cancellables)
    }
    
    private func knobCenterInScreen() -> CGPoint? {
        guard let arView = arView,
              let knob = knobEntity else { return nil }
        
        let worldPosition = knob.position(relativeTo: nil)
        
        if let screenPoint = arView.project(worldPosition) {
            return screenPoint
        } else {
            return nil
        }
    }

    // MARK: Function responsible for loading the camera video session and applying
    func applyCameraImage(_ image: UIImage, to root: Entity) {
        guard let photoPlaneEntity = root.findEntity(named: "PhotoPlane") else {
            print("There is no entity called 'PhotoPlane'.")
            return
        }
        
        let targetModel: ModelEntity
        
        if let model = photoPlaneEntity as? ModelEntity {
            targetModel = model
        } else if let childModel = photoPlaneEntity.children.first(where: { $0 is ModelEntity }) as? ModelEntity {
            targetModel = childModel
        } else {
            print("Error in ApplyCameraImage")
            return
        }
        
        guard let cgImage = image.cgImage else { return }
        
        let texture: TextureResource
        
        do {
            texture = try TextureResource.generate(
                from: cgImage,
                options: .init(semantic: .color)
            )
        } catch {
            print("Error in ApplyCameraImage: \(error)")
            return
        }
        
        var material = UnlitMaterial()
        material.color = .init(
            tint: .white,
            texture: .init(texture)
        )
        
        targetModel.model?.materials = [material]
    }

    private func isPartOfCameraBody(_ entity: Entity) -> Bool {
        var current: Entity? = entity
        while let e = current {
            if e.name == "CameraBody" { return true }
            current = e.parent
        }
        return false
    }
    
    // MARK: Function responsible for dealing with user's interaction with the exposure's knob
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let arView = arView else { return }
        let location = recognizer.location(in: arView)

        switch recognizer.state {
        case .began:
            if let entity = arView.entity(at: location),
               isPartOfKnob(entity) {
                isDraggingKnob = true
                print("Knob is being manipulated")

                if let center = knobCenterInScreen() {
                    knobCenterScreen = center
                } else {
                    knobCenterScreen = CGPoint(x: arView.bounds.midX,
                                               y: arView.bounds.midY)
                }

                let dx = Float(location.x - knobCenterScreen.x)
                let dy = Float(location.y - knobCenterScreen.y)
                let startAngle = atan2(dy, dx)

                dragStartAngle = startAngle
                lastAngle = startAngle

                exposureAtDragStart = knobValue
            } else {
                isDraggingKnob = false
            }

        case .changed:
            guard isDraggingKnob else { return }

            let dx = Float(location.x - knobCenterScreen.x)
            let dy = Float(location.y - knobCenterScreen.y)

            let distance = hypot(dx, dy)
            if distance < 20 {
                return
            }

            let currentAngle = atan2(dy, dx)

            var deltaAngle = currentAngle - lastAngle

            let twoPi = Float.pi * 2
            if deltaAngle > Float.pi {
                deltaAngle -= twoPi
            } else if deltaAngle < -Float.pi {
                deltaAngle += twoPi
            }

            lastAngle = currentAngle

            let maxAngle = Float(270.0 * .pi / 180.0)

            let deltaStops = -(deltaAngle / maxAngle) * 4.0

            let unclampedKnob = knobValue + deltaStops
            let newKnobValue = max(-2.0, min(2.0, unclampedKnob))

            applyExposure(newKnobValue)


        case .ended, .cancelled, .failed:
            isDraggingKnob = false

            var snappedLogical = (currentExposure * 10).rounded() / 10

            snappedLogical = max(-2.0, min(2.0, snappedLogical))

            let snappedKnob = -snappedLogical

            applyExposure(snappedKnob)

            print("Exposition fixated in: \(currentExposure)")

        default:
            break
        }
    }
    
    // MARK: Function responsible for dealing with knob's rotation and exposure application
    func applyExposure(_ exposure: Float) {
        let clampedKnob = max(-2.0, min(2.0, exposure))
        knobValue = clampedKnob
        
        let logicalExposure = -clampedKnob
        currentExposure = logicalExposure

        if let knob = knobEntity {
            let degreesPerStop: Float = 67.5
            let angleDegrees = clampedKnob * degreesPerStop
            let angleRadians = angleDegrees * .pi / 180

            let rotationQuat = simd_quatf(
                angle: angleRadians,
                axis: SIMD3<Float>(1, 0, 0)
            )

            if let base = baseKnobOrientation {
                knob.orientation = rotationQuat * base
            } else {
                knob.orientation = rotationQuat
            }
        }

        vm.exposure = logicalExposure
    }
    
    private func isPartOfKnob(_ entity: Entity) -> Bool {
        var current: Entity? = entity
        while let e = current {
            if e.name == "Cylinder" {
                return true
            }
            current = e.parent
        }
        return false
    }
}
