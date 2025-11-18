//
//  MockPhotoRepository.swift
//  camera-poc
//
//  Created by Diogo Camargo on 18/11/25.
//

import UIKit
@testable import camera_poc

final class MockPhotoRepository: PhotoRepositoryProtocol {
    private(set) var savedPhotos: [Photo] = []
    private(set) var deletedPhotoIds: [UUID] = []
    
    var saveCalled = false
    var fetchAllCalled = false
    var deleteCalled = false
    
    func save(_ photo: Photo) throws {
        saveCalled = true
        savedPhotos.append(photo)
    }
    
    func fetchAll() -> [Photo] {
        fetchAllCalled = true
        return savedPhotos
    }
    
    func delete(_ id: UUID) throws {
        deleteCalled = true
        deletedPhotoIds.append(id)
        savedPhotos.removeAll { $0.id == id }
    }
}
