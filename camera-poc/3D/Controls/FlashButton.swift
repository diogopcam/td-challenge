//
//  FlashButton.swift
//  camera-poc
//
//  Created by Gabriel Barbosa on 24/11/25.
//

import RealityKit
import UIKit

class FlashButton {
    
    private let entity: Entity
    private let baseOrientation: simd_quatf
    
    private(set) var isOn: Bool = false
    var onToggle: ((Bool) -> Void)?
    
    private let haptic = UIImpactFeedbackGenerator(style: .light)
    
    init?(rootEntity: Entity, entityName: String) {
        guard let found = rootEntity.findEntity(named: entityName) else {
            return nil
        }
        self.entity = found
        self.baseOrientation = found.orientation
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
    
    func handleTap() {
        
        if !ButtonManager.shared.isEnabled {
             SoundManager.shared.playSound(named: "offFlash")
             return
        }
        
        isOn.toggle()
        haptic.impactOccurred()
        
        if isOn {
            SoundManager.shared.playSound(named: "onFlash")
        } else {
            SoundManager.shared.playSound(named: "offFlash")
        }
        
        let angleDegrees: Float = isOn ? 10.0 : -10.0
        let angleRadians = angleDegrees * .pi / 180
        let rotation = simd_quatf(angle: angleRadians,
                                  axis: SIMD3<Float>(0, 0, 1))
        
        var transform = entity.transform
        transform.rotation = rotation * baseOrientation
        
        HapticManager.shared.flashFeedback()
        
        entity.move(
            to: transform,
            relativeTo: entity.parent,
            duration: 0.12,
            timingFunction: .easeInOut
        )
        
        onToggle?(isOn)
    }
}
