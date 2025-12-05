//
//  MuralPlaceholderView.swift
//  camera-poc
//
//  Created by Gabriel Barbosa on 05/12/25.
//

import SwiftUI

struct MuralPlaceholderView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Parabéns! Você está na tela de mural! Incrível!")
                .font(.title)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {
                dismiss()
            }) {
                Text("Voltar para Câmera")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 200)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

#Preview {
    MuralPlaceholderView()
}
