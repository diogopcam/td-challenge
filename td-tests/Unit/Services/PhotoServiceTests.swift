//
//  PhotoServiceTests.swift
//  camera-poc
//
//  Created by Diogo Camargo on 18/11/25.
//

import Testing
import UIKit
@testable import camera_poc

struct PhotoServiceTests {
    
    // MARK: - savePhoto
    @Test("savePhoto calls repository correctly")
    func testSavePhoto() throws {
        let repository = MockPhotoRepository()
        let service = PhotoService(repository: repository)
        
        let image = UIImage(systemName: "camera")!
        
        try service.savePhoto(image: image, annotation: "Test")
        
        #expect(repository.saveCalled == true)
        #expect(repository.savedPhotos.count == 1)
        #expect(repository.savedPhotos.first?.annotation == "Test")
        #expect(repository.savedPhotos.first?.image != nil)
    }
    
    // MARK: - fetchAllPhotos
    @Test("fetchAllPhotos returns data correctly from repository")
    func testFetchAllPhotos() throws {
        let repository = MockPhotoRepository()
        let service = PhotoService(repository: repository)
        
        // Pre-populate the "database"
        let img = UIImage(systemName: "camera")!
        let photo = Photo(annotation: "photo", image: img)
        try repository.save(photo)
        
        let result = try service.fetchAllPhotos()
        
        #expect(repository.fetchAllCalled == true)
        #expect(result.count == 1)
        #expect(result.first?.annotation == "photo")
    }
    
    // MARK: - deletePhoto
    @Test("deletePhoto removes item from repository")
    func testDeletePhoto() throws {
        let repository = MockPhotoRepository()
        let service = PhotoService(repository: repository)
        
        let img = UIImage(systemName: "camera")!
        let photo = Photo(annotation: "photo", image: img)
        try repository.save(photo)
        
        service.deletePhoto(withId: photo.id)
        
        #expect(repository.deleteCalled == true)
        #expect(repository.deletedPhotoIds.contains(photo.id))
        
        // Database should be empty
        let all = try service.fetchAllPhotos()
        #expect(all.isEmpty)
    }
}
