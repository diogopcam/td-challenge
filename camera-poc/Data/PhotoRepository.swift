//
//  SwiftDataPhotoRepository.swift
//  camera-poc
//
//  Created by Diogo Camargo on 12/11/25.
//

import SwiftUI
import SwiftData

final class PhotoRepository: PhotoRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ photo: Photo) throws {
        context.insert(photo)
        try context.save()
    }

    func fetchAll() -> [Photo] {
        (try? context.fetch(FetchDescriptor<Photo>())) ?? []
    }
    
    func delete(_ id: UUID) throws {
        let descriptor = FetchDescriptor<Photo>(
            predicate: #Predicate { $0.id == id }
        )

        if let photo = try context.fetch(descriptor).first {
            context.delete(photo)
            try context.save()
        }
    }
}
