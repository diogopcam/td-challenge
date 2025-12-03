//
//  CameraPolaroidVM.swift
//  camera-poc
//
//  Created by Fernanda Farias Uberti on 02/12/25.
//

import Foundation
import Foundation
import RealityKit
import SwiftUI

@Observable
class CameraPolaroidViewModel {

    let loader = RootEntityLoader()
    func applyGrayOverlay(to image: UIImage,
                          gray: UIColor,
                          intensity: CGFloat) -> UIImage? {

        let rect = CGRect(origin: .zero, size: image.size)
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        image.draw(in: rect)

        context.setFillColor(gray.withAlphaComponent(intensity).cgColor)
        context.fill(rect)

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }

    
    func updatePolaroid(with imageData: Data, in anchor: Entity) async {
        guard let uiImage = UIImage(data: imageData),
              let _ = uiImage.cgImage else {
            print("Erro convertendo Data -> UIImage")
            return
        }

        let overlayGray = UIColor(white: 0.02, alpha: 1.0)
        let intensity: CGFloat = 0.80

        guard let tinted = applyGrayOverlay(to: uiImage,
                                            gray: overlayGray,
                                            intensity: intensity),
              let tintedCG = tinted.cgImage else {
            print("Erro aplicando overlay cinza")
            return
        }

        guard let target = findEntity(named: "imagePolaroid_001", in: anchor) as? ModelEntity else {
            print("Polaroid não encontrada")
            return
        }

        do {
            let texture = try await TextureResource(image: tintedCG, options: .init(semantic: .color))
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(texture: .init(texture))

            if var model = target.model {
                model.materials = [material]
                target.model = model
            }

            print("Textura atualizada com sucesso!")
        } catch {
            print("Erro gerando TextureResource: \(error)")
        }
    }

    func findEntity(named name: String, in root: Entity) -> Entity? {
        if root.name == name { return root }
        for child in root.children {
            if let found = findEntity(named: name, in: child) {
                return found
            }
        }
        return nil
    }

    func playAnimation(in anchor: AnchorEntity?) {
        guard let anchor = anchor else { return }

        if let anim = anchor.availableAnimations.first {
            anchor.playAnimation(anim.repeat(count: 1), transitionDuration: 0.3)
            return
        }

        if let entityWithAnim = findEntityWithAnimation(in: anchor),
           let anim = entityWithAnim.availableAnimations.first {
            entityWithAnim.playAnimation(anim.repeat(count: 1), transitionDuration: 0.2)
        }
    }

    func findEntityWithAnimation(in root: Entity) -> Entity? {
        if !root.availableAnimations.isEmpty {
            return root
        }

        for child in root.children {
            if let found = findEntityWithAnimation(in: child) {
                return found
            }
        }
        return nil
    }

    func printAllEntities(_ entity: Entity, indent: String = "") {
        print("\(indent)- \(entity.name) | \(type(of: entity))")

        for child in entity.children {
            printAllEntities(child, indent: indent + "    ")
        }
    }
}
