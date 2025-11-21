import SwiftUI
import RealityKit
import AVFoundation // 1. Importar AVFoundation

struct Modelo3DView: UIViewRepresentable {
    
    func dumpHierarchy(_ entity: Entity, level: Int = 0) {
        let indent = String(repeating: "  ", count: level)
        print("\(indent)- \(entity.name) [\(type(of: entity))]")
        for child in entity.children {
            dumpHierarchy(child, level: level + 1)
        }
    }
    
    // 2. Implementar o makeCoordinator
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(
            frame: .zero,
            cameraMode: .nonAR,
            automaticallyConfigureSession: false
        )
        
        do {
            let modelEntity: Entity = try Entity.load(named: "cameraModel")
            dumpHierarchy(modelEntity)
            modelEntity.scale = SIMD3<Float>(repeating: 1.0)
            modelEntity.position = SIMD3<Float>(0, -2.1, 2)
            
            let yaw = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 1, 0))
            let roll = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 0, 1))
            modelEntity.orientation = roll * yaw
            
            modelEntity.generateCollisionShapes(recursive: true)
            
            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(modelEntity)
            arView.scene.addAnchor(anchor)
            
            // 🔹 CÂMERA PERSONALIZADA (Virtual)
            let camera = PerspectiveCamera()
            let cameraTranslation = SIMD3<Float>(0, 0, 5)
            let cameraTransform = Transform(
                scale: .one,
                rotation: simd_quatf(angle: -.pi/12, axis: SIMD3<Float>(0, 0, 0)),
                translation: cameraTranslation
            )
            camera.transform = cameraTransform
            camera.look(at: .zero, from: cameraTranslation, relativeTo: nil)
            
            let cameraAnchor = AnchorEntity(world: .zero)
            cameraAnchor.addChild(camera)
            arView.scene.addAnchor(cameraAnchor)
            
            context.coordinator.rootModelEntity = modelEntity
            context.coordinator.arView = arView

            // 👇 Guardar referência do CameraBody (pra saber se o toque foi na câmera)
            if let cameraBody = modelEntity.findEntity(named: "CameraBody") {
                context.coordinator.cameraBody = cameraBody
                print("Achei entidade CameraBody em RealityKit")
            } else {
                print("NÃO achei entidade 'CameraBody' em RealityKit")
            }
            
            let panGesture = UIPanGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handlePan(_:))
            )
            arView.addGestureRecognizer(panGesture)

            context.coordinator.setupCameraFeed()
            
            // ExposureButton
            if let knob = modelEntity.findEntity(named: "Cylinder") {
                context.coordinator.knobEntity = knob
                context.coordinator.baseKnobOrientation = knob.orientation
                print("Achei knob: \(knob.name)")
            } else {
                print("⚠️ Não achei entidade 'Knob' no modelo. Ajuste o nome no código.")
            }

        } catch {
            print("Erro ao carregar modelo .usdz: \(error)")
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    // 5. Mover a função applyCameraImage para dentro do Coordinator
    //    (Ela não é mais necessária aqui)
    
    
    // 6. Criar a classe Coordinator
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        
        var captureSession: AVCaptureSession?
        var rootModelEntity: Entity? // Referência ao modelo 3D
        var cameraBody: Entity?
        var cameraBodyAnimation: AnimationResource?
        weak var arView: ARView?      // <-- ADICIONAR
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
        
        // Função para configurar a sessão de captura da câmera
        func setupCameraFeed() {
            let session = AVCaptureSession()
            // Tenta usar uma resolução baixa para melhor performance
            session.sessionPreset = .vga640x480
            
            // Procura pela câmera traseira
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                print("Não foi possível acessar a câmera traseira.")
                return
            }
            
            self.captureDevice = device
            
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            let output = AVCaptureVideoDataOutput()
            // Define o Coordinator como o delegate para receber os frames
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.feed.queue"))
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            self.captureSession = session
            
            // Inicia a sessão em uma thread separada
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
        
        // 7. Delegar: Chamado para cada frame da câmera
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            
            // LINHA DE DEBUG:
                //print("------- FRAME DA CÂMERA RECEBIDO! -------")
            
            // Tenta converter o buffer do frame em um UIImage
            guard let uiImage = imageFromSampleBuffer(sampleBuffer) else { return }
            
            // Atualiza a textura na thread principal
            DispatchQueue.main.async {
                if let root = self.rootModelEntity {
                    self.applyCameraImage(uiImage, to: root)
                }
            }
        }
        
        // Função auxiliar para converter CMSampleBuffer para UIImage
        private func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
            
            var ciImage = CIImage(cvPixelBuffer: imageBuffer)
            
            // Descobre a orientação física do aparelho
            let deviceOrientation = UIDevice.current.orientation
            
            // Rotaciona a imagem de acordo com o landscape
            switch deviceOrientation {
            case .landscapeLeft:
                // Botão do volume pra baixo
                ciImage = ciImage.oriented(.left)   // 90º CW
            case .landscapeRight:
                // Botão do volume pra cima
                ciImage = ciImage.oriented(.right)    // 90º CCW
            default:
                // Fallback (por segurança)
                ciImage = ciImage.oriented(.right)
            }
            
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
            
            // Agora os pixels já estão "na posição certa"
            return UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
        }
        
        // MARK: - Exposição (knob → rotação + câmera)

        func applyExposure(_ exposure: Float) {
            // clamp entre -2 e 2
            let clampedKnob = max(-2.0, min(2.0, exposure))
            knobValue = clampedKnob
            
            let logicalExposure = -clampedKnob
            currentExposure = logicalExposure

            // 1) Rotação do knob
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
            
            //print("Usando 'PhotoPlane' como ModelEntity: \(targetModel)")
            
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
}
