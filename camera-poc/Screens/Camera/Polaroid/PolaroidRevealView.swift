//
//  PolaroidRevealView.swift
//  camera-poc
//
//  Created by Auto on 11/11/25.
//

import SwiftUI
import Combine
import UIKit

struct PolaroidRevealView: View {
    let image: UIImage
    let onClose: () -> Void
    
    @StateObject private var shakeManager = ShakeManager()
    @State private var overlayOpacity: Double = 0.85 // Opacidade do overlay branco (começa alto)
    @State private var isRevealed: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var lastShakeTime: Date = Date()
    @State private var isRevealing: Bool = false // Controla se a revelação começou
    
    private let minShakeInterval: TimeInterval = 0.15 // Intervalo mínimo entre haptics/sons (reduzido para ser mais rápido)
    private let revealThreshold: Double = 0.01 // Opacidade mínima do overlay para considerar revelado
    private let opacityReduction: Double = 0.12 // Quantidade de opacidade removida por shake (aumentado para revelar mais rápido)
    
    var body: some View {
        ZStack {
            
            // Imagem de fundo desfocada (para efeito de profundidade)
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width * 3.7, height: geometry.size.height * 1.1)
                    .blur(radius: 50)
                    .opacity(0.3)
                    .offset(x: -geometry.size.width * 1.1, y: -geometry.size.height * 0.05)
            }
            .ignoresSafeArea()
            
            // Conteúdo principal centralizado
            HStack(spacing: 24) {
                // Instrução e ícone de shake
                VStack(spacing: 8) {
                    // Ícone de shake
                    Image("shakeIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 31)
                    
                    // Texto "Shake to reveal your photo"
                    Text("Shake to reveal your photo.")
                        .font(getHandwritingFont(size: 16))
                        .foregroundColor(.white)
                        .opacity(0.8)
                        .shadow(color: .black.opacity(0.7), radius: 4, x: -2, y: 2)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .frame(width: 118)
                }
                .frame(width: 119, height: 84)
                
                // Polaroid
                VStack(spacing: 11.172) {
                    // Imagem com opacidade que será revelada
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 207.8, height: 191)
                            .clipped()
                            .opacity(0.15 + (1.0 - overlayOpacity) * 0.85) // Começa em 0.15 e vai até 1.0
                        
                        // Overlay branco que será removido conforme o shake
                        Color.white
                            .opacity(overlayOpacity)
                    }
                    .frame(width: 207.8, height: 191)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .blur(radius: overlayOpacity > 0.1 ? 0.112 : 0)
                    
                    // Data
                    HStack {
                        Spacer()
                        Text(formatDate())
                            .font(getHandwritingFont(size: 12))
                            .foregroundColor(Color(red: 0.847, green: 0.847, blue: 0.847))
                    }
                    .frame(width: 208, height: 55)
                }
                .padding(11.172)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .shadow(color: .black.opacity(0.25), radius: 3.714, x: 0, y: 3.714)
                .shadow(color: Color(red: 0.922, green: 0.922, blue: 0.922), radius: 0, x: -4, y: 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Botão de fechar (após revelação)
            if isRevealed {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                                .shadow(radius: 10)
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            setupShakeDetection()
        }
        .onDisappear {
            cancellables.removeAll()
            // Para o som contínuo quando a view desaparecer
            SoundManager.shared.stopContinuousSound()
        }
    }
    
    private func setupShakeDetection() {
        shakeManager.shakeSubject
            .sink { [self] in
                handleShake()
            }
            .store(in: &cancellables)
    }
    
    private func handleShake() {
        let now = Date()
        
        // Limita a frequência de haptics
        guard now.timeIntervalSince(lastShakeTime) >= minShakeInterval else {
            return
        }
        
        lastShakeTime = now
        
        // Inicia o som contínuo apenas na primeira vez
        if !isRevealing {
            isRevealing = true
            SoundManager.shared.playContinuousSound(named: "shakeWind", volume: 0.9)
        }
        
        // Reduz a opacidade do overlay progressivamente (mais rápido)
        withAnimation(.easeOut(duration: 0.1)) {
            overlayOpacity = max(0, overlayOpacity - opacityReduction)
        }
        
        // Toca haptic intenso e contínuo apenas se ainda não estiver revelado
        if !isRevealed {
            HapticManager.shared.playIntenseRevealHaptic()
        }
        
        // Verifica se a foto foi completamente revelada
        if overlayOpacity <= revealThreshold && !isRevealed {
            isRevealed = true
            overlayOpacity = 0
            
            // Para o som contínuo quando a revelação estiver completa
            SoundManager.shared.stopContinuousSound()
            
            // Toca som de conclusão
            SoundManager.shared.playSound(named: "succe3", volume: 1.0)
            
            // Toca haptic de conclusão (diferente do contínuo)
            HapticManager.shared.playRevealCompleteHaptic()
        }
    }
    
    private func formatDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: Date())
    }
    
    private func getHandwritingFont(size: CGFloat) -> Font {
        // Tenta diferentes nomes de fonte
        if let font = UIFont(name: "Caption Handwriting Regular", size: size) {
            return Font(font)
        } else if let font = UIFont(name: "Caption Handwriting", size: size) {
            return Font(font)
        } else {
            // Fallback para uma fonte similar
            return .system(size: size, design: .rounded)
        }
    }
}

