//
//  PhotoServiceProtocol.swift
//  camera-poc
//
//  Created by Diogo Camargo on 12/11/25.
//

import Foundation
import SwiftData
import UIKit

protocol PhotoServiceProtocol {
    func savePhoto(image: UIImage, annotation: String?) throws
    func fetchAllPhotos() throws -> [Photo]
    func deletePhoto(withId id: UUID) throws
}
