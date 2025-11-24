import SwiftUI
import CoreMotion

// MARK: - Calibration Configuration
private let PITCH_THRESHOLD: Double = 0.6      // Up/Down Sensitivity (~20°)
private let YAW_THRESHOLD: Double = 0.4        // Left/Right Sensitivity (~23°)
private let CALIBRATION_DELAY: TimeInterval = 0.5
private let MOVEMENT_DETECTION_DELAY: TimeInterval = 0.1

struct GameScreen: View {
    @ObservedObject var multiPeer: MultiPeerManager
    var onGameEnd: () -> Void
    
    @State private var clickCount = 0
    @State private var timeRemaining = 10
    @State private var timer: Timer?
    @State private var motionManager = CMMotionManager()
    @State private var lastDirection = ""
    
    // Calibration State
    @State private var neutralPitch: Double = 0
    @State private var neutralYaw: Double = 0
    @State private var isCalibrated = false
    
    // Movement State
    @State private var currentZone: Zone = .center
    @State private var isMovementOnCooldown: Bool = false
    @State private var currentVector: (x: Int, y: Int) = (0, 0)
    
    private enum Zone {
        case center, left, right, up, down
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("Tempo: \(timeRemaining)s")
                .font(.title)
            
            // Calibration Status
            if !isCalibrated {
                Text("Calibrando...")
                    .font(.headline)
                    .foregroundColor(.yellow)
            }
            
            // Mostrar direção do movimento
            VStack(spacing: 10) {
                Text("Movimento:")
                    .font(.headline)
                
                Text(lastDirection.isEmpty ? "Centro" : lastDirection.uppercased())
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(getColorForDirection(lastDirection))
                    .animation(.easeInOut, value: lastDirection)
                
                Text("Vector: [\(currentVector.x), \(currentVector.y)]")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.2))
            )
            
            Text("Cliques: \(clickCount)")
                .font(.title2)
            
            Button(action: {
                clickCount += 1
                multiPeer.sendClick()
            }) {
                Text("CLIQUE!")
                    .font(.title)
                    .padding(50)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            startTimer()
            startMotionDetection()
        }
        .onDisappear {
            timer?.invalidate()
            stopMotionDetection()
        }
    }
    
    private func getColorForDirection(_ direction: String) -> Color {
        switch direction {
        case "cima":
            return .green
        case "baixo":
            return .red
        case "esquerda":
            return .blue
        case "direita":
            return .orange
        default:
            return .gray
        }
    }
    
    private func startTimer() {
        timeRemaining = 10
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                multiPeer.finalClickCount = clickCount
                onGameEnd()
            }
        }
    }
    
    private func startMotionDetection() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion não disponível")
            lastDirection = "Erro"
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + CALIBRATION_DELAY) {
            self.motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { motion, error in
                guard let motion = motion else { 
                    if let error = error {
                        print("❌ Erro no motion: \(error)")
                    }
                    return 
                }
                
                // PHASE 1: Calibration
                if !self.isCalibrated {
                    self.neutralPitch = motion.attitude.pitch
                    self.neutralYaw = motion.attitude.yaw
                    self.isCalibrated = true
                    print("✅ Calibrado - Pitch: \(self.neutralPitch), Yaw: \(self.neutralYaw)")
                    return
                }
                
                // PHASE 2: Detection
                let currentPitch = motion.attitude.pitch
                let currentYaw = motion.attitude.yaw
                
                self.detectMovement(pitch: currentPitch, yaw: currentYaw)
            }
        }
    }
    
    private func detectMovement(pitch: Double, yaw: Double) {
        let deltaPitch = pitch - neutralPitch
        var deltaYaw = yaw - neutralYaw
        
        // Wrap-around correction for yaw
        if deltaYaw > .pi { deltaYaw -= 2 * .pi }
        else if deltaYaw < -.pi { deltaYaw += 2 * .pi }
        
        let absPitch = abs(deltaPitch)
        let absYaw = abs(deltaYaw)
        
        let newZone: Zone
        
        // Determine Zone
        if absPitch < PITCH_THRESHOLD && absYaw < YAW_THRESHOLD {
            newZone = .center
        } else if absPitch > absYaw {
            newZone = deltaPitch > 0 ? .down : .up
        } else {
            newZone = deltaYaw > 0 ? .right : .left
        }
        
        // Trigger State Change
        if newZone != currentZone && !isMovementOnCooldown {
            isMovementOnCooldown = true
            onZoneChanged(from: currentZone, to: newZone)
            currentZone = newZone
            
            DispatchQueue.main.asyncAfter(deadline: .now() + MOVEMENT_DETECTION_DELAY) {
                isMovementOnCooldown = false
            }
        }
    }
    
    private func onZoneChanged(from oldZone: Zone, to newZone: Zone) {
        // Update vector
        updateVector(for: newZone)
        
        // Update direction text
        let direction: String
        switch newZone {
        case .left:
            direction = "esquerda"
        case .right:
            direction = "direita"
        case .up:
            direction = "cima"
        case .down:
            direction = "baixo"
        case .center:
            direction = ""
        }
        
        lastDirection = direction
        
        // Send to Apple TV
        if !direction.isEmpty {
            multiPeer.sendMove(direction: direction)
            print("🎯 \(direction.uppercased()) | Vector: [\(currentVector.x), \(currentVector.y)]")
        }
    }
    
    private func updateVector(for zone: Zone) {
        var x = 0
        var y = 0
        
        switch zone {
        case .left:   x = -1; y = 0
        case .right:  x = 1;  y = 0
        case .up:     x = 0;  y = 1
        case .down:   x = 0;  y = -1
        case .center: x = 0;  y = 0
        }
        
        currentVector = (x, y)
    }
    
    private func stopMotionDetection() {
        motionManager.stopDeviceMotionUpdates()
    }
}
