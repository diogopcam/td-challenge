//
//  CameraPolaroidVM.swift
//  camera-poc
//
//  Created by Fernanda Farias Uberti on 02/12/25.
//

import Foundation
import RealityKit
import SwiftUI
import CoreImage

@Observable
class CameraPolaroidViewModel {

    let loader = RootEntityLoader()
    private var hasPlayedAnimation = false
    
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
    
    /// Aplica filtro de polaroid antiga usando Core Image
    private func applyPolaroidFilter(to image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return image }
        
        guard let filteredImage = applyPolaroidEffect(to: ciImage) else { return image }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(filteredImage, from: filteredImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    /// Aplica efeito de polaroid antiga usando Core Image filters
    private func applyPolaroidEffect(to inputImage: CIImage) -> CIImage? {
        // 1. Aplicar efeito instantâneo (look vintage)
        let instantFilter = CIFilter.photoEffectInstant()
        instantFilter.inputImage = inputImage
        
        guard let instantOutput = instantFilter.outputImage else {
            return nil
        }
        
        // 2. Aplicar vinheta suave (cantos levemente escurecidos, mais autêntico)
        let vignetteFilter = CIFilter.vignette()
        vignetteFilter.inputImage = instantOutput
        vignetteFilter.intensity = 0.5  // Reduzido de 1.0 para menos escuro
        vignetteFilter.radius = 1.2     // Aumentado de 2.0 para vinheta mais suave
        
        return vignetteFilter.outputImage
    }

    
    func updatePolaroid(with imageData: Data, in anchor: Entity) async {
        guard let uiImage = UIImage(data: imageData),
              let _ = uiImage.cgImage else {
            print("Erro convertendo Data -> UIImage")
            return
        }

        guard let filteredImage = applyPolaroidFilter(to: uiImage),
              let tintedCG = filteredImage.cgImage else {
            print("Erro aplicando filtro de polaroid")
            return
        }
        
        let overlayColor = UIColor.gray
        let overlayIntensity: CGFloat = 1
        
        guard let finalImage = applyGrayOverlay(
            to: filteredImage,
            gray: overlayColor,
            intensity: overlayIntensity
        ), let finalCG = finalImage.cgImage else {
            print("Erro aplicando overlay cinza")
            return
        }
        

        guard let target = findEntity(named: "imagePolaroid_001", in: anchor) as? ModelEntity else {
            print("Polaroid não encontrada")
            return
        }

        do {
            let texture = try await TextureResource(
                image: finalCG,
                options: .init(semantic: .color)
            )

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

    func playAnimation(in anchor: AnchorEntity?, completion: @escaping () -> Void) {
        // Previne múltiplas execuções da animação
        guard !hasPlayedAnimation else { return }
        guard let anchor = anchor else { return }

        hasPlayedAnimation = true

        let entity: Entity
        let anim: AnimationResource

        if let a = anchor.availableAnimations.first {
            entity = anchor
            anim = a
        } else if let e = findEntityWithAnimation(in: anchor),
                  let a = e.availableAnimations.first {
            entity = e
            anim = a
        } else {
            hasPlayedAnimation = false // Reset se não encontrou animação
            return
        }

        // Inicia haptic e som de impressão
        HapticManager.shared.startPrintingHaptic()
        SoundManager.shared.playContinuousSound(named: "printing", volume: 0.4)

        entity.playAnimation(anim.repeat(count: 1), transitionDuration: 0.3)

        let duration = anim.definition.duration
        let soundDuration = duration * 0.5 // Som toca por 70% da duração da animação
        
        // Para o som antes do término da animação
        DispatchQueue.main.asyncAfter(deadline: .now() + soundDuration) {
            SoundManager.shared.stopContinuousSound()
        }
        
        // Para o haptic e chama completion quando a animação terminar
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            HapticManager.shared.stopPrintingHaptic()
            completion()
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
