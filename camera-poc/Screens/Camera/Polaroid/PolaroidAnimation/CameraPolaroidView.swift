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
    @State private var viewModel = CameraPolaroidViewModel()
    @EnvironmentObject var vm: CameraVM
    @State var showFinalPolaroid = false

    var body: some View {
        ZStack {
            Image("fundotela")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            RealityView { content in
                if let rootAnchor = viewModel.loader.anchor {
                    rootAnchor.transform.translation = [0.3, -0.4, 0]
                    rootAnchor.transform.scale = SIMD3<Float>(repeating: 15)

                    let currentRotation = rootAnchor.transform.rotation
                    let delta = simd_quatf(angle: -.pi/2, axis: [0, -0.4, 0])
                    rootAnchor.transform.rotation = simd_normalize(delta * currentRotation)

                    content.add(rootAnchor)
                }
            }
            
            .edgesIgnoringSafeArea(.all)
            
            .task {
                await viewModel.loader.loadEntity(name: "cameraPolaroidAnimadaSM")

                if let anchor = viewModel.loader.anchor {
                    viewModel.printAllEntities(anchor)

                    if let data = vm.capturedImage {
                        if let data = data.pngData() {
                            await viewModel.updatePolaroid(with: data, in: anchor)
                        }
                    }
                }
            }
            
            .onTapGesture {
                viewModel.playAnimation(in: viewModel.loader.anchor) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        showFinalPolaroid = true
                    }
                }
            }
            
            if showFinalPolaroid, let img = vm.capturedImage {
        
                Polaroid3DView(image: img)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(999)
            }
        }
    }
}
