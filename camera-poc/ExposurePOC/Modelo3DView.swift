import SwiftUI
import RealityKit
import AVFoundation // 1. Importar AVFoundation

struct Modelo3DView: UIViewRepresentable {
    
    func dumpHierarchy(_ entity: Entity, level: Int = 0) {
        let indent = String(repeating: "  ", count: level)
        print("\(indent)- \(entity.name) [\(type(of: entity))]")
        for child in entity.children {
            dumpHierarchy(child, level: level + 1)
        }
    }
    
    // 2. Implementar o makeCoordinator
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(
            frame: .zero,
            cameraMode: .nonAR,
            automaticallyConfigureSession: false
        )
        
        do {
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
            
            // 🔹 CÂMERA PERSONALIZADA (Virtual)
            let camera = PerspectiveCamera()
            let cameraTranslation = SIMD3<Float>(0, 0, 5)
            let cameraTransform = Transform(
                scale: .one,
                rotation: simd_quatf(angle: -.pi/12, axis: SIMD3<Float>(0, 0, 0)),
                translation: cameraTranslation
            )
            camera.transform = cameraTransform
            camera.look(at: .zero, from: cameraTranslation, relativeTo: nil)
            
            let cameraAnchor = AnchorEntity(world: .zero)
            cameraAnchor.addChild(camera)
            arView.scene.addAnchor(cameraAnchor)
            
            context.coordinator.rootModelEntity = modelEntity
            context.coordinator.arView = arView

            // 👇 Guardar referência do CameraBody (pra saber se o toque foi na câmera)
            if let cameraBody = modelEntity.findEntity(named: "CameraBody") {
                context.coordinator.cameraBody = cameraBody
                print("Achei entidade CameraBody em RealityKit")
            } else {
                print("NÃO achei entidade 'CameraBody' em RealityKit")
            }
            
            let panGesture = UIPanGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handlePan(_:))
            )
            arView.addGestureRecognizer(panGesture)

            context.coordinator.setupCameraFeed()
            
            // ExposureButton
            if let knob = modelEntity.findEntity(named: "Cylinder") {
                context.coordinator.knobEntity = knob
                context.coordinator.baseKnobOrientation = knob.orientation
                print("Achei knob: \(knob.name)")
            } else {
                print("⚠️ Não achei entidade 'Knob' no modelo. Ajuste o nome no código.")
            }

        } catch {
            print("Erro ao carregar modelo .usdz: \(error)")
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}
