//
//  ContentView.swift
//  camera-poc
//
//  Created by Diogo Camargo on 06/11/25.
//

import SwiftData
import SwiftUI

struct SimpleCameraView: View {
    @StateObject private var vm = CameraVM()
    
    var body: some View {
        ZStack {
            if vm.isCameraAuthorized {
                
                VStack(spacing: 30) {
                    CameraFrame(session: vm.session)
                        .frame(height: 400)
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
                    
                    if let img = vm.capturedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    } else {
                        Image(systemName: "checkmark")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            }
        }
    }
}

// Extensão para usar UIImage com Binding opcional
extension UIImage: Identifiable {
    public var id: String { UUID().uuidString }
}
