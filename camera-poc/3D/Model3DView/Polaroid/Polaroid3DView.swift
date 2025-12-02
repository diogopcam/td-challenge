//
//  Polaroid3DView.swift
//  camera-poc
//
//  Created by Diogo Camargo on 02/12/25.
//

import SwiftUI
import RealityKit
import Combine

struct Polaroid3DView: UIViewRepresentable {
    var image: UIImage?
    
    func makeCoordinator() -> Polaroid3DCoordinator {
        Polaroid3DCoordinator()
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(
            frame: .zero,
            cameraMode: .nonAR,
            automaticallyConfigureSession: false
        )
        
        arView.environment.background = .color(.black)
        
        do {
            let modelEntity = try Entity.load(named: "polaroidnew2")
            modelEntity.generateCollisionShapes(recursive: true)
            
            // Armazenar a entidade principal no coordinator
            context.coordinator.polaroidEntity = modelEntity
            
            // Verificar se encontramos o imagePolaroid
            if let imagePart = findImagePolaroidEntity(in: modelEntity) {
                print("✅ Encontrado imagePolaroid: \(imagePart.name)")
                print("   Tem material? \(imagePart.model?.materials.count ?? 0)")
            } else {
                print("⚠️ imagePolaroid não encontrado")
            }
            
            let anchor = AnchorEntity(.camera)
            anchor.position = SIMD3<Float>(0, 0, -1.5) // Posição melhor
            anchor.addChild(modelEntity)
            arView.scene.addAnchor(anchor)
            
            // Aplicar a imagem inicial se já tiver uma
            if let img = image {
                updatePolaroidImage(img, in: modelEntity)
            }
            
        } catch {
            print("Erro ao carregar polaroidModel:", error)
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Se uma nova imagem foi passada → atualiza a Polaroid
        if let img = image,
           let polaroidEntity = context.coordinator.polaroidEntity {
            updatePolaroidImage(img, in: polaroidEntity)
        }
    }
    
    func findImagePolaroidEntity(in entity: Entity) -> ModelEntity? {
        // Procura recursivamente
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
    
    func printAllEntities(from root: Entity, level: Int = 0) {
        let indent = String(repeating: "  ", count: level)
        print("\(indent)• \(root.name)  [\(type(of: root))]")
    
        if let model = root as? ModelEntity {
            print("\(indent)  📐 Tem \(model.model?.materials.count ?? 0) material(is)")
        }
        
        for child in root.children {
            printAllEntities(from: child, level: level + 1)
        }
    }
}
