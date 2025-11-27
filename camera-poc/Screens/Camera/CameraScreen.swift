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
            Model3DViewMF()
                .environmentObject(vm)
        }
        .fullScreenCover(isPresented: $vm.showCapturedPhoto) {
            if let img = vm.capturedImage {
                CapturedPhotoView(image: img) {
                    vm.showCapturedPhoto = false
                    print("É PARA APARECER A VIEW")
                }
            }
        }
    }
}
