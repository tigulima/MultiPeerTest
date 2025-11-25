//
//  PhoneContentView.swift
//  MultiPeerTest iPhone
//
//  Created for rhythm game controller MVP
//

import SwiftUI
import MultipeerConnectivity

enum GameState {
    case start
    case selectTV
    case lobby
    case game
    case score
}

struct PhoneContentView: View {
    @StateObject private var multiPeer = MultiPeerManager()
    @State private var currentScreen: GameState = .start
    
    var body: some View {
        switch currentScreen {
        case .start:
            StartScreen(onEnter: {
                currentScreen = .selectTV
            })
            
        case .selectTV:
            TVSelectionScreen(
                multiPeer: multiPeer,
                onTVSelected: {
                    currentScreen = .lobby
                }
            )
            
        case .lobby:
            LobbyScreen(
                multiPeer: multiPeer,
                onStartGame: {
                    currentScreen = .game
                }
            )
            
        case .game:
            GameScreen(
                multiPeer: multiPeer,
                onGameEnd: {
                    currentScreen = .score
                }
            )
            
        case .score:
            ScoreScreen(
                multiPeer: multiPeer,
                onBackToLobby: {
                    currentScreen = .selectTV
                }
            )
        }
    }
}

struct PhoneContentView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneContentView()
    }
}
