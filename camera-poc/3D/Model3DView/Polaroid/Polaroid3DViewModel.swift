//
//  Polaroid3DViewModel.swift
//  camera-poc
//
//  Created by Diogo Camargo on 04/12/25.
//

import SwiftUI
import RealityKit
import CoreImage

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
        
        // Aplica filtro de polaroid antiga
        guard let filteredImage = applyPolaroidFilter(to: flipped) else {
            return flipped
        }
        
        // Durante a revelação, aplica overlay escuro que vai diminuindo
        let currentIntensity = intensity * (1 - progress)
        
        if currentIntensity > 0 {
            return applyGrayOverlay(
                       to: filteredImage,
                       gray: UIColor(white: 0.02, alpha: 1),
                       intensity: currentIntensity
                   ) ?? filteredImage
        }
        
        return filteredImage
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
