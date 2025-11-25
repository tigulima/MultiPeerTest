//
//  TVSelectionScreen.swift
//  MultiPeerTest iPhone
//
//  Created for selecting Apple TV to connect
//

import SwiftUI
import MultipeerConnectivity

struct TVSelectionScreen: View {
    @ObservedObject var multiPeer: MultiPeerManager
    var onTVSelected: () -> Void
    
    var body: some View {
        ZStack {
            Image("LobbyBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Selecione a sua Apple TV")
                    .font(Font.custom("LuckiestGuy-Regular", size: 24))
                    .foregroundStyle(LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom))
                    .shadow(color: .black, radius: 3)
                    .padding(.top, 100)
                
                if multiPeer.isSearching {
                    ProgressView("Procurando Apple TVs...")
                        .padding()
                }
                
                if multiPeer.connectedPeers.isEmpty && multiPeer.isSearching {
                    Text("Nenhuma Apple TV encontrada")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(multiPeer.connectedPeers, id: \.displayName) { peer in
                        Button(action: {
                            onTVSelected()
                        }) {
                            HStack {
                                Text(peer.displayName)
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                        }
                    }
                    .listStyle(.plain)
					.background(Color.white.opacity(0.4))
					.cornerRadius(10)
					.padding()
					.frame(maxWidth: 400)
                }
                
                Spacer()
            }
            .onAppear {
                if !multiPeer.isSearching {
                    multiPeer.startBrowsing()
                }
            }
        }
    }
}

#Preview {
	TVSelectionScreen(multiPeer: MultiPeerManager(), onTVSelected: {})
}

