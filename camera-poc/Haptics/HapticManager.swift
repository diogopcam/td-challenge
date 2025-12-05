import CoreHaptics
import UIKit

final class HapticManager {
    static let shared = HapticManager()

    private var engine: CHHapticEngine?
    private let supportsHaptics: Bool

    private init() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        if supportsHaptics {
            prepareHaptics()
        }
    }
    
    private func prepareHaptics() {
        guard supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            try engine?.start()

            engine?.stoppedHandler = { [weak self] reason in
                self?.restartEngine()
            }

            engine?.resetHandler = { [weak self] in
                self?.restartEngine()
            }
        } catch {
            print("Failed to create haptic engine: \(error)")
        }
    }

    private func restartEngine() {
        guard let engine = engine else { return }
        do {
            try engine.start()
        } catch {
            print("Failed to restart haptic engine: \(error)")
        }
    }

    func ensureEngineRunning() {
        guard supportsHaptics, let engine = engine else { return }
        do {
            try engine.start()
        } catch {
            print("Failed to start engine: \(error)")
        }
    }
    
    func playRevealCompleteHaptic() {
        guard supportsHaptics else { return }
        ensureEngineRunning()

        let firstPulse = createTransientEvent(intensity: 1.0, sharpness: 0.8, time: 0)
        let secondPulse = createTransientEvent(intensity: 0.9, sharpness: 0.7, time: 0.15)
        let thirdPulse = createTransientEvent(intensity: 0.8, sharpness: 0.6, time: 0.3)

        playPattern(events: [firstPulse, secondPulse, thirdPulse])
    }
    
    func playIntenseRevealHaptic() {
        guard supportsHaptics else { return }
        ensureEngineRunning()

        let continuous = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3),
            ],
            relativeTime: 0,
            duration: 0.3
        )

        playPattern(events: [continuous])
    }

    func playShutterHaptic(style: ShutterStyle) {
        guard supportsHaptics else { return }
        ensureEngineRunning()

        let events: [CHHapticEvent]
        
        switch style {
        case .mechanical:
            events = createMechanicalShutterEvents()
        case .heavy:
            events = createHeavyShutterEvents()
        case .electronic:
            events = createElectronicShutterEvents()
        case .double:
            events = createDoubleShutterEvents()
        case .oldCamera:
            events = createOldCameraShutterEvents()
        }
        
        playPattern(events: events)
    }

    func createMechanicalShutterEvents() -> [CHHapticEvent] {
        let start = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8),
            ],
            relativeTime: 0
        )
        
        let rumble = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4),
            ],
            relativeTime: 0.01,
            duration: 0.15
        )
        
        let end = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5),
            ],
            relativeTime: 0.16
        )
        
        return [start, rumble, end]
    }
    
    func createHeavyShutterEvents() -> [CHHapticEvent] {
        return [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3),
                ],
                relativeTime: 0
            )
        ]
    }
    
    func createElectronicShutterEvents() -> [CHHapticEvent] {
        return [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9),
                ],
                relativeTime: 0
            )
        ]
    }
    
    func createDoubleShutterEvents() -> [CHHapticEvent] {
        return [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6),
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8),
                ],
                relativeTime: 0.12
            )
        ]
    }
    
    func createOldCameraShutterEvents() -> [CHHapticEvent] {
        return [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4),
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5),
                ],
                relativeTime: 0.08
            )
        ]
    }

    func playPattern(events: [CHHapticEvent], curves: [CHHapticParameterCurve] = []) {
        guard supportsHaptics, let engine = engine else { return }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: curves)
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }

    @discardableResult
    func notification(_ type: NotificationType) -> Bool {
        guard supportsHaptics else { return false }
        ensureEngineRunning()

        let events = createNotificationEvents(for: type)
        playPattern(events: events)
        return true
    }
    
    func createNotificationEvents(for type: NotificationType) -> [CHHapticEvent] {
        switch type {
        case .success:
            return [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8),
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0),
                    ],
                    relativeTime: 0.1
                )
            ]
            
        case .warning:
            return [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4),
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4),
                    ],
                    relativeTime: 0.15
                )
            ]
            
        case .error:
            return (0..<4).map { index in
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8),
                    ],
                    relativeTime: TimeInterval(index) * 0.08
                )
            }
        }
    }

    @discardableResult
    func impact(_ style: ImpactStyle) -> Bool {
        guard supportsHaptics else { return false }
        ensureEngineRunning()

        let (intensity, sharpness) = getImpactParameters(for: style)
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: 0
        )

        playPattern(events: [event])
        return true
    }
    
    func getImpactParameters(for style: ImpactStyle) -> (intensity: Float, sharpness: Float) {
        switch style {
            case .light: return (0.4, 0.6)
            case .medium: return (0.7, 0.7)
            case .heavy: return (1.0, 0.8)
            case .soft: return (0.6, 0.3)
            case .rigid: return (1.0, 1.0)
        }
    }

    @discardableResult
    func selection() -> Bool {
        guard supportsHaptics else { return false }
        ensureEngineRunning()

        let event = createTransientEvent(intensity: 0.3, sharpness: 0.6, time: 0)
        playPattern(events: [event])
        return true
    }

    func shutterPress() {
        guard supportsHaptics else { return }
        ensureEngineRunning()
        
        let event = createTransientEvent(intensity: 0.75, sharpness: 0.8, time: 0)
        playPattern(events: [event])
    }
    
    func shutterRelease() {
        guard supportsHaptics else { return }
        ensureEngineRunning()
        
        let event = createTransientEvent(intensity: 0.7, sharpness: 0.5, time: 0)
        playPattern(events: [event])
    }
    
    func dialFeedback() {
        guard supportsHaptics else { return }
        ensureEngineRunning()
        
        let event = createTransientEvent(intensity: 0.4, sharpness: 0.4, time: 0)
        playPattern(events: [event])
    }

    func sliderFeedback() {
        guard supportsHaptics else { return }
        ensureEngineRunning()
        
        let event = createTransientEvent(intensity: 0.3, sharpness: 0.5, time: 0)
        playPattern(events: [event])
    }

    func flashFeedback() {
        guard supportsHaptics else { return }
        ensureEngineRunning()
        
        let event = createTransientEvent(intensity: 1.0, sharpness: 1.0, time: 0)
        playPattern(events: [event])
    }
    
    func buttonRelease() {
        guard supportsHaptics else { return }
        ensureEngineRunning()
        
        let event = createTransientEvent(intensity: 0.4, sharpness: 0.3, time: 0)
        playPattern(events: [event])
    }
    
    func playShakeHaptic() {
        guard supportsHaptics else { return }
        ensureEngineRunning()

        let transient = createTransientEvent(intensity: 1.0, sharpness: 0.2, time: 0)
        let continuous = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1),
            ],
            relativeTime: 0.05,
            duration: 0.15
        )

        playPattern(events: [transient, continuous])
    }
    
    var printingHapticPlayer: CHHapticAdvancedPatternPlayer?
    
    func startPrintingHaptic() {
        guard supportsHaptics else { return }
        ensureEngineRunning()
        
        stopPrintingHaptic()
        
        let continuous = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2),
            ],
            relativeTime: 0,
            duration: 100.0
        )
        
        do {
            let pattern = try CHHapticPattern(events: [continuous], parameterCurves: [])
            let player = try engine?.makeAdvancedPlayer(with: pattern)
            try player?.start(atTime: 0)
            printingHapticPlayer = player
        } catch {
            print("Failed to start printing haptic: \(error)")
        }
    }
    
    func stopPrintingHaptic() {
        do {
            try printingHapticPlayer?.stop(atTime: 0)
        } catch {
            print("Failed to stop printing haptic: \(error)")
        }
        printingHapticPlayer = nil
    }
    
    func createTransientEvent(intensity: Float, sharpness: Float, time: TimeInterval) -> CHHapticEvent {
        return CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: time
        )
    }
}

extension HapticManager {
    enum NotificationType {
        case success, warning, error
    }

    enum ImpactStyle {
        case light, medium, heavy, soft, rigid
    }
}

enum ShutterStyle: String, CaseIterable, Identifiable {
    
    case mechanical = "Mechanical"
    
    case heavy = "Heavy"
    
    case electronic = "Electronic"
    
    case double = "Double"
    
    case oldCamera = "Old Camera"

    var id: String { rawValue }
}
