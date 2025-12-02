//
//  ButtonManager.swift
//  camera-poc
//
//  Created by Diogo Camargo on 02/12/25.
//


class ButtonManager {
    static let shared = ButtonManager()
    private init() {}

    private(set) var isEnabled: Bool = true

    func disable() {
        isEnabled = false
        SoundManager.shared.playSound(named: "blocked") // opcional
    }

    func enable() {
        isEnabled = true
    }
}
