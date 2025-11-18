//
//  ExposureSlider.swift
//  camera-poc
//
//  Created by Diogo Camargo on 12/11/25.
//

import SwiftUI

struct ExposureSlider: View {
    @Binding var exposure: Float

    var body: some View {
        VStack {
            Text("Exposure: \(exposure, specifier: "%.1f")")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))

            Slider(
                value: $exposure,
                in: -3.0...3.0,
                step: 0.1
            )
            .tint(.yellow)
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 20)
    }
}
