import SwiftUI
import CoreMotion
import CoreHaptics
import Combine

// MARK: - Configuration
private enum MotionConfig {
    static let pitchThreshold: Double = 0.4
    static let yawThreshold: Double = 0.4
    static let calibrationDelay: TimeInterval = 0.5
    static let movementCooldown: TimeInterval = 0.05
    static let updateInterval: TimeInterval = 0.02
}

private enum GameConfig {
    static let initialTime: Int = 99999
}

// MARK: - Models
enum MovementZone: Equatable {
    case center, left, right, up, down
    
    var direction: String {
        switch self {
        case .left: return "left"
        case .right: return "right"
        case .up: return "up"
        case .down: return "down"
        case .center: return ""
        }
    }
    
    var displayName: String {
        direction.isEmpty ? "Centro" : direction.uppercased()
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .left: return .blue
        case .right: return .orange
        case .center: return .gray
        }
    }
    
    var vector: (x: Int, y: Int) {
        switch self {
        case .left: return (-1, 0)
        case .right: return (1, 0)
        case .up: return (0, 1)
        case .down: return (0, -1)
        case .center: return (0, 0)
        }
    }
}

// MARK: - Haptic Manager
class HapticManager: ObservableObject {
    private var engine: CHHapticEngine?
    
    init() {
        setupHapticEngine()
    }
    
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("❌ Haptic engine error: \(error.localizedDescription)")
        }
    }
    
    func playDirectionalFeedback(for zone: MovementZone) {
        guard zone != .center else {
            playLightImpact()
            return
        }
        
        playIntensePattern(for: zone)
    }
    
    func playClickFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred(intensity: 1.0)
    }
    
    private func playLightImpact() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func playIntensePattern(for zone: MovementZone) {
        guard let engine = engine else {
            fallbackHaptic(for: zone)
            return
        }
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
        
        let events: [CHHapticEvent] = [
            CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0),
            CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.1)
        ]
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            fallbackHaptic(for: zone)
        }
    }
    
    private func fallbackHaptic(for zone: MovementZone) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred(intensity: 0.8)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            impact.impactOccurred(intensity: 0.6)
        }
    }
}

// MARK: - Motion Detector
class MotionDetector: ObservableObject {
    @Published var currentZone: MovementZone = .center
    @Published var isCalibrated = false
    
    private let motionManager = CMMotionManager()
    private var neutralPitch: Double = 0
    private var neutralYaw: Double = 0
    private var isOnCooldown = false
    
    var onZoneChanged: ((MovementZone) -> Void)?
    
    func start() {
        guard motionManager.isDeviceMotionAvailable else {
            print("❌ Device motion não disponível")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = MotionConfig.updateInterval
        
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConfig.calibrationDelay) { [weak self] in
            self?.startUpdates()
        }
    }
    
    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func startUpdates() {
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else {
                if let error = error {
                    print("❌ Motion error: \(error)")
                }
                return
            }
            
            if !self.isCalibrated {
                self.calibrate(with: motion)
            } else {
                self.detectMovement(from: motion)
            }
        }
    }
    
    private func calibrate(with motion: CMDeviceMotion) {
        neutralPitch = motion.attitude.pitch
        neutralYaw = motion.attitude.yaw
        isCalibrated = true
        print("✅ Calibrado - Pitch: \(neutralPitch), Yaw: \(neutralYaw)")
    }
    
    private func detectMovement(from motion: CMDeviceMotion) {
        let deltaPitch = motion.attitude.pitch - neutralPitch
        var deltaYaw = motion.attitude.yaw - neutralYaw
        
        // Correção de wrap-around
        if deltaYaw > .pi { deltaYaw -= 2 * .pi }
        else if deltaYaw < -.pi { deltaYaw += 2 * .pi }
        
        let newZone = determineZone(deltaPitch: deltaPitch, deltaYaw: deltaYaw)
        
        if newZone != currentZone && !isOnCooldown {
            triggerZoneChange(to: newZone)
        }
    }
    
    private func determineZone(deltaPitch: Double, deltaYaw: Double) -> MovementZone {
        let absPitch = abs(deltaPitch)
        let absYaw = abs(deltaYaw)
        
        guard absPitch >= MotionConfig.pitchThreshold || absYaw >= MotionConfig.yawThreshold else {
            return .center
        }
        
        if absPitch > absYaw {
            return deltaPitch > 0 ? .up : .down
        } else {
            return deltaYaw > 0 ? .left : .right
        }
    }
    
    private func triggerZoneChange(to newZone: MovementZone) {
        isOnCooldown = true
        currentZone = newZone
        onZoneChanged?(newZone)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + MotionConfig.movementCooldown) { [weak self] in
            self?.isOnCooldown = false
        }
    }
}

// MARK: - Game Screen
struct GameScreen: View {
    @ObservedObject var multiPeer: MultiPeerManager
    var onGameEnd: () -> Void
    
    @StateObject private var motionDetector = MotionDetector()
    @StateObject private var hapticManager = HapticManager()
    
    @State private var clickCount = 0
    @State private var timeRemaining = GameConfig.initialTime
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            HeaderView(
                playerNumber: multiPeer.myPlayerNumber,
                timeRemaining: timeRemaining
            )
            
            CalibrationStatusView(isCalibrated: motionDetector.isCalibrated)
            
            MovementDisplayView(
                zone: motionDetector.currentZone,
                vector: motionDetector.currentZone.vector
            )
            
            ClickCounterView(clickCount: clickCount)
            
            ClickButton {
                handleClick()
            }
            
            Spacer()
        }
        .padding()
        .onAppear(perform: setupGame)
        .onDisappear(perform: cleanup)
    }
    
    // MARK: - Actions
    private func setupGame() {
        startTimer()
        startMotionDetection()
    }
    
    private func cleanup() {
        timer?.invalidate()
        motionDetector.stop()
    }
    
    private func handleClick() {
        clickCount += 1
        multiPeer.sendClick()
        hapticManager.playClickFeedback()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                endGame()
            }
        }
    }
    
    private func endGame() {
        timer?.invalidate()
        multiPeer.finalClickCount = clickCount
        onGameEnd()
    }
    
    private func startMotionDetection() {
        motionDetector.onZoneChanged = { [self] zone in
            handleZoneChange(zone)
        }
        motionDetector.start()
    }
    
    private func handleZoneChange(_ zone: MovementZone) {
        hapticManager.playDirectionalFeedback(for: zone)
        
        guard !zone.direction.isEmpty else { return }
        
        multiPeer.sendMove(direction: zone.direction)
        print("🎯 \(zone.displayName) | Vector: [\(zone.vector.x), \(zone.vector.y)]")
    }
}

// MARK: - Subviews
private struct HeaderView: View {
    let playerNumber: Int
    let timeRemaining: Int
    
    var body: some View {
        HStack {
            Text("Player \(playerNumber)")
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.horizontal)
            
            Spacer()
            
            Text("Tempo: \(timeRemaining)s")
                .font(.title)
        }
        .padding(.horizontal)
    }
}

private struct CalibrationStatusView: View {
    let isCalibrated: Bool
    
    var body: some View {
        if !isCalibrated {
            Text("Calibrando...")
                .font(.headline)
                .foregroundColor(.yellow)
        }
    }
}

private struct MovementDisplayView: View {
    let zone: MovementZone
    let vector: (x: Int, y: Int)
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Movimento:")
                .font(.headline)
            
            Text(zone.displayName)
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(zone.color)
                .animation(.easeInOut, value: zone)
            
            Text("Vector: [\(vector.x), \(vector.y)]")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.2))
        )
    }
}

private struct ClickCounterView: View {
    let clickCount: Int
    
    var body: some View {
        Text("Cliques: \(clickCount)")
            .font(.title2)
    }
}

private struct ClickButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("CLIQUE!")
                .font(.title)
                .padding(50)
        }
    }
}

