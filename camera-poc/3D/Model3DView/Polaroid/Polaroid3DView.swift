//
//  Polaroid3DView.swift
//  camera-poc
//
//  Created by Diogo Camargo on 02/12/25.
//

import SwiftUI
import RealityKit
import CoreImage
import Combine

struct Polaroid3DView: View {
    let image: UIImage
    
    @StateObject private var shakeManager = ShakeManager()
    @State private var cancellables = Set<AnyCancellable>()
    
    @State private var overlayOpacity: CGFloat = 0.85  // Começa forte
    @State private var lastShakeTime: Date = Date()
    @State private var isRevealed: Bool = false
    
    private let minShakeInterval: TimeInterval = 0.15
    private let revealStep: CGFloat = 0.12
    private let revealThreshold: CGFloat = 0.01
    
    var body: some View {
        RealityView { content in
            
            guard let modelEntity = try? Entity.load(named: "polaroidNew") else {
                print("❌ Error loading 3D model")
                return
            }
            
            applyTexture(entity: modelEntity)
            
            modelEntity.generateCollisionShapes(recursive: true)
            
            let anchor = AnchorEntity(.camera)
            anchor.addChild(modelEntity)
            content.add(anchor)
            
            setupShakeDetection(for: modelEntity)
            
        }
    }
}

extension Polaroid3DView {
    
    // MARK: - Setup Shake Logic
    private func setupShakeDetection(for model: Entity) {
        shakeManager.shakeSubject
            .sink { [self] in
                self.handleShake(for: model)
            }
            .store(in: &cancellables)
    }
    
    private func handleShake(for model: Entity) {
        let now = Date()
        
        guard now.timeIntervalSince(lastShakeTime) >= minShakeInterval else { return }
        lastShakeTime = now
        
        // Revela mais a foto
        overlayOpacity = max(0, overlayOpacity - revealStep)
        
        updateTexture(entity: model)
        
        if !isRevealed {
            HapticManager.shared.playIntenseRevealHaptic()
        }
        
        // Final da revelação
        if overlayOpacity <= revealThreshold && !isRevealed {
            isRevealed = true
            overlayOpacity = 0
            
            SoundManager.shared.playSound(named: "polaroidRevealed", volume: 1.0)
            HapticManager.shared.playRevealCompleteHaptic()
        }
    }
}

extension Polaroid3DView {
    
    // MARK: - Applying Texture
    private func applyTexture(entity: Entity) {
        updateTexture(entity: entity)
    }
    
    private func updateTexture(entity: Entity) {
        guard let polaroidNode = findImagePolaroidEntity(in: entity) else { return }
        
        let img = processedImage(intensity: overlayOpacity)
        guard let cgImage = img.cgImage else { return }
        
        do {
            let texture = try TextureResource(image: cgImage, options: .init(semantic: .color))
            
            var material = SimpleMaterial()
            material.color = .init(tint: .white, texture: .init(texture))
            polaroidNode.model?.materials = [material]
            
        } catch {
            print("❌ Error updating texture: \(error)")
        }
    }
}

extension Polaroid3DView {
    
    // MARK: - Find Polaroid Image Mesh
    func findImagePolaroidEntity(in entity: Entity) -> ModelEntity? {
        if let m = entity as? ModelEntity,
           entity.name.lowercased().contains("imagepolaroid") {
            return m
        }
        
        for child in entity.children {
            if let found = findImagePolaroidEntity(in: child) {
                return found
            }
        }
        return nil
    }
}

extension Polaroid3DView {
    
    // MARK: - Full Processing Pipeline
    func processedImage(intensity: CGFloat) -> UIImage {
        let normalized = fixImageOrientation(image)
        let flipped = flipImageHorizontally(normalized) ?? normalized
        
        let filtered = applyPolaroidFilter(to: flipped) ?? flipped
        
        return applyGrayOverlay(
            to: filtered,
            gray: UIColor(white: 0.02, alpha: 1),
            intensity: intensity
        ) ?? filtered
    }
    
    
    // MARK: - Polaroid Filter
    func applyPolaroidFilter(to image: UIImage) -> UIImage? {
        guard let ciInput = CIImage(image: image) else { return nil }
        guard let ciOut = applyPolaroidEffect(to: ciInput) else { return nil }
        
        let context = CIContext()
        guard let cg = context.createCGImage(ciOut, from: ciOut.extent) else { return nil }
        
        return UIImage(cgImage: cg)
    }
    
    func applyPolaroidEffect(to ci: CIImage) -> CIImage? {
        let f = CIFilter.photoEffectInstant()
        f.inputImage = ci
        
        guard let instantOut = f.outputImage else { return nil }
        
        let v = CIFilter.vignette()
        v.inputImage = instantOut
        v.intensity = 0.5
        v.radius = 1.2
        
        return v.outputImage
    }
    
    
    // MARK: - Utility Functions
    func fixImageOrientation(_ img: UIImage) -> UIImage {
        if img.imageOrientation == .up { return img }
        
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale)
        img.draw(in: CGRect(origin: .zero, size: img.size))
        let r = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return r
    }
    
    func flipImageHorizontally(_ img: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.translateBy(x: img.size.width, y: 0)
        ctx.scaleBy(x: -1, y: 1)
        img.draw(in: CGRect(origin: .zero, size: img.size))
        let r = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return r
    }
    
    func applyGrayOverlay(to img: UIImage, gray: UIColor, intensity: CGFloat) -> UIImage? {
        let rect = CGRect(origin: .zero, size: img.size)
        
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale)
        let ctx = UIGraphicsGetCurrentContext()!
        
        img.draw(in: rect)
        
        ctx.setFillColor(gray.withAlphaComponent(intensity).cgColor)
        ctx.fill(rect)
        
        let out = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return out
    }
}
