//
//  Polaroid3DView.swift
//  camera-poc
//
//  Created by Diogo Camargo on 02/12/25.
//

import SwiftUI
import RealityKit
import Combine

struct Polaroid3DView: View {
    var image: UIImage?

    var body: some View {
        RealityView { content in
            if let modelEntity = try? Entity.load(named: "polaroidNew") {
                modelEntity.generateCollisionShapes(recursive: true)
                
                if let imagePart = findImagePolaroidEntity(in: modelEntity) {
                    print("Encontrado imagePolaroid: \(imagePart.name)")
                    print("Tem material? \(imagePart.model?.materials.count ?? 0)")
                } else {
                    print("imagePolaroid não encontrado")
                }
            
                if let img = image {
                    updatePolaroidImage(img, in: modelEntity)
                }

                let anchor = AnchorEntity(.camera)
                anchor.addChild(modelEntity)
                content.add(anchor)
            }
        }
        .background(.clear)
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
    
        func updatePolaroidImage(_ image: UIImage, in modelEntity: Entity) {
            guard let imagePolaroid = findImagePolaroidEntity(in: modelEntity) else {
                return
            }
    
            let normalizedImage = fixImageOrientation(image)
            var finalImage: UIImage
            finalImage = flipImageHorizontally(normalizedImage) ?? normalizedImage
    
            guard let cgImage = finalImage.cgImage else {
                return
            }
    
            do {
                let texture = try TextureResource.generate(
                    from: cgImage,
                    options: .init(semantic: .color)
                )
    
                var material = SimpleMaterial()
    
                material.color = .init(tint: .white, texture: .init(texture))
                imagePolaroid.model?.materials = [material]
    
            } catch {
                print("Error creating texture", error)
            }
        }
    
        func fixImageOrientation(_ image: UIImage) -> UIImage {
            if image.imageOrientation == .up {
                return image
            }
    
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            let fixedImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
    
            return fixedImage
        }
    
        func flipImageHorizontally(_ originalImage: UIImage) -> UIImage? {
            UIGraphicsBeginImageContextWithOptions(originalImage.size, false, originalImage.scale)
    
            let context = UIGraphicsGetCurrentContext()!
    
            context.translateBy(x: originalImage.size.width, y: 0)
            context.scaleBy(x: -1.0, y: 1.0)
    
            originalImage.draw(in: CGRect(origin: .zero, size: originalImage.size))
    
            let mirroredImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
    
            return mirroredImage
        }
    
        func flipImageVertically(_ originalImage: UIImage) -> UIImage? {
            UIGraphicsBeginImageContextWithOptions(originalImage.size, false, originalImage.scale)
    
            let context = UIGraphicsGetCurrentContext()!
    
            context.translateBy(x: 0, y: originalImage.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
    
            originalImage.draw(in: CGRect(origin: .zero, size: originalImage.size))
    
            let flippedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
    
            return flippedImage
        }
}
