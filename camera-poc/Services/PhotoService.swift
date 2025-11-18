//
//  PhotoService.swift
//  camera-poc
//
//  Created by Diogo Camargo on 12/11/25.
//

import SwiftUI
import SwiftData
import Combine

final class PhotoService: PhotoServiceProtocol {
    private let repository: PhotoRepositoryProtocol
    
    init(repository: PhotoRepositoryProtocol) {
        self.repository = repository
    }
    
    func savePhoto(image: UIImage, annotation: String?) throws {
        let photo = Photo(annotation: annotation, image: image)
        try? repository.save(photo)
    }
    
    func fetchAllPhotos() throws -> [Photo] {
        repository.fetchAll()
    }

    func deletePhoto(withId id: UUID) {
        try? repository.delete(id)
    }
}
