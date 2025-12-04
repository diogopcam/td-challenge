//
//  PolaroidTiltWrapper.swift
//  camera-poc
//
//  Created by Bruna Marschner on 04/12/25.
//

import SwiftUI

struct PolaroidTiltModifier: ViewModifier {
    @State private var tiltY: Double = 0
    @State private var tiltX: Double = 0

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(tiltY),
                axis: (x: 0, y: 1, z: 0)
            )
            .rotation3DEffect(
                .degrees(tiltX),
                axis: (x: 1, y: 0, z: 0)
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let maxTranslation: CGFloat = 120
                        
                        // horizontal -> gira pros lados
                        let clampedX = max(-maxTranslation,
                                           min(maxTranslation, value.translation.width))
                        let normalizedX = clampedX / maxTranslation   // -1...1
                        let maxAngle: Double = 12                      // graus
                        tiltY = Double(normalizedX) * maxAngle
                        
                        // vertical
                        let clampedY = max(-maxTranslation,
                                           min(maxTranslation, value.translation.height))
                        let normalizedY = clampedY / maxTranslation   // -1...1
                        tiltX = -Double(normalizedY) * (maxAngle)
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.4,
                                              dampingFraction: 0.7)) {
                            tiltX = 0
                            tiltY = 0
                        }
                    }
            )
            .animation(.easeOut(duration: 0.12), value: tiltX)
            .animation(.easeOut(duration: 0.12), value: tiltY)
    }
}

extension View {
    func polaroidTilt() -> some View {
        self.modifier(PolaroidTiltModifier())
    }
}
