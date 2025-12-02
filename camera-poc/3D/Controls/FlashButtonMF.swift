//
//  FlashButtonMF.swift
//  camera-poc
//
//  Created by Gabriel Barbosa on 24/11/25.
//

import RealityKit
import UIKit

class FlashButtonMF {
    
    private let entity: Entity
    private let baseOrientation: simd_quatf
    
    private let ledEntity: ModelEntity
    private let ledOnMaterial: SimpleMaterial
    private let ledOffMaterial: SimpleMaterial
    
    private(set) var isOn: Bool = false
    var onToggle: ((Bool) -> Void)?
    
    private let haptic = UIImpactFeedbackGenerator(style: .light)
    
    init?(rootEntity: Entity, entityName: String) {
        guard let found = rootEntity.findEntity(named: entityName) else {
            return nil
        }
        self.entity = found
        self.baseOrientation = found.orientation


        guard let buttonModel = found.children.compactMap({ $0 as? ModelEntity }).first else {
            return nil
        }

        let radius: Float = 0.002
        let mesh = MeshResource.generateSphere(radius: radius)

        ledOffMaterial = SimpleMaterial(color: .darkGray, isMetallic: false)
        ledOnMaterial  = SimpleMaterial(color: .red,      isMetallic: false)

        let led = ModelEntity(mesh: mesh, materials: [ledOffMaterial])

        // bounds do botão
        let bounds  = buttonModel.visualBounds(relativeTo: buttonModel)
        let center  = bounds.center
        let extents = bounds.extents

        // ponto de partida: centro do botão
        let offsetX: Float =  0.2   // frente/fundo
        let offsetY: Float =  -0.069   // cima/baixo
        let offsetZ: Float =  -0.28 // esquerda/direita

        led.position = SIMD3<Float>(
            center.x + offsetX,
            center.y + offsetY,
            center.z + extents.z / 2 + radius + offsetZ
        )

        // tamanho
        led.setScale(SIMD3<Float>(repeating: 3.5), relativeTo: buttonModel)

        buttonModel.addChild(led)
        self.ledEntity = led

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
        isOn.toggle()
        haptic.impactOccurred()
        
        let angleDegrees: Float = isOn ? 10.0 : -10.0
        let angleRadians = angleDegrees * .pi / 180
        let rotation = simd_quatf(angle: angleRadians,
                                  axis: SIMD3<Float>(0, 0, 1))
        
        var transform = entity.transform
        transform.rotation = rotation * baseOrientation
        
        // cinza quando off, vermelho quando on
        if var model = ledEntity.model {
            model.materials = [isOn ? ledOnMaterial : ledOffMaterial]
            ledEntity.model = model
        }
        
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
