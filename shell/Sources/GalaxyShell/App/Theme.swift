import SwiftUI

/// Default look: clean light (D13). Phase 2 replaces this with the theme
/// engine, where every value is customisable (D11).
enum Theme {
    static let barBackground = Color(white: 0.97).opacity(0.94)
    static let barText = Color(white: 0.12)
    static let barFontSize: CGFloat = 13

    static let panelBackground = Color(white: 0.995)
    static let panelText = Color(white: 0.10)
    static let panelSecondaryText = Color(white: 0.45)
    static let selection = Color(red: 0.36, green: 0.42, blue: 0.95).opacity(0.14)
    static let cornerRadius: CGFloat = 12
}
