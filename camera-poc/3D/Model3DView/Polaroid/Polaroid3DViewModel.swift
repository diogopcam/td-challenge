//
//  Polaroid3DViewModel.swift
//  camera-poc
//
//  Created by Diogo Camargo on 04/12/25.
//

import SwiftUI
import RealityKit

@Observable
class Polaroid3DViewModel {
    var image: UIImage
    var progress: CGFloat = 0.0
    var intensity: CGFloat = 0.9
    var modelEntity: Entity?
    var timer: Timer?
    
    init(image: UIImage) {
        self.image = image
    }
    
    func applyTexture() {
        guard let model = modelEntity,
                     let imageNode = findImagePolaroidEntity(in: model) else { return }
        
        let processed = processedImage()
        
        guard let cgImage = processed.cgImage else { return }
        
        do {
            let texture = try TextureResource(
                image: cgImage,
                options: .init(semantic: .color)
            )
            
            var material = SimpleMaterial()
            material.color = .init(tint: .white, texture: .init(texture))
            imageNode.model?.materials = [material]
            
        } catch {
            print("Erro criando textura: \(error)")
        }
    }
    
    private func processedImage() -> UIImage {
        let normalized = fixImageOrientation(image)
        
        // Flip horizontal
        let flipped = flipImageHorizontally(normalized) ?? normalized
        
        let currentIntensity = intensity * (1 - progress)
        
        return applyGrayOverlay(
                   to: flipped,
                   gray: UIColor(white: 0.02, alpha: 1),
                   intensity: currentIntensity
               ) ?? flipped
    }

    func startRevealAnimation() {
        timer?.invalidate()
        
        let steps = 60
        let interval = 15.0 / 60.0
        var current = 0
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] t in
                guard let self = self else { return }
                
                current += 1
                self.progress = CGFloat(current) / CGFloat(steps)
                
                self.applyTexture()  // Isso deve estar no main thread
                
                if current >= steps {
                    t.invalidate()
                    self.timer = nil
                }
            }
        }
    }
    
    func findImagePolaroidEntity(in entity: Entity) -> ModelEntity? {
        if let modelEntity = entity as? ModelEntity,
           entity.name.lowercased().contains("imagepolaroid") {
            return modelEntity
        }
        
        for child in entity.children {
            if let found = findImagePolaroidEntity(in: child) {
                return found
            }
        }
        
        return nil
    }
    
    func fixImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let fixed = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return fixed
    }
    
    func flipImageHorizontally(_ img: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale)
        let ctx = UIGraphicsGetCurrentContext()!
        
        ctx.translateBy(x: img.size.width, y: 0)
        ctx.scaleBy(x: -1, y: 1)
        
        img.draw(in: CGRect(origin: .zero, size: img.size))
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    func applyGrayOverlay(to image: UIImage,
                          gray: UIColor,
                          intensity: CGFloat) -> UIImage? {
        
        let rect = CGRect(origin: .zero, size: image.size)
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        
        image.draw(in: rect)
        
        ctx.setFillColor(gray.withAlphaComponent(intensity).cgColor)
        ctx.fill(rect)
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
