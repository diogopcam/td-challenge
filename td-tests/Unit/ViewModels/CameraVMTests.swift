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
    
    @Test("Initial state is correct")
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
    
    @Test("Exposure updates to positive value")
    func exposureAdjustment() {
        let sut = CameraVM()
        
        sut.exposure = 1.5
        
        #expect(sut.exposure == 1.5)
    }
    
    @Test("Exposure updates to negative value")
    func exposureNegativeValue() {
        let sut = CameraVM()
        
        sut.exposure = -1.0
        
        #expect(sut.exposure == -1.0)
    }
    
    @Test("Toggling flash inverts state")
    func flashToggle() {
        let sut = CameraVM()
        let initial = sut.isFlashOn
        
        sut.toggleFlash()
        
        #expect(sut.isFlashOn == !initial)
    }
    
    @Test("Double toggle returns flash to original state")
    func flashToggleTwiceReturnsToOriginal() {
        let sut = CameraVM()
        let initial = sut.isFlashOn
        
        sut.toggleFlash()
        sut.toggleFlash()
        
        #expect(sut.isFlashOn == initial)
    }
    
    @Test("Timer delay stores positive value correctly")
    func timerDelaySetting() {
        let sut = CameraVM()
        
        sut.timerDelay = 3
        
        #expect(sut.timerDelay == 3)
    }
    
    @Test("Timer delay can be set to zero")
    func timerDelayZero() {
        let sut = CameraVM()
        
        sut.timerDelay = 0
        
        #expect(sut.timerDelay == 0)
    }
    
    @Test("CropToSquare handles small images correctly")
    func cropToSquareWithSmallImage() {
        let sut = CameraVM()
        let img = UIImage(systemName: "circle")!
        
        let cropped = sut.cropToSquare(image: img)
        
        #expect(cropped != nil)
    }
    
    @Test("CurrentFrame publisher exists")
    func currentFramePublisherExists() {
        let sut = CameraVM()
        
        #expect(type(of: sut.currentFramePublisher) == Published<UIImage?>.Publisher.self)
    }
    
    @Test("Countdown begins using timerDelay value")
    func countdownStartsWithTimerDelay() {
        let sut = CameraVM()
        sut.timerDelay = 2
        
        sut.startCountdown()
        
        #expect(sut.countdown == 2)
    }
}
