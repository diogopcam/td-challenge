//
//  PermissionView.swift
//  camera-poc
//
//  Created by Gabriel Barbosa on 04/12/25.
//

import SwiftUI

struct PermissionView: View {
    var body: some View {
        ZStack {
            
            VStack(spacing: 24) {
        
                Text("Required Permissions")
                    .font(.custom("Caption Handwriting Regular", size: 23))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack {
                    
                    Image("cameraAccessIcon")
                    
                    Text("Camera Access")
                        .font(.custom("Caption Handwriting Regular", size: 16))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        
                }
    
                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    
                    Text("Go to Settings")
                        .font(.custom("Caption Handwriting Regular", size: 16))
                        .padding()
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .foregroundColor(.blue)
                                .frame(width: 217,height: 34)
                        )
                }
            }
            .padding()
        }
    }
}

#Preview {
    PermissionView()
}
