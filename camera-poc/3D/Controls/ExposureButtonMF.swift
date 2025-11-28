//
//  ExposureButtonMF.swift
//  camera-poc
//
//  Created by Gabriel Barbosa on 21/11/25.
//

import RealityKit
import UIKit

class ExposureButtonMF {
    
    private let entity: Entity
    private let baseOrientation: simd_quatf
    
    private(set) var value: Float = 0.0
    private var lastAngle: Float = 0.0
    private var centerScreenPosition: CGPoint = .zero
    
    /// Para detectar quando cruzou um "stop" de 0.1
    private var lastStepValue: Float = 0.0
    
    var onValueChange: ((Float) -> Void)?
    
    init?(rootEntity: Entity, entityName: String) {
        guard let foundEntity = rootEntity.findEntity(named: entityName) else {
            print("ExposureButton: Entidade '\(entityName)' não encontrada.")
            return nil
        }
        self.entity = foundEntity
        self.baseOrientation = foundEntity.orientation
    }
    
    func represents(_ targetEntity: Entity?) -> Bool {
        guard let target = targetEntity else { return false }
        
        var current: Entity? = target
        while let e = current {
            if e == self.entity { return true }
            current = e.parent
        }
        return false
    }
    
    // MARK: - Gesture Handling
    func handlePan(_ recognizer: UIPanGestureRecognizer, in arView: ARView) {
        let location = recognizer.location(in: arView)
        
        switch recognizer.state {
            
        case .began:
            HapticManager.shared.selection()
            
            lastStepValue = value
            
            if let projected = arView.project(entity.position(relativeTo: nil)) {
                centerScreenPosition = projected
            } else {
                centerScreenPosition = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
            }
            
            let dx = Float(location.x - centerScreenPosition.x)
            let dy = Float(location.y - centerScreenPosition.y)
            lastAngle = atan2(dy, dx)
            
            
        case .changed:
            let dx = Float(location.x - centerScreenPosition.x)
            let dy = Float(location.y - centerScreenPosition.y)
            
            if hypot(dx, dy) < 20 { return }
            
            let currentAngle = atan2(dy, dx)
            var deltaAngle = currentAngle - lastAngle
            
            if deltaAngle > .pi { deltaAngle -= .pi * 2 }
            else if deltaAngle < -.pi { deltaAngle += .pi * 2 }
            
            lastAngle = currentAngle
            
            let maxAngle = Float(270.0 * .pi / 180.0)
            let deltaStops = -(deltaAngle / maxAngle) * 4.0
            
            value = max(-2.0, min(2.0, value + deltaStops))
            
            let stepped = (value * 10).rounded() / 10
            if stepped != lastStepValue {
                HapticManager.shared.dialFeedback()
                lastStepValue = stepped
            }
            
            updateVisualRotation()
            onValueChange?(value)
            
            
        case .ended, .cancelled:
            let snapped = (value * 10).rounded() / 10
            value = max(-2.0, min(2.0, snapped))
            updateVisualRotation()
            onValueChange?(value)
            
            HapticManager.shared.impact(.light)
            
            
        default: break
        }
    }
    
    
    // MARK: - Visual Update
    private func updateVisualRotation() {
        let degreesPerStop: Float = 67.5
        let angleRadians = (value * degreesPerStop) * .pi / 180
        let rotation = simd_quatf(angle: angleRadians, axis: SIMD3<Float>(1, 0, 0))
        
        entity.orientation = rotation * baseOrientation
    }
}
