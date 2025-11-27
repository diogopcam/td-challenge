//
//  RootEntityLoader.swift
//  camera-poc
//
//  Created by Fernanda Farias Uberti on 24/11/25.
//

import Foundation
import RealityKit
import SwiftUI

@Observable
class RootEntityLoader{
    var anchor: AnchorEntity?
    

    init() {
        self.anchor = AnchorEntity()

    }

    func loadEntity(name: String) async {
        if let entity = try? await Entity(named: name) {
            anchor?.addChild(entity)
        } else {
            print("Erro: entidade \(name) não encontrada")
        }
    }
}
