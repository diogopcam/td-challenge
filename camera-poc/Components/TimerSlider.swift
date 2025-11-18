//
//  TimerSlider.swift
//  camera-poc
//
//  Created by Diogo Camargo on 12/11/25.
//

import SwiftUI

struct TimerSlider: View {
    @Binding var timerDelay: Int
    
    var body: some View {
        VStack {
            Text("Timer: \(timerDelay)s")
                .font(.headline)

            Slider(
                value: Binding(
                    get: { Double(timerDelay) },
                    set: { newValue in
                        let nearest = [0, 5, 10].min(by: { abs($0 - Int(newValue)) < abs($1 - Int(newValue)) }) ?? 0
                        timerDelay = nearest
                    }
                ),
                in: 0...10,
                step: 1
            )
            .tint(.yellow)
        }
        .padding()
    }
}
