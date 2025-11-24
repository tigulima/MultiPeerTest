import SwiftUI
import CoreMotion

struct GameScreen: View {
    @ObservedObject var multiPeer: MultiPeerManager
    var onGameEnd: () -> Void
    
    @State private var clickCount = 0
    @State private var timeRemaining = 10
    @State private var timer: Timer?
    @State private var motionManager = CMMotionManager()
    @State private var lastDirection = ""
    @State private var lastMoveTime = Date()
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("Tempo: \(timeRemaining)s")
            
            Text("Cliques: \(clickCount)")
            
            Button(action: {
                clickCount += 1
                multiPeer.sendClick()
            }) {
                Text("CLIQUE!")
                    .padding(50)
            }
            
            Spacer()
        }
        .onAppear {
            startTimer()
            startMotionDetection()
        }
        .onDisappear {
            timer?.invalidate()
            stopMotionDetection()
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
        guard motionManager.isAccelerometerAvailable else {
            print("Acelerômetro não disponível")
            return
        }
        
        motionManager.accelerometerUpdateInterval = 0.1 // Atualiza a cada 100ms
        motionManager.startAccelerometerUpdates(to: .main) { data, error in
            guard let data = data, error == nil else { return }
            
            // Limitar envio de mensagens para não sobrecarregar (mínimo 0.3s entre envios)
            let now = Date()
            guard now.timeIntervalSince(lastMoveTime) > 0.3 else { return }
            
            let x = data.acceleration.x
            let y = data.acceleration.y
            let threshold = 0.5 // Sensibilidade do movimento
            
            var direction = ""
            
            // Detectar movimento mais forte
            if abs(x) > abs(y) {
                // Movimento horizontal
                if x > threshold {
                    direction = "direita"
                } else if x < -threshold {
                    direction = "esquerda"
                }
            } else {
                // Movimento vertical
                if y > threshold {
                    direction = "cima"
                } else if y < -threshold {
                    direction = "baixo"
                }
            }
            
            // Enviar apenas se detectou movimento e é diferente do último
            if !direction.isEmpty && direction != lastDirection {
                lastDirection = direction
                lastMoveTime = now
                multiPeer.sendMove(direction: direction)
            }
        }
    }
    
    private func stopMotionDetection() {
        motionManager.stopAccelerometerUpdates()
    }
}
