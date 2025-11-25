//
//  StrokedTextComponent.swift
//  MultiPeerTest
//
//  Created by Thiago Imai on 25/11/25.
//

import SwiftUI

struct StrokedTextComponent: View {
    let text: String
    let strokeColor: Color
    let strokeWidth: CGFloat
    let fillColor: Color

    var body: some View {
        Text(text)
            .font(.largeTitle) // Or any desired font
            .foregroundColor(fillColor)
            .overlay(
                Text(text)
                    .font(.largeTitle) // Must match the base text's font
                    .foregroundColor(strokeColor)
                    .mask(
                        Text(text)
                            .font(.largeTitle) // Must match the base text's font
                    )
            )
    }
}
