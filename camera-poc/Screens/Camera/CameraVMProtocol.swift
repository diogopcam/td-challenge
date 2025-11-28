//
//  CameraVMProtocol.swift
//  camera-poc
//
//  Created by Diogo Camargo on 24/11/25.
//

import SwiftUI
import AVFoundation
import Combine

protocol CameraVMProtocol: ObservableObject {
    
    // MARK: Properties
    var isCameraAuthorized: Bool { get }
    var capturedImage: UIImage? { get }
    var errorMessage: String? { get }
    var isFlashOn: Bool { get set }
    var timerDelay: Int { get set }
    var countdown: Int? { get }
    var currentFrame: UIImage? { get }
    var currentFramePublisher: Published<UIImage?>.Publisher { get }
    var exposure: Float { get set }
    
    // MARK: - Methods
    func checkCameraPermission()
    func setupCamera()
    func takePhoto()
    func toggleFlash()
    func cropToSquare(image: UIImage) -> UIImage?
}
