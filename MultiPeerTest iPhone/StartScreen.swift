import SwiftUI

struct StartScreen: View {
    var onEnter: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("logo")
            
            Spacer()
            
            Button(action: onEnter) {
                Text("entrar!")
            }
            
            Spacer()
        }
    }
}

