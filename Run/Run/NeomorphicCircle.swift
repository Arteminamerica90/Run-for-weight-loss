//
//  NeomorphicCircle.swift
//  Run
//
//  Created by Artem Menshikov on 04.01.2026.
//

import SwiftUI

struct NeomorphicCircle: View {
    let radius: CGFloat
    let offset: CGSize
    
    private var baseColor: Color {
        Color(hex: "C6FFFA")
    }
    
    private var lightColor: Color {
        Color(hex: "E0FFFD")
    }
    
    private var darkColor: Color {
        Color(hex: "A8E6E0")
    }
    
    var body: some View {
        ZStack {
            // Base gradient circle
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [lightColor, baseColor, darkColor]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: radius * 2, height: radius * 2)
            
            // Light highlight (top-left)
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.4), Color.clear]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: radius * 0.6
                    )
                )
                .frame(width: radius * 2, height: radius * 2)
                .blur(radius: radius * 0.3)
                .offset(x: -radius * 0.15, y: -radius * 0.15)
            
            // Dark shadow (bottom-right)
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [Color.clear, darkColor.opacity(0.5)]),
                        center: .bottomTrailing,
                        startRadius: 0,
                        endRadius: radius * 0.6
                    )
                )
                .frame(width: radius * 2, height: radius * 2)
                .blur(radius: radius * 0.3)
                .offset(x: radius * 0.15, y: radius * 0.15)
        }
        .shadow(color: darkColor.opacity(0.4), radius: radius * 0.3, x: radius * 0.2, y: radius * 0.2)
        .shadow(color: Color.white.opacity(0.5), radius: radius * 0.3, x: -radius * 0.2, y: -radius * 0.2)
        .offset(offset)
        .opacity(0.8)
    }
}

