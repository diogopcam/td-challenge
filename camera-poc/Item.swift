//
//  Item.swift
//  camera-poc
//
//  Created by Diogo Camargo on 06/11/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
