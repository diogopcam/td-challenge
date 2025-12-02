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
                Image("fundotela")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                RealityView { content in
                    if let rootAnchor = loader.anchor {
                        rootAnchor.transform.translation = [0, -0.4, 0]
                        rootAnchor.transform.scale = SIMD3<Float>(repeating: 15)

                        let currentRotation = rootAnchor.transform.rotation
                        let delta = simd_quatf(angle: -.pi/2, axis: [0, -0.4, 0])
                        rootAnchor.transform.rotation = simd_normalize(delta * currentRotation)

                        content.add(rootAnchor)
                    }
                }
                .edgesIgnoringSafeArea(.all)
                .task {
                    await loader.loadEntity(name: "cameraPolaroidAnimadaSM")

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
            }
        }
    }


    func applyGrayOverlay(to image: UIImage,
                          gray: UIColor,
                          intensity: CGFloat) -> UIImage? {

        let rect = CGRect(origin: .zero, size: image.size)
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)

        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        // desenha a foto original
        image.draw(in: rect)

        // aplica camada cinza escura com intensidade controlada
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

        let overlayGray = UIColor(white: 0.02, alpha: 1.0)  // bem escuro

        let intensity: CGFloat = 0.80

        guard let tinted = applyGrayOverlay(to: uiImage,
                                            gray: overlayGray,
                                            intensity: intensity),
              let tintedCG = tinted.cgImage else {
            print("Erro ao aplicar overlay cinza")
            return
        }

        guard let target = findEntity(named: "imagePolaroid_001", in: anchor) as? ModelEntity else {
            print("Entidade 'imagePolaroid_001' não encontrada")
            return
        }

        do {
            // 5) Cria textura já mascarada
            let texture = try await TextureResource(
                image: tintedCG,
                options: .init(semantic: .color)
            )

            let wrappedTexture = MaterialParameters.Texture(texture)

            // 6) Aplica no PhysicallyBasedMaterial
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(texture: wrappedTexture)

            if var model = target.model {
                model.materials = [material]
                target.model = model
            }

            print("Textura mascarada aplicada com sucesso!")

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
