// Developed by Ben Dodson (ben@bendodson.com)

import SwiftUI

struct ContentView: View {
    @StateObject private var multiPeer = MultiPeerManager()
    
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
            
            // Messages area
            HStack {
                ForEach(0..<multiPeer.connectedPeers.count, id: \.self) { index in
                    Text("Player \(index + 1)")
                    VStack(alignment: .leading, spacing: 15) {
                        if multiPeer.receivedMessages.isEmpty {
                            Text("Aguardando jogadores...")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 100)
                        } else {
                            ForEach(multiPeer.receivedMessages.suffix(10).reversed(), id: \.self) { message in
                                Text(message)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.white.opacity(0.15))
                                    )
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                    }
                    .background(.red)
                }
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
