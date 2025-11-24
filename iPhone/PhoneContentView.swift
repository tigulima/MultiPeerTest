//
//  PhoneContentView.swift
//  MultiPeerTest iPhone
//
//  Created for rhythm game controller MVP
//

import SwiftUI

struct PhoneContentView: View {
    @StateObject private var multiPeer = MultiPeerManager()
    @State private var playerNumber = "1"
    @State private var isButtonPressed = false
    @State private var showPlayerSelector = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Text("🎮 Controle do Jogo")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Player ID selector
                    Button(action: {
                        showPlayerSelector = true
                    }) {
                        HStack {
                            Text("Player \(playerNumber)")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Image(systemName: "chevron.down")
                                .font(.title3)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                    
                    // Connection status
                    HStack(spacing: 10) {
                        Circle()
                            .fill(multiPeer.isConnected ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        
                        Text(multiPeer.isConnected ? "Conectado à TV" : "Procurando TV...")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Main Button
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: isButtonPressed ? 
                                        [Color.green, Color.green.opacity(0.7)] :
                                        [Color.red, Color.orange]
                                    ),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 250, height: 250)
                            .shadow(color: isButtonPressed ? Color.green.opacity(0.6) : Color.red.opacity(0.6), 
                                    radius: isButtonPressed ? 40 : 20, 
                                    x: 0, 
                                    y: 10)
                            .scaleEffect(isButtonPressed ? 0.9 : 1.0)
                        
                        VStack(spacing: 10) {
                            Image(systemName: isButtonPressed ? "hand.tap.fill" : "hand.tap")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            
                            Text(isButtonPressed ? "PRESSED!" : "TAP ME")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isButtonPressed {
                                isButtonPressed = true
                                multiPeer.sendButtonPressed()
                                // Haptic feedback
                                let generator = UIImpactFeedbackGenerator(style: .heavy)
                                generator.impactOccurred()
                            }
                        }
                        .onEnded { _ in
                            isButtonPressed = false
                            multiPeer.sendButtonReleased()
                        }
                )
                
                Spacer()
                
                // Info and controls
                VStack(spacing: 20) {
                    if !multiPeer.isConnected {
                        Button(action: {
                            multiPeer.startBrowsing()
                        }) {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                Text("Buscar Apple TV")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.green)
                            )
                        }
                    }
                    
                    // Connected devices info
                    if multiPeer.isConnected {
                        VStack(spacing: 10) {
                            Text("📱 Dispositivos Conectados:")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                            
                            ForEach(multiPeer.connectedPeers, id: \.self) { peer in
                                Text(peer.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                }
                .padding(.bottom, 50)
            }
            .padding()
        }
        .sheet(isPresented: $showPlayerSelector) {
            PlayerSelectorView(selectedPlayer: $playerNumber, multiPeer: multiPeer)
        }
        .onAppear {
            multiPeer.playerID = "Player_\(playerNumber)"
            multiPeer.startBrowsing()
        }
        .onDisappear {
            multiPeer.disconnect()
        }
        .onChange(of: playerNumber) { newValue in
            multiPeer.playerID = "Player_\(newValue)"
        }
    }
}

// Player Selector Sheet
struct PlayerSelectorView: View {
    @Binding var selectedPlayer: String
    var multiPeer: MultiPeerManager
    @Environment(\.dismiss) var dismiss
    
    let players = ["1", "2", "3", "4"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.opacity(0.9)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Selecione seu número")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(.top, 30)
                    
                    ForEach(players, id: \.self) { player in
                        Button(action: {
                            selectedPlayer = player
                            multiPeer.playerID = "Player_\(player)"
                            dismiss()
                        }) {
                            HStack {
                                Text("Player \(player)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                if selectedPlayer == player {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                }
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(selectedPlayer == player ? 
                                          Color.blue.opacity(0.5) : 
                                          Color.white.opacity(0.1)
                                    )
                            )
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct PhoneContentView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneContentView()
    }
}

