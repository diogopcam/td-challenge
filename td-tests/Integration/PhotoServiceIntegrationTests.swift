//
//  PhotoServiceIntegrationTests.swift
//  camera-poc
//
//  Created by Diogo Camargo on 18/11/25.
//

import Testing
import SwiftData
import UIKit
@testable import camera_poc

struct PhotoServiceIntegrationTests {

    // Creates an in-memory SwiftData container for each test
    private func makeInMemoryContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Photo.self, configurations: config)
    }

    @MainActor @Test("Save photo to database")
    func testSavePhoto() throws {
        // Given
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let repository = PhotoRepository(context: context)
        let service = PhotoService(repository: repository)

        let sampleImage = UIImage(systemName: "circle")!

        // When
        try service.savePhoto(image: sampleImage, annotation: "Test Annotation")

        // Then
        let all = try service.fetchAllPhotos()

        #expect(all.count == 1)
        #expect(all.first?.annotation == "Test Annotation")
        #expect(all.first?.image != nil)
    }

    @MainActor @Test("Fetch all saved photos")
    func testFetchAllPhotos() throws {
        // Given
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let repository = PhotoRepository(context: context)
        let service = PhotoService(repository: repository)

        let img = UIImage(systemName: "square")!

        // Insert two photos manually
        try service.savePhoto(image: img, annotation: "A")
        try service.savePhoto(image: img, annotation: "B")

        // When
        let all = try service.fetchAllPhotos()

        // Then
        #expect(all.count == 2)
    }

    @MainActor @Test("Delete photo")
    func testDeletePhoto() throws {
        // Given
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let repository = PhotoRepository(context: context)
        let service = PhotoService(repository: repository)

        let img = UIImage(systemName: "triangle")!

        try service.savePhoto(image: img, annotation: "To Delete")
        var all = try service.fetchAllPhotos()

        #expect(all.count == 1)

        let idToDelete = all[0].id

        // When
        service.deletePhoto(withId: idToDelete)
        all = try service.fetchAllPhotos()

        // Then
        #expect(all.isEmpty)
    }
}

