// Developed by Ben Dodson (ben@bendodson.com)

import SwiftUI
import MultipeerConnectivity

struct ContentView: View {
    @StateObject private var multiPeer = MultiPeerManager()
    
    // Cores para cada jogador
    private let playerColors: [Color] = [
        Color(red: 0.2, green: 0.5, blue: 0.8),    // Azul
        Color(red: 0.8, green: 0.3, blue: 0.4),    // Vermelho/Rosa
        Color(red: 0.3, green: 0.7, blue: 0.4),    // Verde
        Color(red: 0.9, green: 0.6, blue: 0.2)     // Laranja
    ]
    
    private func getPlayerColor(for index: Int) -> Color {
        playerColors[index % playerColors.count]
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 10) {
                Text("TESTE - MULTI 🐥🧀☕️")
                    .font(.title3)
                    .bold()
                    .padding()
                    .foregroundColor(.white)
                
                HStack(spacing: 20) {
                    // Status indicator
                    HStack {
                        Circle()
                            .fill(multiPeer.isHosting ? Color.green : Color.red)
                            .frame(width: 20, height: 20)
                        
                        Text(multiPeer.isHosting ? "Servidor Ativo" : "Servidor Inativo")
                            .font(.callout)
                            .foregroundColor(.white)
                    }
                    
                    // Connected players count
                    HStack {
                        Text("\(multiPeer.connectedPeers.count)/4 Jogadores")
                            .font(.callout)
                    }
                    .foregroundColor(.white)
                }
            }
            .padding(.top, 50)
            
            Divider()
                .background(Color.white.opacity(0.5))
                .padding(.horizontal, 100)
            
            // Messages area - Colunas por jogador
            if multiPeer.connectedPeers.isEmpty {
                VStack {
                    Text("Aguardando jogadores...")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 100)
                }
            } else {
                HStack(alignment: .top, spacing: 20) {
                    ForEach(Array(multiPeer.connectedPeers.enumerated()), id: \.element) { index, peer in
                        let playerColor = getPlayerColor(for: index)
                        let _ = print("🎮 === Renderizando coluna para peer [\(index)]: '\(peer.displayName)' ===")
                        
                        VStack(spacing: 15) {
                            // Nome do jogador
                            let playerNumber = multiPeer.getPlayerNumber(for: peer.displayName) ?? (index + 1)
                            
                            VStack(spacing: 5) {
                                Text("JOGADOR \(playerNumber)")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.white)
                                
                                Text(peer.displayName)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(playerColor.opacity(0.8))
                            )
                            
                            // Logs do jogador
                            ScrollView {
                                VStack(alignment: .leading, spacing: 10) {
                                    let _ = print("🔍 Buscando mensagens para peer: '\(peer.displayName)'")
                                    let _ = print("📋 Keys disponíveis: \(Array(multiPeer.playerMessages.keys))")
                                    
                                    if let messages = multiPeer.playerMessages[peer.displayName], !messages.isEmpty {
                                        ForEach(Array(messages.suffix(15).enumerated()), id: \.offset) { msgIndex, message in
                                            Text(message)
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                                                .padding(12)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(playerColor.opacity(0.3))
                                                )
                                        }
                                    } else {
                                        let _ = print("❌ Nenhuma mensagem para '\(peer.displayName)'")
                                        Text("Sem atividade")
                                            .font(.callout)
                                            .foregroundColor(.white.opacity(0.5))
                                            .padding()
                                    }
                                }
                                .padding(.horizontal, 10)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(playerColor.opacity(0.2))
                        )
                    }
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
            
            // Controls
            HStack {
                Button (multiPeer.isHosting ? "Parar Servidor" : "Iniciar Servidor") {
                    if multiPeer.isHosting {
                        multiPeer.stopHosting()
                    } else {
                        multiPeer.startHosting()
                    }
                }
                
                Button("Limpar Mensagens") {
                    multiPeer.receivedMessages.removeAll()
                    multiPeer.playerMessages.removeAll()
                }
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            multiPeer.startHosting()
        }
        .onDisappear {
            multiPeer.disconnect()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
