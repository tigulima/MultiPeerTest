//
//  ButtonComponent.swift
//  MultiPeerTest
//
//  Created by Thiago Imai on 21/11/25.
//

import SwiftUI

struct ButtonComponent: View {
    var text: String
    var action: () -> Void = { }
    var size: CGFloat = 50
    var body: some View {
        VStack {
            Button {
                action()
            } label: {
                Text(text)
                    .font(Font.custom("LuckiestGuy-Regular", size: size))
                    .textCase(.uppercase)
                    .foregroundStyle(.white)
                    .padding(30)
                    .background(.red)
                    .border(Color.white, width: 10)
                    .cornerRadius(20)
                    .shadow(radius: 10)
            }
        }
    }
}

#Preview {
    ButtonComponent(text: "oi", action: { print("oi") })
}
