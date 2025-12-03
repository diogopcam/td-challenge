//
//  CameraScreen.swift
//  camera-poc
//
//  Created by Diogo Camargo on 27/11/25.
//

import SwiftUI

struct CameraScreen: View {
    @EnvironmentObject var vm: CameraVM

    var body: some View {
        ZStack {
            Camera3DView()
                .environmentObject(vm)
            
        if let count = vm.countdown {
                Text("\(count)")
                    .font(.system(size: 120, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
                    .transition(.opacity)
                    .animation(.easeInOut, value: count)
            }
        }
        // 1. Tela da animação Polaroid
        .fullScreenCover(isPresented: $vm.showAnimation) {
            CameraPolaroidView()
                .environmentObject(vm)
        }
        // 2. Tela final com a foto
        .fullScreenCover(isPresented: $vm.showCapturedPhoto) {
            if let img = vm.capturedImage {
                CapturedPhotoView(image: img) {
                    vm.showCapturedPhoto = false
                }
            }
        }
    }
}
