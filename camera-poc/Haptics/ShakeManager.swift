import Combine
import CoreMotion
import Foundation

/// Gerenciador de detecção de agitação do dispositivo
/// Usa o acelerômetro para detectar movimentos bruscos
class ShakeManager: ObservableObject {
    private let motionManager = CMMotionManager()
    let shakeSubject = PassthroughSubject<Void, Never>()
    
    private let shakeThreshold: Double = 2.5
    private let updateInterval: TimeInterval = 0.1

    init() {
        startAccelerometerUpdates()
    }

    // MARK: - Accelerometer Setup
    
    private func startAccelerometerUpdates() {
        guard motionManager.isAccelerometerAvailable else {
            print("Accelerometer not available")
            return
        }

        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            if let error = error {
                print("Accelerometer error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else { return }
            self?.processAccelerometerData(data)
        }
    }
    
    private func processAccelerometerData(_ data: CMAccelerometerData) {
        let acceleration = data.acceleration
        let magnitude = sqrt(
            pow(acceleration.x, 2) +
            pow(acceleration.y, 2) +
            pow(acceleration.z, 2)
        )

        if magnitude > shakeThreshold {
            shakeSubject.send()
        }
    }

    deinit {
        motionManager.stopAccelerometerUpdates()
    }
}
