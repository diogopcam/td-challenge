//
//  Polaroid.swift
//  camera-poc
//
//  Created by Diogo Camargo on 12/11/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Photo {
    var id: UUID
    var timestamp: Date
    var annotation: String?
    var imageData: Data
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        annotation: String? = nil,
        image: UIImage
    ) {
        self.id = id
        self.timestamp = timestamp
        self.annotation = annotation
        self.imageData = image.jpegData(compressionQuality: 0.8) ?? Data()
    }
}

extension Photo {
    var image: UIImage? {
        UIImage(data: imageData)
    }
}
