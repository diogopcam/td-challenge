import CoreHaptics
import UIKit

/// Gerenciador centralizado de feedback háptico usando CoreHaptics
/// Componentizado para fácil integração em outros projetos
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

    // MARK: - Engine Management
    
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

    private func ensureEngineRunning() {
        guard supportsHaptics, let engine = engine else { return }
        do {
            try engine.start()
        } catch {
            print("Failed to start engine: \(error)")
        }
    }

    // MARK: - Camera Haptics
    /// Estilos de haptic para o obturador da câmera
    enum ShutterStyle: String, CaseIterable, Identifiable {
        
        case mechanical = "Mechanical"
        
        case heavy = "Heavy"
        
        case electronic = "Electronic"
        
        case double = "Double"
        
        case oldCamera = "Old Camera"

        var id: String { rawValue }
    }

    /// Reproduz haptic do obturador baseado no estilo selecionado
    /// - Parameter style: Estilo do haptic do obturador
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
    
    // MARK: - Shutter Event Builders
    private func createMechanicalShutterEvents() -> [CHHapticEvent] {
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
    
    private func createHeavyShutterEvents() -> [CHHapticEvent] {
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
    
    private func createElectronicShutterEvents() -> [CHHapticEvent] {
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
    
    private func createDoubleShutterEvents() -> [CHHapticEvent] {
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
    
    private func createOldCameraShutterEvents() -> [CHHapticEvent] {
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

    // MARK: - Pattern Playback
    private func playPattern(events: [CHHapticEvent], curves: [CHHapticParameterCurve] = []) {
        guard supportsHaptics, let engine = engine else { return }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: curves)
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }

    // MARK: - System Haptics
    /// Reproduz haptic de notificação
    /// - Parameter type: Tipo de notificação (success, warning, error)
    /// - Returns: true se o haptic foi reproduzido com sucesso
    @discardableResult
    func notification(_ type: NotificationType) -> Bool {
        guard supportsHaptics else { return false }
        ensureEngineRunning()

        let events = createNotificationEvents(for: type)
        playPattern(events: events)
        return true
    }
    
    private func createNotificationEvents(for type: NotificationType) -> [CHHapticEvent] {
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

    /// Reproduz haptic de impacto
    /// - Parameter style: Estilo do impacto
    /// - Returns: true se o haptic foi reproduzido com sucesso
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
    
    private func getImpactParameters(for style: ImpactStyle) -> (intensity: Float, sharpness: Float) {
        switch style {
        case .light: return (0.4, 0.6)
        case .medium: return (0.7, 0.7)
        case .heavy: return (1.0, 0.8)
        case .soft: return (0.6, 0.3)
        case .rigid: return (1.0, 1.0)
        }
    }

    /// Reproduz haptic de seleção (leve e preciso)
    /// - Returns: true se o haptic foi reproduzido com sucesso
    @discardableResult
    func selection() -> Bool {
        guard supportsHaptics else { return false }
        ensureEngineRunning()

        let event = createTransientEvent(intensity: 0.3, sharpness: 0.6, time: 0)
        playPattern(events: [event])
        return true
    }

    // MARK: - Camera Control Haptics
    /// Haptic personalizado para pressionar o botão do obturador
    /// Intensidade média-alta para feedback tátil claro
    func shutterPress() {
        guard supportsHaptics else { return }
        ensureEngineRunning()
        
        // Haptic médio-alto, nítido para o pressionar
        let event = createTransientEvent(intensity: 0.75, sharpness: 0.8, time: 0)
        playPattern(events: [event])
    }
    
    /// Haptic personalizado para soltar o botão do obturador
    /// Intensidade média-alta, mais suave que o press
    func shutterRelease() {
        guard supportsHaptics else { return }
        ensureEngineRunning()
        
        // Haptic médio-alto, mais suave para o soltar
        let event = createTransientEvent(intensity: 0.7, sharpness: 0.5, time: 0)
        playPattern(events: [event])
    }
    
    /// Feedback háptico para rotação do dial de exposição
    func dialFeedback() {
        guard supportsHaptics else { return }
        ensureEngineRunning()
        
        let event = createTransientEvent(intensity: 0.4, sharpness: 0.4, time: 0)
        playPattern(events: [event])
    }

    /// Feedback háptico para movimento do slider de timer
    func sliderFeedback() {
        guard supportsHaptics else { return }
        ensureEngineRunning()
        
        let event = createTransientEvent(intensity: 0.3, sharpness: 0.5, time: 0)
        playPattern(events: [event])
    }

    /// Feedback háptico para ativação/desativação do flash
    func flashFeedback() {
        guard supportsHaptics else { return }
        ensureEngineRunning()
        
        let event = createTransientEvent(intensity: 1.0, sharpness: 1.0, time: 0)
        playPattern(events: [event])
    }

    /// Feedback háptico para liberação do botão do obturador
    func buttonRelease() {
        guard supportsHaptics else { return }
        ensureEngineRunning()
        
        let event = createTransientEvent(intensity: 0.4, sharpness: 0.3, time: 0)
        playPattern(events: [event])
    }
    
    /// Feedback háptico para agitação da foto Polaroid
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
    
    // MARK: - Helper Methods
    
    private func createTransientEvent(intensity: Float, sharpness: Float, time: TimeInterval) -> CHHapticEvent {
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
