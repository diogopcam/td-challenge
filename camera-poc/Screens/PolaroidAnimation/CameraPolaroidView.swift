//
//  PolaroidView.swift
//  camera-poc
//
//  Created by Fernanda Farias Uberti on 24/11/25.
//

import SwiftUI
import RealityKit
import UIKit


struct CameraPolaroidView: View {
    @State var loader = RootEntityLoader()
    @State var showTransition = false

    
    var body: some View {
        VStack {
            ZStack {
                
                RealityView { content in
                    
                    if let rootAnchor = loader.anchor {
            
                        rootAnchor.transform.translation = [0, -0.4, 0]
                        rootAnchor.transform.scale = SIMD3<Float>(repeating: 13)

                        let currentRotation = rootAnchor.transform.rotation
                        let delta = simd_quatf(angle: -.pi/2, axis: [0, -0.4, 0])

                        rootAnchor.transform.rotation = simd_normalize(delta * currentRotation)
                        content.add(rootAnchor)

                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
                .task {
                    await loader.loadEntity(name: "a")
                    if let anchor = loader.anchor {
                           printAllEntities(anchor)
                           
                        if let data = UIImage(named: "fotoTeste")?.pngData() {
                               await updatePolaroid(with: data, in: anchor)
                           } else {
                               print("Não consegui carregar fotoTeste.png")
                           }
                       }
                    

                }
                .onTapGesture {
                    playAnimation()
                }
                
                if showTransition {
                        PolaroidTransitionView {
                            showTransition = false
                        }
                        .transition(.opacity)
                        .ignoresSafeArea()
                    }
            }
        }
    }
    
    func updatePolaroid(with imageData: Data, in anchor: Entity) async {
        guard let uiImage = UIImage(data: imageData),
              let cg = uiImage.cgImage else {
            print("Erro convertendo Data -> UIImage")
            return
        }

        guard let target = findEntity(named: "imagePolaroid_001", in: anchor) as? ModelEntity else {
            print("Entidade 'imagePolaroid_001' não encontrada")
            return
        }

        do {
            let texture = try await TextureResource(
                image: cg,
                options: .init(semantic: .color)
            )
            let wrappedTexture = MaterialParameters.Texture(texture)

            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(texture: wrappedTexture)

            if var model = target.model {
                model.materials = [material]
                target.model = model
            }

            print("Textura atualizada com sucesso!")

        } catch {
            print("Erro gerando TextureResource: \(error)")
        }
    }


    
    func printAllEntities(_ entity: Entity, indent: String = "") {
        print("\(indent)- \(entity.name) | \(type(of: entity))")

        for child in entity.children {
            printAllEntities(child, indent: indent + "    ")
        }
    }

    func findEntity(named name: String, in root: Entity) -> Entity? {
        if root.name == name { return root }
        for child in root.children {
            if let found = findEntity(named: name, in: child) { return found }
        }
        return nil
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
    
    
    func playAnimation() {
        guard let anchor = loader.anchor else { return }
        
        
        if let anim = anchor.availableAnimations.first {
            anchor.playAnimation(anim.repeat(count: 1), transitionDuration: 0.3)
            return
        }
        
        
        if let entityWithAnim = findEntityWithAnimation(in: anchor),
           let anim = entityWithAnim.availableAnimations.first {
            entityWithAnim.playAnimation(anim.repeat(count: 1), transitionDuration: 0.2)
        }
    }
}
#Preview {
    CameraPolaroidView()
}
