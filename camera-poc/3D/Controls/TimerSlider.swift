//
//  TimerSlider.swift
//  camera-poc
//
//  Created by Gabriel Barbosa on 21/11/25.
//

import RealityKit
import UIKit

class TimerSlider {
    
    private let knobEntity: Entity
    private let pos0: SIMD3<Float>
    private let pos5: SIMD3<Float>
    private let pos10: SIMD3<Float>
    
    private(set) var selectedValue: Int = 0
    private var currentProgress: Float = 0.0
    
    var onValueChange: ((Int) -> Void)?
    
    private var startProgress: Float = 0.0
    private var touchStartLocation: CGPoint = .zero
    private var screenTrackVector: CGPoint = .zero
    
    init?(rootEntity: Entity) {
        guard let knob = rootEntity.findEntity(named: "TimerKnob"),
              let e0 = rootEntity.findEntity(named: "Empty0s"),
              let e5 = rootEntity.findEntity(named: "Empty5s"),
              let e10 = rootEntity.findEntity(named: "Empty10s") else {
            return nil
        }
        
        self.knobEntity = knob
        
        self.pos0 = e0.position
        self.pos5 = e5.position
        self.pos10 = e10.position
        
        self.knobEntity.position = pos0
        self.currentProgress = 0.0
    }
    
    func represents(_ entity: Entity?) -> Bool {
        guard let target = entity else { return false }
        var current: Entity? = target
        while let e = current {
            if e == self.knobEntity { return true }
            current = e.parent
        }
        return false
    }
    
    func handlePan(_ recognizer: UIPanGestureRecognizer, in arView: ARView) {
        
        if !ButtonManager.shared.isEnabled {
            if recognizer.state == .began {
                HapticManager.shared.impact(.light)
                SoundManager.shared.playSound(named: "disableButton1")
            }

            return
        }

        let location = recognizer.location(in: arView)

        switch recognizer.state {

        case .began:
            touchStartLocation = location
            startProgress = currentProgress

            let worldPos0 = knobEntity.parent?.convert(position: pos0, to: nil) ?? pos0
            let worldPos10 = knobEntity.parent?.convert(position: pos10, to: nil) ?? pos10

            guard let p0 = arView.project(worldPos0),
                  let p10 = arView.project(worldPos10) else { return }

            screenTrackVector = CGPoint(x: p10.x - p0.x, y: p10.y - p0.y)


        case .changed:
            let dragVector = CGPoint(x: location.x - touchStartLocation.x,
                                     y: location.y - touchStartLocation.y)

            let trackLengthSquared = screenTrackVector.x * screenTrackVector.x +
                                     screenTrackVector.y * screenTrackVector.y
            guard trackLengthSquared > 0 else { return }

            let dotProduct = dragVector.x * screenTrackVector.x + dragVector.y * screenTrackVector.y
            let progressDelta = Float(dotProduct / trackLengthSquared)

            var newProgress = startProgress + progressDelta
            newProgress = max(0.0, min(1.0, newProgress))

            HapticManager.shared.sliderFeedback()
            updateKnobPosition(progress: newProgress)


        case .ended, .cancelled:
            let snapTarget: Float
            let finalValue: Int

            if currentProgress < 0.25 {
                snapTarget = 0.0
                finalValue = 0
            } else if currentProgress < 0.75 {
                snapTarget = 0.5
                finalValue = 5
            } else {
                snapTarget = 1.0
                finalValue = 10
            }

            currentProgress = snapTarget
            selectedValue = finalValue
            updateKnobPosition(progress: snapTarget)
            onValueChange?(finalValue)

        default:
            break
        }
    }

    
    private func updateKnobPosition(progress: Float) {
        self.currentProgress = progress
        
        let newPos: SIMD3<Float>
        if progress <= 0.5 {
            let localP = progress * 2.0
            newPos = simd_mix(pos0, pos5, SIMD3<Float>(repeating: localP))
        } else {
            let localP = (progress - 0.5) * 2.0
            newPos = simd_mix(pos5, pos10, SIMD3<Float>(repeating: localP))
        }
        
        knobEntity.position = newPos
    }
}
