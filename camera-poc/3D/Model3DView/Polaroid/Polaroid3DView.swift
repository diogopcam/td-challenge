//
//  Polaroid3DView.swift
//  camera-poc
//
//  Created by Diogo Camargo on 02/12/25.
//

import SwiftUI
import RealityKit

struct Polaroid3DView: View {
    @Bindable var viewModel: Polaroid3DViewModel
    
    var body: some View {
        RealityView { content in

            if let modelEntity = try? Entity.load(named: "polaroidNew") {
                
                modelEntity.generateCollisionShapes(recursive: true)
                
                viewModel.modelEntity = modelEntity
            
                viewModel.applyTexture()
                
                let anchor = AnchorEntity(.camera)
                anchor.addChild(modelEntity)
                content.add(anchor)
            }
        }
        .task {
            viewModel.startRevealAnimation()
        }
        .background(.clear)
    }
}
