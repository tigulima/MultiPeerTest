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
    case buttonPressed(playerID: String)
    case buttonReleased(playerID: String)
    case playerConnected(playerID: String)
    case playerReady(playerID: String, isReady: Bool)
    case startGame
    case playerClick(playerID: String)
    case updateTotalPlayers(count: Int)
    case updateReadyPlayers(players: [String])
    case playerMove(playerID: String, direction: String)
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
    private var readyPlayers: Set<String> = []
    private var totalPlayers = 1
    
    // MARK: - Initialization
    
    override init() {
        // Criar peerID com nome do dispositivo
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        
        // Criar sessão
        self.session = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .none // Para menor latência
        )
        
        // Configurar playerID com o nome do dispositivo
        self.playerID = UIDevice.current.name
        
        super.init()
        
        session.delegate = self
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
        
        isHosting = true
        print("Apple TV começou a anunciar")
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
    
    func sendButtonPressed() {
        sendMessage(.buttonPressed(playerID: playerID))
    }
    
    func sendButtonReleased() {
        sendMessage(.buttonReleased(playerID: playerID))
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
        sendMessage(.playerReady(playerID: playerID, isReady: isReady))
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
        sendMessage(.playerClick(playerID: playerID))
    }
    
    func sendMove(direction: String) {
        sendMessage(.playerMove(playerID: playerID, direction: direction))
    }
    
    func resetLobby() {
        readyPlayers.removeAll()
        allPlayersReady = false
    }
    
    // Adicionar mensagem ao log do jogador específico
    private func addPlayerMessage(playerID: String, message: String) {
        if playerMessages[playerID] == nil {
            playerMessages[playerID] = []
        }
        playerMessages[playerID]?.append(message)
        // Manter apenas as últimas 20 mensagens por jogador
        if let count = playerMessages[playerID]?.count, count > 20 {
            playerMessages[playerID]?.removeFirst()
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
                print("Conectado: \(peerID.displayName)")
                self.receivedMessages.append("\(peerID.displayName) conectou!")
                self.isConnecting = false
                self.isSearching = false
                self.connectionError = false
                
                // Se for cliente (iPhone), avisar o servidor qual é o playerID
                if !self.isHosting {
                    self.sendMessage(.playerConnected(playerID: self.playerID))
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
            
            DispatchQueue.main.async {
                switch message {
                case .buttonPressed(let playerID):
                    self.receivedMessages.append("\(playerID) pressionou o botão!")
                    self.addPlayerMessage(playerID: playerID, message: "Pressionou o botão")
                    print("\(playerID) pressed")
                    
                case .buttonReleased(let playerID):
                    self.receivedMessages.append("\(playerID) soltou o botão")
                    self.addPlayerMessage(playerID: playerID, message: "Soltou o botão")
                    print("\(playerID) released")
                    
                case .playerConnected(let playerID):
                    self.receivedMessages.append("Player \(playerID) entrou no jogo!")
                    self.addPlayerMessage(playerID: playerID, message: "Conectado!")
                    print("\(playerID) joined")
                    
                    // Atualizar número do jogador baseado em quantos já estão conectados
                    if !self.isHosting {
                        // Assumir que somos o único jogador até receber atualização da TV
                        self.totalPlayers = 1
                        self.myPlayerNumber = 1
                        self.updateAllPlayersReady()
                    }
                    
                case .playerReady(let playerID, let isReady):
                    print("\(playerID) ready: \(isReady)")
                    if isReady {
                        self.readyPlayers.insert(playerID)
                        self.addPlayerMessage(playerID: playerID, message: "Pronto!")
                    } else {
                        self.readyPlayers.remove(playerID)
                        self.addPlayerMessage(playerID: playerID, message: "Não pronto")
                    }
                    self.updateAllPlayersReady()
                    
                case .startGame:
                    print("Game started")
                    
                case .playerClick(let playerID):
                    self.addPlayerMessage(playerID: playerID, message: "Clique")
                    print("\(playerID) clicked")
                    
                case .playerMove(let playerID, let direction):
                    self.receivedMessages.append("\(playerID) - \(direction)")
                    self.addPlayerMessage(playerID: playerID, message: direction)
                    print("\(playerID) moved \(direction)")
                    
                case .updateTotalPlayers(let count):
                    self.totalPlayers = count
                    self.updateAllPlayersReady()
                    
                case .updateReadyPlayers(let players):
                    self.readyPlayers = Set(players)
                    self.updateAllPlayersReady()
                }
            }
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

