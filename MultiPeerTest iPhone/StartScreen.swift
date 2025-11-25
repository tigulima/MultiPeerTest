import SwiftUI

struct StartScreen: View {
    var onEnter: () -> Void
    
    var body: some View {
        ZStack {
            Image("Background2")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            VStack {
                Spacer()
                
                Image("Logo")
                
                Spacer()
                
                Button {
                    onEnter()
                } label: {
                    Image("ButtonEntrar")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200)
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    StartScreen(onEnter: {})
}
