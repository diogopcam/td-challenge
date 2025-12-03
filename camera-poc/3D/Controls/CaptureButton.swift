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
    private var isEnabled = true
    
    var onCapture: (() -> Void)?
    
    private var isPressed = false
    
    init?(rootEntity: Entity, entityName: String) {
        guard let found = rootEntity.findEntity(named: entityName) else {
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
        if !ButtonManager.shared.isEnabled {
            SoundManager.shared.playSound(named: "disableButton1")
            return
        }
        
        guard !isPressed else { return }
        isPressed = true
         
        HapticManager.shared.shutterPress()
        SoundManager.shared.playSound(named: "shutter")
        
        var pressed = baseTransform
        //pressed.translation.y -= 0.003
        pressed.scale -= 0.03
        
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
        
        HapticManager.shared.shutterRelease()
        
        entity.move(
            to: baseTransform,
            relativeTo: entity.parent,
            duration: 0.12,
            timingFunction: .easeOut
        )
        
        onCapture?()
    }
    
    func enable() {
        isEnabled = true
    }
    
    func disable() {
        isEnabled = false
    }

}
