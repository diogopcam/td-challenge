//
//  ContentView.swift
//  camera-poc
//
//  Created by Diogo Camargo on 06/11/25.
//

import SwiftData
import SwiftUI

struct CameraView: View {
    @ObservedObject var vm: CameraVM
    
    init(vm: CameraVM) {
        self.vm = vm
    }
    
    var body: some View {
        if vm.isCameraAuthorized {
            
            HStack(spacing: 30) {
                VStack {
                    if let img = vm.capturedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                    } else {
                        Text("Any image was captured yet")
                    }
                }

                CameraFrame(session: vm.session)
                    .frame(width: 341, height: 341)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Button(action: {
                    vm.takePhoto()
                }) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 3)
                                .frame(width: 80, height: 80)
                        )
                }
                
                Button(action: {
                    vm.toggleFlash()
                }) {
                    Image(systemName: vm.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                            .foregroundColor(vm.isFlashOn ? .yellow : .white)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
    }
}

// Extensão para usar UIImage com Binding opcional
extension UIImage: @retroactive Identifiable {
    public var id: String { UUID().uuidString }
}
