import SwiftUI
import RealityKit
import AVFoundation // 1. Importar AVFoundation

// MARK: Struct responsible for "bringing 3D to code"
struct Modelo3DView: UIViewRepresentable {
    
    // MARK: Function responsible for being the bridge between user's interactions and camera functionalities
    func makeCoordinator() -> Coordinator {
        Coordinator(vm: CameraVM())
    }
    
    func dumpHierarchy(_ entity: Entity, level: Int = 0) {
        let indent = String(repeating: "  ", count: level)
        print("\(indent)- \(entity.name) [\(type(of: entity))]")
        for child in entity.children {
            dumpHierarchy(child, level: level + 1)
        }
    }

    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(
            frame: .zero,
            cameraMode: .nonAR,
            automaticallyConfigureSession: false
        )
        
        do {
            // MARK: 3D model being loaded
            let modelEntity: Entity = try Entity.load(named: "cameraModel")
            dumpHierarchy(modelEntity)
            
            modelEntity.scale = SIMD3<Float>(repeating: 1.0)
            modelEntity.position = SIMD3<Float>(0, -2.1, 2)
            
            let yaw = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 1, 0))
            let roll = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 0, 1))
            modelEntity.orientation = roll * yaw
            
            modelEntity.generateCollisionShapes(recursive: true)
            
            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(modelEntity)
            arView.scene.addAnchor(anchor)
            
            // MARK: This camera is the "user's view" in the virtual world, not the iPhone's camera
            let camera = PerspectiveCamera()
            let cameraTranslation = SIMD3<Float>(0, 0, 24)
            let cameraTransform = Transform(
                scale: .one,
                rotation: simd_quatf(angle: 0, axis: SIMD3<Float>(1, 0, 0)),
                translation: cameraTranslation
            )
            camera.transform = cameraTransform
            camera.look(at: SIMD3<Float>(0, 0, 0), from: cameraTranslation, relativeTo: nil)
            
            let cameraAnchor = AnchorEntity(world: .zero)
            cameraAnchor.addChild(camera)
            arView.scene.addAnchor(cameraAnchor)
            
            context.coordinator.rootModelEntity = modelEntity
            context.coordinator.arView = arView

            if let cameraBody = modelEntity.findEntity(named: "CameraBody") {
                context.coordinator.cameraBody = cameraBody
                print("CameraBody found in RealityKit")
            } else {
                print("CameraBody wasn't found in RealityKit")
            }
            
            let panGesture = UIPanGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handlePan(_:))
            )
            arView.addGestureRecognizer(panGesture)
            
            // MARK: ExposureButton being defined
            if let knob = modelEntity.findEntity(named: "Cylinder") {
                context.coordinator.knobEntity = knob
                context.coordinator.baseKnobOrientation = knob.orientation
                print("Exposure button found and stored as 'knobEntity': \(knob.name)")
            } else {
                print("Knob entity wasn't found in RealityKit.")
            }

        } catch {
            print("Error loading .usdz model: \(error)")
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}
