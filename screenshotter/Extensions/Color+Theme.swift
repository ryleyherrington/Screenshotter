//
//  Color+Theme.swift
//  screenshotter
//

import SwiftUI

extension Color {
    // Teal Theme Colors
    static let tealPrimary = Color(red: 0.078, green: 0.722, blue: 0.651)      // #14B8A6 teal-500
    static let tealHover = Color(red: 0.051, green: 0.580, blue: 0.533)        // #0D9488 teal-600
    static let tealLight = Color(red: 0.369, green: 0.918, blue: 0.831)        // #5EEAD4 teal-300
    static let tealDark = Color(red: 0.039, green: 0.455, blue: 0.420)         // #0A7469 teal-700
}

// MARK: - Button Styles

struct TealButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(configuration.isPressed ? Color.tealDark : (isHovered ? Color.tealHover : Color.tealPrimary))
            )
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 6)
            .shadow(color: Color.tealPrimary.opacity(0.4), radius: 12, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

struct LargeTealButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(configuration.isPressed ? Color.tealDark : (isHovered ? Color.tealHover : Color.tealPrimary))
            )
            .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 8)
            .shadow(color: Color.tealPrimary.opacity(0.5), radius: 16, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - View Modifiers

struct SectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

extension View {
    func sectionHeader() -> some View {
        modifier(SectionHeaderStyle())
    }
}
