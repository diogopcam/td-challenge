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
    @State private var showMural = false

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
            .allowsHitTesting(!showFinalPolaroid)

            .task {
                await viewModel.loader.loadEntity(name: "cameraPolaroidAnimadaSM")

                if let anchor = viewModel.loader.anchor {
                    viewModel.printAllEntities(anchor)

                    if let data = vm.capturedImage,
                       let png = data.pngData() {
                        await viewModel.updatePolaroid(with: png, in: anchor)
                    }
                }
            }

            .onTapGesture {
                guard !showFinalPolaroid else { return }

                viewModel.playAnimation(in: viewModel.loader.anchor) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        showFinalPolaroid = true
                    }
                }
            }

            if showFinalPolaroid, let img = vm.capturedImage {
                GeometryReader { geo in
                    let sideWidth = geo.size.width * 0.35

                    ZStack {
                        // Polaroid central
                        Polaroid3DView(image: img)
                            .polaroidTilt()
                            .frame(width: geo.size.width,
                                   height: geo.size.height,
                                   alignment: .center)
                            .zIndex(1)

                        // Botões laterais
                        HStack {
                            // DESCARTAR (lado esquerdo)
                            ZStack {
                                Color.clear   // só pra ter uma área visível pra toque

                                VStack(spacing: 10) {
                                    Text("Tap here to discard\nthis photo.")
                                        .font(.custom("Caption Handwriting Regular", size: 23))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)

                                    Image("discardicon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 35, height: 35)
                                }
                                // rotaciona TUDO junto (texto + ícone)
                                .rotationEffect(.degrees(-12))
                            }
                            .frame(width: sideWidth,
                                   height: geo.size.height,
                                   alignment: .center)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                print("👉 Discard tapped")
                                vm.capturedImage = nil
                                showFinalPolaroid = false      // some só o overlay
                                vm.showAnimation = false
                            }

                            Spacer(minLength: 0)

                            // SALVAR (lado direito)
                            ZStack {
                                Color.clear

                                VStack(spacing: 10) {
                                    Text("Tap here to save\nthis memory.")
                                        .font(.custom("Caption Handwriting Regular", size: 23))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)

                                    Image("savememoryicon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 35, height: 35)
                                }
                                .rotationEffect(.degrees(12))
                            }
                            .frame(width: sideWidth,
                                   height: geo.size.height,
                                   alignment: .center)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                print("👉 Save tapped")
                                vm.saveToMural(img)
                                showMural = true
                            }
                        }
                        .frame(width: geo.size.width,
                               height: geo.size.height)
                        .zIndex(2)
                    }
                    .frame(width: geo.size.width,
                           height: geo.size.height)
                    .contentShape(Rectangle())
                }
                .ignoresSafeArea()
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(50)
            }
        }
        .sheet(isPresented: $showMural) {
            MuralView()
                .environmentObject(vm)
        }
    }
}
