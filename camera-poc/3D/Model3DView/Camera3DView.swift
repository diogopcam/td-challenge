//
//  Model3DView.swift
//  camera-poc
//
//  Created by Gabriel Barbosa on 21/11/25.
//

import SwiftUI
import RealityKit
import Combine

struct Camera3DView: UIViewRepresentable {
    @EnvironmentObject var cameraVM: CameraVM

    func makeCoordinator() -> Camera3DCoordinator {
        Camera3DCoordinator(cameraVM: cameraVM)
    }
    
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
            
        } catch {
            print("Erro ao carregar modelo .usdz: \(error)")
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

