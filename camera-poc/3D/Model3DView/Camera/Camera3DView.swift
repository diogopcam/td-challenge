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
            
            modelEntity.generateCollisionShapes(recursive: true)
            
            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(modelEntity)
            arView.scene.addAnchor(anchor)
            
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

