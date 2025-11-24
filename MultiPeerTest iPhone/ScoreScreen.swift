import SwiftUI

struct ScoreScreen: View {
    @ObservedObject var multiPeer: MultiPeerManager
    var onBackToLobby: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Seus cliques:")
            
            Text("\(multiPeer.finalClickCount)")
            
            Spacer()
            
            Button(action: onBackToLobby) {
                Text("voltar para a sala")
            }
            
            Spacer()
        }
    }
}

