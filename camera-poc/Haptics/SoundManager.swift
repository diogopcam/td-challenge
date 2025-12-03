import AVFoundation
import UIKit

/// Gerenciador centralizado de sons usando AVAudioPlayer
/// Otimizado para performance e limpeza automática de recursos
final class SoundManager {
    static let shared = SoundManager()

    private var players: [AVAudioPlayer] = []
    private let maxPlayers = 10

    private init() {
        setupAudioSession()
    }

    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: .mixWithOthers
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Sound Playback
    func playSound(named name: String, volume: Float = 1.0) {
        guard let asset = NSDataAsset(name: name) else {
            print("Sound asset not found: \(name)")
            return
        }

        cleanupFinishedPlayers()
        
        guard players.count < maxPlayers else {
            print("Too many active players, skipping sound: \(name)")
            return
        }

        do {
            let player = try AVAudioPlayer(data: asset.data)
            player.volume = volume
            player.prepareToPlay()
            player.play()
            players.append(player)
        } catch {
            print("Error playing sound '\(name)': \(error.localizedDescription)")
        }
    }
    
    // MARK: - Continuous Sound Playback
    private var continuousPlayer: AVAudioPlayer?
    
    /// Toca um som continuamente em loop até ser parado
    func playContinuousSound(named name: String, volume: Float = 1.0) {
        // Se já está tocando, não faz nada
        if let player = continuousPlayer, player.isPlaying {
            return
        }
        
        guard let asset = NSDataAsset(name: name) else {
            print("Sound asset not found: \(name)")
            return
        }

        do {
            let player = try AVAudioPlayer(data: asset.data)
            player.volume = volume
            player.numberOfLoops = -1 // Loop infinito
            player.prepareToPlay()
            player.play()
            continuousPlayer = player
        } catch {
            print("Error playing continuous sound '\(name)': \(error.localizedDescription)")
        }
    }
    
    /// Para o som contínuo
    func stopContinuousSound() {
        continuousPlayer?.stop()
        continuousPlayer = nil
    }
    
    // MARK: - Cleanup
    private func cleanupFinishedPlayers() {
        players.removeAll { !$0.isPlaying }
    }
}
