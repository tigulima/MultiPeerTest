import SwiftUI

struct LobbyScreen: View {
    @ObservedObject var multiPeer: MultiPeerManager
    var onStartGame: () -> Void
    
    @State private var isReady = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            Image("LobbyBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                
                // Status da conexão
                if shouldShowLoadingAnimation() {
                    // Animação de loading com Abacaxi
                    VStack {
                        Spacer()
                        Image("Abacaxi")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(rotationAngle))
                            .onAppear {
                                startLoadingAnimation()
                            }
                        Spacer()
                    }
                }
                
                // Número do jogador (somente quando conectado)
                if multiPeer.isConnected {
                    Text("JOGADOR \(multiPeer.myPlayerNumber)")
                        .font(Font.custom("LuckiestGuy-Regular", size: 50))
                        .foregroundStyle(LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom))
                        .shadow(color: .black, radius: 3)
                        .padding()
                }
                
                Spacer()
                
                // Botão "Estou pronto"
                if multiPeer.isConnected {
                    Button {
                        isReady.toggle()
                        multiPeer.sendReadyStatus(isReady)
                    } label: {
                        if isReady {
                            Image(systemName: "checkmark")
                                .font(Font.system(size: 60, weight: .bold))
                                .foregroundColor(Color.green)
                        } else {
                            Image("ButtonEstouPronto")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 220)
                        }
                    }
                }
                
                // Botão "Começar" (só aparece quando todos estão prontos)
                if multiPeer.isConnected && multiPeer.allPlayersReady {
                    Button(action: onStartGame) {
                        Image("ButtonComecar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200)
                    }
                }
                
                Spacer()
            }
            .onAppear {
                isReady = false
                multiPeer.resetLobby()
                print("🔵 Lobby carregado - Conectado: \(multiPeer.isConnected), Buscando: \(multiPeer.isSearching)")
            }
        }
    }
    
    private func shouldShowLoadingAnimation() -> Bool {
        // Mostra animação quando está aguardando, procurando ou conectando
        return (!multiPeer.isConnected && !multiPeer.isSearching) ||
               (multiPeer.isSearching && !multiPeer.isConnected) ||
               multiPeer.isConnecting
    }
    
    private func startLoadingAnimation() {
        // Animação que gira 360°, para por 0.5s, e repete
        withAnimation(.easeInOut(duration: 1.0)) {
            rotationAngle = 360
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Pausa de 0.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                rotationAngle = 0
                // Se ainda estiver no estado de loading, continua a animação
                if shouldShowLoadingAnimation() {
                    startLoadingAnimation()
                }
            }
        }
    }
    
    private func connectionStatusText() -> String {
        if multiPeer.connectionError {
            return "Erro na conexão"
        }
        
        if multiPeer.isConnected {
            return "Conectado!"
        }
        
        return ""
    }
}

