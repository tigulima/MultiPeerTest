# ⚡ Guia de Otimização de Latência

## 🎯 Objetivo

Para um jogo de ritmo, a latência entre pressionar o botão e a resposta visual/auditiva é crítica. Este guia ajuda a minimizar a latência no MultipeerConnectivity.

## 📊 Medindo a Latência

### 1. Adicionar Medição de Latência ao MultiPeerManager

```swift
class MultiPeerManager: NSObject, ObservableObject {
    @Published var averageLatency: TimeInterval = 0
    private var latencySamples: [TimeInterval] = []
    
    func measureLatency() {
        let timestamp = Date().timeIntervalSince1970
        let pingData = ["type": "ping", "timestamp": timestamp] as [String: Any]
        
        // Enviar ping
        if let data = try? JSONSerialization.data(withJSONObject: pingData) {
            try? session.send(data, toPeers: connectedPeers, with: .unreliable)
        }
    }
    
    func receivePong(sentTime: TimeInterval) {
        let latency = Date().timeIntervalSince1970 - sentTime
        latencySamples.append(latency)
        
        // Manter apenas últimas 100 amostras
        if latencySamples.count > 100 {
            latencySamples.removeFirst()
        }
        
        averageLatency = latencySamples.reduce(0, +) / Double(latencySamples.count)
    }
}
```

### 2. Visualizar Latência na Interface

```swift
struct LatencyIndicator: View {
    let latency: TimeInterval
    
    var body: some View {
        HStack {
            Circle()
                .fill(latencyColor)
                .frame(width: 10, height: 10)
            
            Text("\(Int(latency * 1000))ms")
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(8)
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
    }
    
    var latencyColor: Color {
        switch latency {
        case 0..<0.025:     return .green    // < 25ms - Excelente
        case 0.025..<0.050: return .yellow   // 25-50ms - Bom
        case 0.050..<0.100: return .orange   // 50-100ms - Aceitável
        default:            return .red      // > 100ms - Ruim
        }
    }
}
```

## 🚀 Técnicas de Otimização

### 1. Usar .unreliable para Inputs Contínuos

```swift
// Para botões que são pressionados frequentemente, use unreliable
func sendButtonState(pressed: Bool) {
    let message = ["pressed": pressed, "timestamp": Date().timeIntervalSince1970]
    
    if let data = try? JSONSerialization.data(withJSONObject: message) {
        // unreliable = menor latência, mas pode perder algumas mensagens
        try? session.send(data, toPeers: connectedPeers, with: .unreliable)
    }
}

// Para eventos críticos, use reliable
func sendScore(score: Int) {
    let message = ["score": score]
    
    if let data = try? JSONSerialization.data(withJSONObject: message) {
        // reliable = garante entrega, mas pode ter mais latência
        try? session.send(data, toPeers: connectedPeers, with: .reliable)
    }
}
```

### 2. Comprimir Dados

```swift
// Usar estruturas de dados menores
struct CompactInputMessage: Codable {
    let p: String  // playerID (usar códigos curtos)
    let s: UInt8   // state: 0=released, 1=pressed
    let t: UInt32  // timestamp (milliseconds desde início)
}

// Versus
struct VerboseInputMessage: Codable {
    let playerIdentifier: String
    let buttonState: String // "pressed" ou "released"
    let timestamp: TimeInterval
}

// CompactInputMessage é ~50% menor!
```

### 3. Batch Updates com Limite de Tempo

```swift
class OptimizedNetworkManager {
    private var pendingMessages: [Data] = []
    private var lastFlush = Date()
    private let maxBatchSize = 10
    private let maxBatchDelay: TimeInterval = 0.016 // ~60 FPS
    
    func queueMessage(_ data: Data) {
        pendingMessages.append(data)
        
        let shouldFlush = pendingMessages.count >= maxBatchSize ||
                         Date().timeIntervalSince(lastFlush) >= maxBatchDelay
        
        if shouldFlush {
            flushMessages()
        }
    }
    
    func flushMessages() {
        guard !pendingMessages.isEmpty else { return }
        
        // Combinar todas as mensagens em uma
        let combined = pendingMessages.reduce(Data()) { $0 + $1 }
        
        try? session.send(combined, toPeers: connectedPeers, with: .unreliable)
        
        pendingMessages.removeAll()
        lastFlush = Date()
    }
}
```

### 4. Priorizar Queue de Rede

```swift
class MultiPeerManager {
    // Use uma queue de alta prioridade para processamento de rede
    private let networkQueue = DispatchQueue(
        label: "com.rhythmgame.network",
        qos: .userInteractive,  // Maior prioridade
        attributes: []
    )
    
    func setupConnection() {
        connection.start(queue: networkQueue)
    }
}
```

### 5. Predição do Lado do Cliente

```swift
class InputPredictor {
    private var lastInputTime: Date?
    private var inputHistory: [Bool] = []
    
    func predictNextInput() -> Bool? {
        guard inputHistory.count >= 3 else { return nil }
        
        // Detectar padrões (ex: pressionando a cada 500ms)
        // Antecipar próximo input
        
        return nil // Implementar lógica de predição
    }
    
    func recordInput(_ pressed: Bool) {
        inputHistory.append(pressed)
        
        if inputHistory.count > 100 {
            inputHistory.removeFirst()
        }
    }
}

// No jogo, mostrar feedback imediato no cliente
// E confirmar com o servidor
struct OptimisticButton: View {
    @State private var localPressed = false
    @Binding var serverPressed: Bool
    
    var body: some View {
        Button(action: {}) {
            // ...
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    // Feedback imediato local
                    localPressed = true
                    
                    // Enviar ao servidor
                    sendInput(pressed: true)
                }
        )
        // Mostrar estado local enquanto aguarda servidor
        .foregroundColor(localPressed ? .green : .red)
    }
}
```

### 6. Usar Codable Personalizado para Velocidade

```swift
struct FastEncodableMessage {
    let playerID: UInt8
    let pressed: Bool
    let timestamp: UInt32
    
    // Codificação manual mais rápida que JSONEncoder
    func encode() -> Data {
        var data = Data()
        data.append(playerID)
        data.append(pressed ? 1 : 0)
        data.append(contentsOf: withUnsafeBytes(of: timestamp) { Array($0) })
        return data
    }
    
    static func decode(from data: Data) -> FastEncodableMessage? {
        guard data.count >= 6 else { return nil }
        
        let playerID = data[0]
        let pressed = data[1] == 1
        let timestamp = data[2..<6].withUnsafeBytes { $0.load(as: UInt32.self) }
        
        return FastEncodableMessage(playerID: playerID, pressed: pressed, timestamp: timestamp)
    }
}
```

### 7. Reduzir Alocações de Memória

```swift
class PooledMessageHandler {
    // Reutilizar objetos em vez de criar novos
    private var messagePool: [GameMessage] = []
    
    func getMessage() -> GameMessage {
        if let message = messagePool.popLast() {
            return message
        }
        return GameMessage()
    }
    
    func returnMessage(_ message: GameMessage) {
        messagePool.append(message)
    }
}
```

### 8. Desabilitar Criptografia (MVP apenas!)

```swift
// No MVP, para latência mínima, desabilitar criptografia
let session = MCSession(
    peer: peerID,
    securityIdentity: nil,
    encryptionPreference: .none  // Reduz latência em ~5-10ms
)

// ⚠️ ATENÇÃO: Para produção, use .required ou .optional
```

### 9. Otimizar Renderização da UI

```swift
struct OptimizedGameView: View {
    @State private var lastUpdate = Date()
    
    var body: some View {
        // Limitar atualizações a 60 FPS
        TimelineView(.animation(minimumInterval: 1/60)) { context in
            GameContentView()
        }
    }
}

// Usar shouldUpdateView para evitar re-renders desnecessários
struct GameContentView: View, Equatable {
    let gameState: GameState
    
    static func == (lhs: GameContentView, rhs: GameContentView) -> Bool {
        lhs.gameState.frame == rhs.gameState.frame
    }
    
    var body: some View {
        // ...
    }
}
```

### 10. Sincronização Baseada em Servidor

```swift
class ServerAuthoritativeGame {
    // Apple TV é a fonte da verdade
    var serverTime: TimeInterval = 0
    
    // Clientes (iPhones) enviam apenas inputs
    func sendInput(pressed: Bool) {
        let input = Input(
            playerID: playerID,
            pressed: pressed,
            clientTime: Date().timeIntervalSince1970
        )
        send(input)
    }
    
    // Servidor processa e envia estado do jogo
    func processInputs(_ inputs: [Input]) {
        for input in inputs {
            // Calcular latência
            let latency = serverTime - input.clientTime
            
            // Aplicar compensação de latência
            let adjustedTime = input.clientTime + latency
            
            // Processar input no tempo correto
            processInput(input, at: adjustedTime)
        }
    }
}
```

## 🔍 Debugging de Latência

### Adicionar Logs de Performance

```swift
class PerformanceMonitor {
    func measureBlock(_ name: String, block: () -> Void) {
        let start = CFAbsoluteTimeGetCurrent()
        block()
        let end = CFAbsoluteTimeGetCurrent()
        
        let elapsed = (end - start) * 1000 // ms
        print("⏱️ \(name): \(String(format: "%.2f", elapsed))ms")
    }
}

// Usar
performanceMonitor.measureBlock("Send Message") {
    multiPeer.sendMessage(message)
}
```

### Visualizar Latência em Tempo Real

```swift
struct LatencyGraph: View {
    let samples: [TimeInterval]
    
    var body: some View {
        Canvas { context, size in
            guard !samples.isEmpty else { return }
            
            let maxLatency = samples.max() ?? 0.1
            let xStep = size.width / CGFloat(samples.count - 1)
            
            var path = Path()
            
            for (index, sample) in samples.enumerated() {
                let x = CGFloat(index) * xStep
                let y = size.height - (CGFloat(sample / maxLatency) * size.height)
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            context.stroke(path, with: .color(.green), lineWidth: 2)
        }
        .frame(height: 100)
    }
}
```

## 📊 Benchmarks Típicos

### Latências Esperadas

| Cenário | Latência Típica | Comentário |
|---------|----------------|------------|
| Mesma sala (Wi-Fi 5GHz) | 15-25ms | Ideal |
| Mesma sala (Wi-Fi 2.4GHz) | 25-40ms | Bom |
| Casa diferente (mesma rede) | 40-60ms | Aceitável |
| Rede congestionada | 60-150ms | Problemático |
| Wi-Fi com interferência | >150ms | Injogável |

### Dicas para Reduzir Latência em Rede

1. **Use Wi-Fi 5GHz** em vez de 2.4GHz (menos interferência)
2. **Aproxime os dispositivos** do roteador
3. **Desligue outros dispositivos** que usam a rede
4. **Use QoS no roteador** para priorizar tráfego de jogo
5. **Evite obstáculos** entre dispositivos e roteador
6. **Considere Wi-Fi 6** para latência ainda menor

## 🎯 Metas de Latência

Para diferentes tipos de jogos de ritmo:

| Tipo de Jogo | Latência Máxima Aceitável |
|--------------|---------------------------|
| Casual | < 100ms |
| Normal | < 50ms |
| Expert | < 25ms |
| Professional | < 15ms |

## ⚡ Checklist de Otimização

- [ ] Usar `.unreliable` para inputs frequentes
- [ ] Usar `.reliable` apenas para eventos críticos
- [ ] Comprimir estruturas de dados
- [ ] Implementar batching de mensagens
- [ ] Usar queue de alta prioridade
- [ ] Minimizar alocações de memória
- [ ] Desabilitar criptografia (MVP)
- [ ] Implementar predição do lado do cliente
- [ ] Otimizar renderização (60 FPS máximo)
- [ ] Adicionar medição de latência
- [ ] Testar em Wi-Fi 5GHz
- [ ] Monitorar performance em tempo real

## 🔬 Ferramenta de Teste

```swift
struct LatencyTestView: View {
    @StateObject private var multiPeer = MultiPeerManager()
    @State private var pingCount = 0
    @State private var latencies: [TimeInterval] = []
    
    var body: some View {
        VStack {
            Text("Latência Média: \(averageLatency)ms")
                .font(.title)
            
            LatencyGraph(samples: latencies)
            
            Button("Testar Latência (10 pings)") {
                testLatency()
            }
            
            List(latencies.enumerated().map { ($0, $1) }, id: \.0) { index, latency in
                Text("Ping \(index + 1): \(Int(latency * 1000))ms")
            }
        }
    }
    
    var averageLatency: Int {
        guard !latencies.isEmpty else { return 0 }
        let avg = latencies.reduce(0, +) / Double(latencies.count)
        return Int(avg * 1000)
    }
    
    func testLatency() {
        latencies.removeAll()
        pingCount = 0
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            multiPeer.measureLatency()
            pingCount += 1
            
            if pingCount >= 10 {
                timer.invalidate()
            }
        }
    }
}
```

---

**Dica Final**: Sempre teste em dispositivos reais e na mesma configuração de rede que será usada no ambiente final!

