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
            
            if !vm.isCameraAuthorized {
                PermissionView()
                    .transition(.opacity)
                    .zIndex(1) 
            }
            
        if let count = vm.countdown {
                Text("\(count)")
                    .font(.system(size: 120, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(radius: 10)
                    .transition(.opacity)
                    .animation(.easeInOut, value: count)
            }
        }
        .fullScreenCover(isPresented: $vm.showAnimation) {
            if let img = vm.capturedImage {
                CameraPolaroidView()
                    .environmentObject(vm)
            }
        }
        .fullScreenCover(isPresented: $vm.shouldNavigateToMural) {
            MuralPlaceholderView()
        }
    }
}
