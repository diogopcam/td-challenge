//
//  PhotoRepositoryProtocol.swift
//  camera-poc
//
//  Created by Diogo Camargo on 12/11/25.
//

import Foundation

protocol PhotoRepositoryProtocol {
    func save(_ photo: Photo) throws
    func fetchAll() -> [Photo]
    func delete(_ id: UUID) throws
}
