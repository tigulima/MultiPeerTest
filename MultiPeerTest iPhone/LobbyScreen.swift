import SwiftUI

struct LobbyScreen: View {
    @ObservedObject var multiPeer: MultiPeerManager
    var onStartGame: () -> Void
    
    @State private var isReady = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Status da conexão
            Text(connectionStatusText())
            
            // Número do jogador (somente quando conectado)
            if multiPeer.isConnected {
                Text("Jogador \(multiPeer.myPlayerNumber)")
            }
            
            Spacer()
            
            // Botão "Estou pronto"
            if multiPeer.isConnected {
                Button(action: {
                    isReady.toggle()
                    multiPeer.sendReadyStatus(isReady)
                }) {
                    Text(isReady ? "Pronto!" : "Estou pronto")
                }
            }
            
            // Botão "Começar" (só aparece quando todos estão prontos)
            if multiPeer.isConnected && multiPeer.allPlayersReady {
                Button(action: onStartGame) {
                    Text("Começar")
                }
            }
            
            Spacer()
        }
        .onAppear {
            isReady = false
            multiPeer.resetLobby()
        }
    }
    
    private func connectionStatusText() -> String {
        if multiPeer.connectionError {
            return "Erro na conexão"
        }
        
        if !multiPeer.isConnected && !multiPeer.isSearching {
            return "Aguardando..."
        }
        
        if multiPeer.isSearching && !multiPeer.isConnected {
            return "Procurando Apple TV..."
        }
        
        if multiPeer.isConnecting {
            return "Conectando..."
        }
        
        if multiPeer.isConnected {
            return "Conectado!"
        }
        
        return "Procurando..."
    }
}

