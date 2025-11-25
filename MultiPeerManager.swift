//
//  MultiPeerManager.swift
//  MultiPeerTest
//
//  Created for rhythm game controller MVP
//

import MultipeerConnectivity
import SwiftUI
import Combine

// Mensagens trocadas entre os dispositivos
enum GameMessage: Codable {
    case playerConnected(playerID: String, playerName: String)
    case playerReady(playerID: String, playerName: String, isReady: Bool)
    case startGame
    case playerClick(playerID: String, playerName: String)
    case updateTotalPlayers(count: Int)
    case updateReadyPlayers(players: [String])
    case playerMove(playerID: String, playerName: String, direction: String)
    case assignPlayerNumber(playerID: String, playerNumber: Int)
}

class MultiPeerManager: NSObject, ObservableObject {
    private let serviceType = "rhythm-game"
    private var peerID: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    @Published var connectedPeers: [MCPeerID] = []
    @Published var receivedMessages: [String] = []
    @Published var playerMessages: [String: [String]] = [:] // Mensagens por jogador
    @Published var isHosting = false
    @Published var isConnected = false
    @Published var isSearching = false
    @Published var isConnecting = false
    @Published var connectionError = false
    @Published var myPlayerNumber = 1
    @Published var allPlayersReady = false
    @Published var finalClickCount = 0
    
    var playerID: String = ""
    var playerName: String = ""
    private var readyPlayers: Set<String> = []
    private var totalPlayers = 1
    
    // Mapeamento de playerID (UUID) para nome do dispositivo
    private var playerIDToName: [String: String] = [:]
    
    // Mapeamento de playerID (UUID) para peer displayName (para Apple TV)
    // Isso garante que sempre usamos a chave correta
    private var playerIDToPeerDisplayName: [String: String] = [:]
    
    // Mapeamento de playerID (UUID) para número do jogador
    private var playerIDToNumber: [String: Int] = [:]
    
    // Contador de jogadores (apenas para host/TV)
    private var nextPlayerNumber = 1
    
    // MARK: - Initialization
    
    override init() {
        // Gerar UUID único para este jogador
        self.playerID = UUID().uuidString
        
        // Guardar o nome do dispositivo
        self.playerName = UIDevice.current.name
        
        // Criar peerID com nome do dispositivo (para exibição na rede)
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        
        // Criar sessão
        self.session = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .none // Para menor latência
        )
        
        super.init()
        
        session.delegate = self
        
        // Registrar o próprio mapeamento
        playerIDToName[playerID] = playerName
        
        print("🆔 MultiPeerManager inicializado")
        print("   playerID (UUID): '\(playerID)'")
        print("   playerName: '\(playerName)'")
        print("   peerID.displayName: '\(peerID.displayName)'")
    }
    
    // MARK: - Host (Apple TV)
    
    func startHosting() {
        stopHosting()
        
        advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: nil,
            serviceType: serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        // Reset contador de jogadores
        nextPlayerNumber = 1
        playerIDToNumber.removeAll()
        playerIDToPeerDisplayName.removeAll()
        
        isHosting = true
        print("🍎 Apple TV começou a anunciar (contador reset)")
    }
    
    func stopHosting() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        isHosting = false
    }
    
    // MARK: - Client (iPhone)
    
    func startBrowsing() {
        stopBrowsing()
        
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        isSearching = true
        print("iPhone começou a procurar")
    }
    
    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
    }
    
    // MARK: - Messaging
    
    func sendMessage(_ message: GameMessage) {
        guard !connectedPeers.isEmpty else {
            print("Nenhum peer conectado")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: connectedPeers, with: .reliable)
            print("Mensagem enviada: \(message)")
        } catch {
            print("Erro ao enviar mensagem: \(error)")
        }
    }
    
    func sendReadyStatus(_ isReady: Bool) {
        // Atualiza estado local
        if isReady {
            readyPlayers.insert(playerID)
        } else {
            readyPlayers.remove(playerID)
        }
        
        // Calcula se todos estão prontos
        updateAllPlayersReady()
        
        // Envia para a TV
        sendMessage(.playerReady(playerID: playerID, playerName: playerName, isReady: isReady))
    }
    
    private func updateAllPlayersReady() {
        // Se estamos conectados, verifica se todos os jogadores estão prontos
        // totalPlayers é atualizado quando recebemos info da TV
        allPlayersReady = readyPlayers.count == totalPlayers && totalPlayers > 0
    }
    
    func sendStartGame() {
        sendMessage(.startGame)
    }
    
    func sendClick() {
        sendMessage(.playerClick(playerID: playerID, playerName: playerName))
    }
    
    func sendMove(direction: String) {
        sendMessage(.playerMove(playerID: playerID, playerName: playerName, direction: direction))
    }
    
    func resetLobby() {
        readyPlayers.removeAll()
        allPlayersReady = false
    }
    
    // Obter o número do jogador baseado no displayName do peer (para Apple TV)
    func getPlayerNumber(for peerDisplayName: String) -> Int? {
        // Encontrar o playerID correspondente ao displayName
        for (playerID, displayName) in playerIDToPeerDisplayName {
            if displayName == peerDisplayName {
                return playerIDToNumber[playerID]
            }
        }
        return nil
    }
    
    // Adicionar mensagem ao log do jogador específico
    private func addPlayerMessage(playerID: String, playerName: String, message: String) {
        print("📝 Adicionando mensagem")
        print("   playerID (UUID): '\(playerID)'")
        print("   playerName: '\(playerName)'")
        print("   message: '\(message)'")
        
        // Usar o mapeamento direto UUID → displayName
        let keyToUse: String
        if let mappedDisplayName = playerIDToPeerDisplayName[playerID] {
            keyToUse = mappedDisplayName
            print("   ✅ Encontrou mapeamento: '\(playerID)' → '\(mappedDisplayName)'")
        } else {
            // Fallback: procurar pelo playerName
            print("   ⚠️ Mapeamento não encontrado, usando playerName como chave")
            keyToUse = playerName
        }
        
        print("   🔑 Chave final: '\(keyToUse)'")
        
        // Usar a chave para exibição
        if playerMessages[keyToUse] == nil {
            playerMessages[keyToUse] = []
            print("   🆕 Criou novo array para '\(keyToUse)'")
        }
        playerMessages[keyToUse]?.append(message)
        
        // Manter apenas as últimas 20 mensagens por jogador
        if let count = playerMessages[keyToUse]?.count, count > 20 {
            playerMessages[keyToUse]?.removeFirst()
        }
        
        print("📊 Estado atual playerMessages:")
        for (key, msgs) in playerMessages {
            print("      '\(key)': \(msgs.count) mensagens")
        }
    }
    
    // MARK: - Disconnect
    
    func disconnect() {
        session.disconnect()
        stopHosting()
        stopBrowsing()
        connectedPeers.removeAll()
        receivedMessages.removeAll()
        isConnected = false
    }
}

// MARK: - MCSessionDelegate

extension MultiPeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
            self.isConnected = !session.connectedPeers.isEmpty
            
            switch state {
            case .connected:
                print("✅ Conectado: \(peerID.displayName)")
                print("🔍 Meu playerID: '\(self.playerID)' - Peer conectado: '\(peerID.displayName)'")
                self.receivedMessages.append("\(peerID.displayName) conectou!")
                self.isConnecting = false
                self.isSearching = false
                self.connectionError = false
                
                // Inicializar entrada no dicionário de mensagens (se for host)
                if self.isHosting && self.playerMessages[peerID.displayName] == nil {
                    self.playerMessages[peerID.displayName] = []
                    print("📦 Inicializou array de mensagens para '\(peerID.displayName)'")
                }
                
                // Se for cliente (iPhone), avisar o servidor qual é o playerID
                if !self.isHosting {
                    print("📨 Enviando playerConnected")
                    print("   playerID (UUID): '\(self.playerID)'")
                    print("   playerName: '\(self.playerName)'")
                    self.sendMessage(.playerConnected(playerID: self.playerID, playerName: self.playerName))
                }
                
            case .connecting:
                print("Conectando: \(peerID.displayName)")
                self.isConnecting = true
                
            case .notConnected:
                print("Desconectado: \(peerID.displayName)")
                self.receivedMessages.append("\(peerID.displayName) desconectou")
                self.isConnecting = false
                
            @unknown default:
                print("Estado desconhecido")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let message = try JSONDecoder().decode(GameMessage.self, from: data)
            
            DispatchQueue.main.async(execute: {
                switch message {
                case .playerConnected(let playerID, let playerName):
                    self.playerIDToName[playerID] = playerName
                    
                    // Encontrar qual peer enviou essa mensagem e mapear seu displayName
                    if let matchingPeer = self.connectedPeers.first(where: { $0.displayName == playerName }) {
                        self.playerIDToPeerDisplayName[playerID] = matchingPeer.displayName
                        print("🔗 Mapeamento criado: UUID '\(playerID)' → displayName '\(matchingPeer.displayName)'")
                    } else {
                        print("⚠️ AVISO: Peer '\(playerName)' não encontrado em connectedPeers!")
                    }
                    
                    // Se for host (Apple TV), atribuir número ao jogador e enviar de volta
                    if self.isHosting {
                        let playerNumber = self.nextPlayerNumber
                        self.playerIDToNumber[playerID] = playerNumber
                        self.nextPlayerNumber += 1
                        
                        print("🎮 Atribuindo Player \(playerNumber) para '\(playerName)'")
                        print("   UUID: \(playerID)")
                        print("   displayName: \(self.playerIDToPeerDisplayName[playerID] ?? "N/A")")
                        self.sendMessage(.assignPlayerNumber(playerID: playerID, playerNumber: playerNumber))
                        
                        print("📊 Mapeamento completo:")
                        print("   UUID → displayName: \(self.playerIDToPeerDisplayName)")
                        print("   UUID → Number: \(self.playerIDToNumber)")
                    }
                    
                    self.receivedMessages.append("Player \(playerName) entrou no jogo!")
                    self.addPlayerMessage(playerID: playerID, playerName: playerName, message: "Conectado!")
                    print("📥 Player conectado - playerID: '\(playerID)' - playerName: '\(playerName)'")
                    
                    // Atualizar número do jogador baseado em quantos já estão conectados
                    if !self.isHosting {
                        // Assumir que somos o único jogador até receber atualização da TV
                        self.totalPlayers = 1
                        self.myPlayerNumber = 1
                        self.updateAllPlayersReady()
                    }
                    
                case .playerReady(let playerID, let playerName, let isReady):
                    self.playerIDToName[playerID] = playerName
                    print("\(playerName) ready: \(isReady)")
                    if isReady {
                        self.readyPlayers.insert(playerID)
                        self.addPlayerMessage(playerID: playerID, playerName: playerName, message: "Pronto!")
                    } else {
                        self.readyPlayers.remove(playerID)
                        self.addPlayerMessage(playerID: playerID, playerName: playerName, message: "Não pronto")
                    }
                    self.updateAllPlayersReady()
                    
                case .startGame:
                    print("Game started")
                    
                case .playerClick(let playerID, let playerName):
                    self.playerIDToName[playerID] = playerName
                    self.addPlayerMessage(playerID: playerID, playerName: playerName, message: "Clique")
                    print("\(playerName) clicked")
                    
                case .playerMove(let playerID, let playerName, let direction):
                    self.playerIDToName[playerID] = playerName
                    
                    // Garantir que o mapeamento existe (caso a mensagem playerConnected tenha sido perdida)
                    if self.playerIDToPeerDisplayName[playerID] == nil {
                        if let matchingPeer = self.connectedPeers.first(where: { $0.displayName == playerName }) {
                            self.playerIDToPeerDisplayName[playerID] = matchingPeer.displayName
                            print("🔗 Mapeamento tardio criado: UUID '\(playerID)' → displayName '\(matchingPeer.displayName)'")
                        }
                    }
                    
                    self.receivedMessages.append("\(playerName) - \(direction)")
                    self.addPlayerMessage(playerID: playerID, playerName: playerName, message: direction)
                    
                case .updateTotalPlayers(let count):
                    self.totalPlayers = count
                    self.updateAllPlayersReady()
                    
                case .updateReadyPlayers(let players):
                    self.readyPlayers = Set(players)
                    self.updateAllPlayersReady()
                    
                case .assignPlayerNumber(let playerID, let playerNumber):
                    // Verificar se é para este jogador
                    if playerID == self.playerID {
                        self.myPlayerNumber = playerNumber
                        print("🎯 Recebi meu número de jogador: \(playerNumber)")
                    }
                }
            })
        } catch {
            print("Erro ao decodificar mensagem: \(error)")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Não usado neste MVP
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Não usado neste MVP
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Não usado neste MVP
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate (Apple TV)

extension MultiPeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Convite recebido de: \(peerID.displayName)")
        // Auto-aceitar (simplificado para MVP)
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Erro ao anunciar: \(error)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate (iPhone)

extension MultiPeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Peer encontrado: \(peerID.displayName)")
        
        // Auto-conectar ao primeiro peer encontrado (Apple TV)
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Peer perdido: \(peerID.displayName)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Erro ao procurar peers: \(error)")
        DispatchQueue.main.async {
            self.connectionError = true
            self.isSearching = false
        }
    }
}

