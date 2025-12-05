//
//  Polaroid3DView.swift
//  camera-poc
//
//  Created by Diogo Camargo on 02/12/25.
//

import SwiftUI
import RealityKit
import CoreImage

struct Polaroid3DView: View {
    let image: UIImage
    
    var body: some View {
        RealityView { content in
            
            guard let modelEntity = try? Entity.load(named: "polaroidNew") else {
                print("Error creating 3D model")
                return
            }
            
            applyImageWithReveal(entity: modelEntity)

            modelEntity.generateCollisionShapes(recursive: true)

            let anchor = AnchorEntity(.camera)
            anchor.addChild(modelEntity)
            content.add(anchor)
        }
        .background(.clear)
    }
}

extension Polaroid3DView {
    
    // MARK: - Encontra o node correto da foto no modelo
    func findImagePolaroidEntity(in entity: Entity) -> ModelEntity? {
        if let me = entity as? ModelEntity,
           entity.name.lowercased().contains("imagepolaroid") {
            return me
        }
        
        for child in entity.children {
            if let found = findImagePolaroidEntity(in: child) {
                return found
            }
        }
        return nil
    }
    
    
    // MARK: - Revelação
    func applyImageWithReveal(entity: Entity) {
        guard let imageNode = findImagePolaroidEntity(in: entity) else { return }
        
        var intensity: CGFloat = 0.9
        let steps: CGFloat = 60
        let interval: TimeInterval = 15 / 60
        
        func updateTexture() {
            let processed = processedImage(intensity: intensity)
            guard let cg = processed.cgImage else { return }
            
            do {
                let texture = try TextureResource(
                    image: cg,
                    options: .init(semantic: .color)
                )
                
                var material = SimpleMaterial()
                material.color = .init(tint: .white, texture: .init(texture))
                imageNode.model?.materials = [material]
                
            } catch {
                print("Error creating textures: \(error)")
            }
        }
        
        updateTexture()
        
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            intensity -= 0.9 / steps
            
            if intensity <= 0 {
                intensity = 0
                updateTexture()
                t.invalidate()
                return
            }
            
            updateTexture()
        }
    }
    
    
    // MARK: - Pipeline de processamento completo
    func processedImage(intensity: CGFloat) -> UIImage {
        let normalized = fixImageOrientation(image)
        let flipped = flipImageHorizontally(normalized) ?? normalized
        
        // Novo filtro Polaroid
        let filtered = applyPolaroidFilter(to: flipped) ?? flipped
        
        // Revelação (overlay escuro que some aos poucos)
        return applyGrayOverlay(
            to: filtered,
            gray: UIColor(white: 0.02, alpha: 1),
            intensity: intensity
        ) ?? filtered
    }
    
    
    // MARK: - Filtro Polaroid antigo
    func applyPolaroidFilter(to image: UIImage) -> UIImage? {
        guard let ciInput = CIImage(image: image) else { return nil }
        
        guard let ciOutput = applyPolaroidEffect(to: ciInput) else { return nil }
        
        let context = CIContext()
        guard let cg = context.createCGImage(ciOutput, from: ciOutput.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    }
    
    func applyPolaroidEffect(to inputImage: CIImage) -> CIImage? {
        let instant = CIFilter.photoEffectInstant()
        instant.inputImage = inputImage
        
        guard let instantOutput = instant.outputImage else { return nil }
        
        let vignette = CIFilter.vignette()
        vignette.inputImage = instantOutput
        vignette.intensity = 0.5
        vignette.radius = 1.2
        
        return vignette.outputImage
    }
    
    
    // MARK: - Utilidades
    func fixImageOrientation(_ img: UIImage) -> UIImage {
        if img.imageOrientation == .up { return img }
        
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale)
        img.draw(in: CGRect(origin: .zero, size: img.size))
        let result = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return result
    }
    
    func flipImageHorizontally(_ img: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.translateBy(x: img.size.width, y: 0)
        ctx.scaleBy(x: -1, y: 1)
        img.draw(in: CGRect(origin: .zero, size: img.size))
        let out = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return out
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
        
        let out = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return out
    }
}
