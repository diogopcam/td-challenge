//
//  CameraVMTests.swift
//  camera-poc
//
//  Created by Diogo Camargo on 24/11/25.
//

import Testing
import UIKit
@testable import camera_poc

struct CameraVMTests {
    
    // MARK: - Initialization Tests
    @Test
    func initialState() {
        let sut = CameraVM()
        
        #expect(sut.isCameraAuthorized == false)
        #expect(sut.capturedImage == nil)
        #expect(sut.isFlashOn == false)
        #expect(sut.timerDelay == 0)
        #expect(sut.countdown == nil)
        #expect(sut.currentFrame == nil)
        #expect(sut.exposure == 0.0)
    }
    
    // MARK: - Exposure Tests
    @Test
    func exposureAdjustment() {
        let sut = CameraVM()
        
        sut.exposure = 1.5
        
        #expect(sut.exposure == 1.5)
    }
    
    @Test
    func exposureNegativeValue() {
        let sut = CameraVM()
        
        sut.exposure = -1.0
        
        #expect(sut.exposure == -1.0)
    }
    
    // MARK: - Flash Tests
    @Test
    func flashToggle() {
        let sut = CameraVM()
        let initial = sut.isFlashOn
        
        sut.toggleFlash()
        
        #expect(sut.isFlashOn == !initial)
    }
    
    @Test
    func flashToggleTwiceReturnsToOriginal() {
        let sut = CameraVM()
        let initial = sut.isFlashOn
        
        sut.toggleFlash()
        sut.toggleFlash()
        
        #expect(sut.isFlashOn == initial)
    }
    
    // MARK: - Timer Tests
    @Test
    func timerDelaySetting() {
        let sut = CameraVM()
        
        sut.timerDelay = 3
        
        #expect(sut.timerDelay == 3)
    }
    
    @Test
    func timerDelayZero() {
        let sut = CameraVM()
        
        sut.timerDelay = 0
        
        #expect(sut.timerDelay == 0)
    }
    
    @Test
    func cropToSquareWithSmallImage() {
        let sut = CameraVM()
        let img = UIImage(systemName: "circle")!
        
        let cropped = sut.cropToSquare(image: img)
        
        #expect(cropped != nil)
    }
    
    // MARK: - Current Frame Publisher Tests
    @Test
    func currentFramePublisherExists() {
        let sut = CameraVM()
        
        #expect(type(of: sut.currentFramePublisher) == Published<UIImage?>.Publisher.self)
    }
    
    // MARK: - Countdown Tests
    @Test
    func countdownStartsWithTimerDelay() {
        let sut = CameraVM()
        sut.timerDelay = 2
        
        sut.startCountdown()
        
        #expect(sut.countdown == 2)
    }
}
