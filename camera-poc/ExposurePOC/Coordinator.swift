//
//  Coordinator.swift
//  camera-poc
//
//  Created by Diogo Camargo on 24/11/25.
//

import SwiftUI
import RealityKit
import AVFoundation
import Combine

class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    var vm: CameraVM
    
    private var cancellables = Set<AnyCancellable>()

    init(vm: CameraVM){
        self.vm = vm
        super.init()
        print("🎯 Coordinator FOI CRIADO!") 
        
        vm.$currentFrame
            .receive(on: DispatchQueue.main)
            .sink { [weak self] frame in
                print("Coordinator recebeu frame: \(frame != nil ? "SIM" : "NIL")")
                
                if let frame = frame, let root = self?.rootModelEntity {
                    print("Aplicando frame no modelo 3D")
                    self?.applyCameraImage(frame, to: root)
                } else {
                    if frame == nil { print("❌ Frame é nil") }
                    if self?.rootModelEntity == nil { print("❌ rootModelEntity é nil") }
                }
            }
            .store(in: &cancellables) // ⚠️ FALTANDO!
    }
    
    var captureSession: AVCaptureSession?
    var rootModelEntity: Entity?
    var cameraBody: Entity?
    var cameraBodyAnimation: AnimationResource?
    weak var arView: ARView?
    private let context = CIContext()
    
    var captureDevice: AVCaptureDevice?
    
    var knobEntity: Entity?
    var baseKnobOrientation: simd_quatf?
    var currentExposure: Float = 0.0
    var knobValue: Float = 0.0
    var knobCenterScreen: CGPoint = .zero
    var dragStartAngle: Float = 0.0
    private var lastAngle: Float = 0.0
    
    private var isDraggingKnob = false
    private var dragStartX: CGFloat = 0
    private var exposureAtDragStart: Float = 0
    
    private func knobCenterInScreen() -> CGPoint? {
        guard let arView = arView,
              let knob = knobEntity else { return nil }
        
        // posição do knob em coordenadas de mundo
        let worldPosition = knob.position(relativeTo: nil)
        
        // projeta para coordenadas de tela
        if let screenPoint = arView.project(worldPosition) {
            return screenPoint
        } else {
            return nil
        }
    }
    
    // MARK: - Exposição (knob → rotação + câmera)
    func applyExposure(_ exposure: Float) {
        // clamp entre -2 e 2
        let clampedKnob = max(-2.0, min(2.0, exposure))
        knobValue = clampedKnob
        
        let logicalExposure = -clampedKnob
        currentExposure = logicalExposure

        // Knob rotation
        if let knob = knobEntity {
            // -2 ... 2 → -135° ... 135°
            let degreesPerStop: Float = 67.5
            let angleDegrees = clampedKnob * degreesPerStop
            let angleRadians = angleDegrees * .pi / 180

            let rotationQuat = simd_quatf(
                angle: angleRadians,
                axis: SIMD3<Float>(1, 0, 0) // eixo X, igual no Blender
            )

            if let base = baseKnobOrientation {
                knob.orientation = rotationQuat * base
            } else {
                knob.orientation = rotationQuat
            }
        }

        // 2) Exposição da câmera (bias)
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
                let bias = logicalExposure
                device.setExposureTargetBias(bias, completionHandler: nil)
                device.unlockForConfiguration()
            } catch {
                print("Erro ao ajustar exposição da câmera: \(error)")
            }
        }
    }

    func applyCameraImage(_ image: UIImage, to root: Entity) {
        // 1. Acha QUALQUER entidade chamada "PhotoPlane"
        guard let photoPlaneEntity = root.findEntity(named: "PhotoPlane") else {
            print("ERRO CRÍTICO: Não existe nenhuma entidade chamada 'PhotoPlane'.")
            return
        }
        
        //print("Achei 'PhotoPlane' do tipo: \(type(of: photoPlaneEntity))")
        
        // 2. Se já for ModelEntity, beleza. Se não for, procura um filho ModelEntity
        let targetModel: ModelEntity
        
        if let model = photoPlaneEntity as? ModelEntity {
            targetModel = model
        } else if let childModel = photoPlaneEntity.children.first(where: { $0 is ModelEntity }) as? ModelEntity {
            targetModel = childModel
        } else {
            print("ERRO: 'PhotoPlane' não é ModelEntity e não tem filho ModelEntity.")
            return
        }
        
        // 3. Cria textura a partir da imagem
        guard let cgImage = image.cgImage else { return }
        
        let texture: TextureResource
        do {
            texture = try TextureResource.generate(
                from: cgImage,
                options: .init(semantic: .color)
            )
        } catch {
            print("ERRO: Falha ao gerar textura a partir da imagem da câmera: \(error)")
            return
        }
        
        // 4. Material sem influência de luz
        var material = UnlitMaterial()
        material.color = .init(
            tint: .white,
            texture: .init(texture)
        )
        
        // 5. Aplica na malha da polaroid
        targetModel.model?.materials = [material]
    }
    
    // MARK: - Toque na câmera para animar

    private func isPartOfCameraBody(_ entity: Entity) -> Bool {
        var current: Entity? = entity
        while let e = current {
            if e.name == "CameraBody" { return true }
            current = e.parent
        }
        return false
    }
    
    private func isPartOfKnob(_ entity: Entity) -> Bool {
        var current: Entity? = entity
        while let e = current {
            if e.name == "Cylinder" {      // mesmo nome usado no findEntity
                return true
            }
            current = e.parent
        }
        return false
    }
    
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let arView = arView else { return }
        let location = recognizer.location(in: arView)

        switch recognizer.state {
        case .began:
            // verifica se começou em cima do knob
            if let entity = arView.entity(at: location),
               isPartOfKnob(entity) {
                isDraggingKnob = true
                print("🌀 Começou arrasto no knob")

                // 1) Calcula o centro do knob na tela
                if let center = knobCenterInScreen() {
                    knobCenterScreen = center
                } else {
                    // fallback: centro da view se não conseguir projetar
                    knobCenterScreen = CGPoint(x: arView.bounds.midX,
                                               y: arView.bounds.midY)
                }

                // 2) Ângulo inicial entre centro do knob e ponto de toque
                let dx = Float(location.x - knobCenterScreen.x)
                let dy = Float(location.y - knobCenterScreen.y)
                let startAngle = atan2(dy, dx)

                dragStartAngle = startAngle
                lastAngle = startAngle          // 👈 agora usamos incrementalmente

                // 3) Valor inicial do KNOB
                exposureAtDragStart = knobValue
            } else {
                isDraggingKnob = false
            }

        case .changed:
            guard isDraggingKnob else { return }

            // vetor do centro do knob até o dedo
            let dx = Float(location.x - knobCenterScreen.x)
            let dy = Float(location.y - knobCenterScreen.y)

            // evita instabilidade muito perto do centro
            let distance = hypot(dx, dy)
            if distance < 20 {        // 20px de raio de segurança (ajustável)
                return
            }

            let currentAngle = atan2(dy, dx)

            // diferença de ângulo em relação AO ÚLTIMO FRAME
            var deltaAngle = currentAngle - lastAngle

            // normaliza para [-π, π] para evitar saltos grandes
            let twoPi = Float.pi * 2
            if deltaAngle > Float.pi {
                deltaAngle -= twoPi
            } else if deltaAngle < -Float.pi {
                deltaAngle += twoPi
            }

            // atualiza lastAngle pro próximo frame
            lastAngle = currentAngle

            // mapeia delta de ângulo → delta de exposição
            // 270° (±135°) de giro total → 4 "stops" (-2 ... 2)
            let maxAngle = Float(270.0 * .pi / 180.0) // 270° em radianos

            // se quiser inverter o sentido do gesto, troca o sinal desse "-"
            let deltaStops = -(deltaAngle / maxAngle) * 4.0

            // acumula no valor atual do KNOB
            let unclampedKnob = knobValue + deltaStops
            let newKnobValue = max(-2.0, min(2.0, unclampedKnob))

            applyExposure(newKnobValue)


        case .ended, .cancelled, .failed:
            isDraggingKnob = false

            // 1) Pega a exposição lógica atual e arredonda p/ 1 casa decimal
            var snappedLogical = (currentExposure * 10).rounded() / 10

            // 2) Garante que continua dentro do intervalo [-2, 2]
            snappedLogical = max(-2.0, min(2.0, snappedLogical))

            // 3) Converte de volta para o valor do knob
            //    (lembrando: currentExposure = -knobValue)
            let snappedKnob = -snappedLogical

            // 4) Aplica de novo para alinhar knob + câmera no valor "travado"
            applyExposure(snappedKnob)

            print("Exposição fixada em: \(currentExposure)")

        default:
            break
        }
    }
}
