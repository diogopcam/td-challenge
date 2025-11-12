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
                    Button(action: {
                        vm.toggleFlash()
                    }) {
                        Image(systemName: vm.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                            .foregroundColor(vm.isFlashOn ? .yellow : .white)
                    }
                    
                    ExposureSlider(exposure: $vm.exposure)
                        .padding(.horizontal, 64)
                    
                    TimerSlider(timerDelay: $vm.timerDelay)
                        .padding(.horizontal, 64)
                }
                
                ZStack {
                    CameraFrame(session: vm.session)
                        .frame(width: 341, height: 341)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    if let countdown = vm.countdown {
                        Text("\(countdown)")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(radius: 10)
                            .transition(.scale.combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.3), value: countdown)
                    }
                }
                
                VStack(alignment: .center, spacing: 32) {
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
                            .frame(width: 120, height: 120)
                    } else {
                        Text("Any image was captured yet")
                            .padding(.horizontal, 32)
                    }
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
