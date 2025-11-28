//
//  CaptureButton.swift
//  camera-poc
//
//  Created by Gabriel Barbosa on 21/11/25.
//

import RealityKit
import UIKit

class CaptureButton {
    
    private let entity: Entity
    private let baseTransform: Transform
    
    var onCapture: (() -> Void)?
    
    private var isPressed = false
    
    init?(rootEntity: Entity, entityName: String) {
        guard let found = rootEntity.findEntity(named: entityName) else {
            print("CaptureButton: entidade '\(entityName)' não encontrada.")
            return nil
        }
        self.entity = found
        self.baseTransform = found.transform
    }
    
    func represents(_ targetEntity: Entity?) -> Bool {
        guard let target = targetEntity else { return false }
        var current: Entity? = target
        
        while let e = current {
            if e == entity { return true }
            current = e.parent
        }
        return false
    }
    
    func press() {
        guard !isPressed else { return }
        isPressed = true
         
        HapticManager.shared.shutterPress()
        
        var pressed = baseTransform
        pressed.translation.x -= 0.12
        
        entity.move(
            to: pressed,
            relativeTo: entity.parent,
            duration: 0.06,
            timingFunction: .easeIn
        )
    }
    
    func release() {
        guard isPressed else { return }
        isPressed = false
        
        HapticManager.shared.shutterPress()
        
        entity.move(
            to: baseTransform,
            relativeTo: entity.parent,
            duration: 0.12,
            timingFunction: .easeOut
        )
        
        onCapture?()
    }
}
