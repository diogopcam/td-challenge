//
//  Polaroid3DView.swift
//  camera-poc
//
//  Created by Diogo Camargo on 02/12/25.
//

import SwiftUI
import RealityKit

struct Polaroid3DView: View {
    var image: UIImage
    
    init(image: UIImage) {
        self.image = image
    }
    
    var body: some View {
        RealityView { content in
            // 1. Carrega o modelo
            guard let modelEntity = try? Entity.load(named: "polaroidNew") else {
                return
            }
            
            applyImage(entity: modelEntity)
            
            // AQUI A IMAGEM DEVE SER APLICADA COM O TOM CINZA
//            applyImage()
            // 2. Gera colisão (opcional)
            modelEntity.generateCollisionShapes(recursive: true)

            // 4. Cria o anchor e adiciona o modelo
            let anchor = AnchorEntity(.camera)
            anchor.addChild(modelEntity)
            content.add(anchor)
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
    
    func processedImage(intensity: CGFloat) -> UIImage {
        let normalized = fixImageOrientation(image)
        let flipped = flipImageHorizontally(normalized) ?? normalized
        
        return applyGrayOverlay(
            to: flipped,
            gray: UIColor(white: 0.02, alpha: 1),
            intensity: intensity
        ) ?? flipped
    }

    
//    func applyImage(entity: Entity) {
//        let imageNode = findImagePolaroidEntity(in: entity)
//        
//        let processed = processedImage(intensity: 10)
//        
//        guard let cgImage = processed.cgImage else { return }
//        
//        do {
//            let texture = try TextureResource(
//                image: cgImage,
//                options: .init(semantic: .color)
//            )
//            
//            var material = SimpleMaterial()
//            material.color = .init(tint: .white, texture: .init(texture))
//            imageNode?.model?.materials = [material]
//            
//        } catch {
//            print("Erro criando textura: \(error)")
//        }
//    }
    
    func applyImage(entity: Entity) {
        guard let imageNode = findImagePolaroidEntity(in: entity) else { return }

        // Intensidade inicial bem forte
        var intensity: CGFloat = 0.9
        let steps: CGFloat = 60
        let interval: TimeInterval = 15 / 60  // 15s total

        func updateTexture() {
            let processed = processedImage(intensity: intensity)
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

        // Aplica textura inicial (cinza forte)
        updateTexture()

        // Timer para revelar
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in

            // Diminui a intensidade do cinza progressivamente
            intensity -= 0.9 / steps
            
            if intensity <= 0 {
                intensity = 0
                updateTexture()
                timer.invalidate()
                return
            }

            updateTexture()
        }
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
