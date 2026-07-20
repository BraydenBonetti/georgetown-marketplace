//
//  AppTheme.swift
//  Georgetown Marketplace
//

import SwiftUI

enum AppTheme {
    /// Official-ish Hoya blue / gray
    static let hoyaNavy = Color(hex: "041E42")
    static let hoyaNavyDeep = Color(hex: "021530")
    static let hoyaBlue = Color(hex: "1A3A6B")
    static let hoyaGray = Color(hex: "8D817B")
    static let hoyaGrayLight = Color(hex: "B7B0AB")
    static let ink = Color(hex: "050505")
    static let surface = Color(hex: "F0F2F5") // FB Marketplace feed gray
    static let searchFill = Color(hex: "E4E6EB")
    static let cardBorder = Color.black.opacity(0.06)
    static let price = Color(hex: "041E42")
    static let success = Color(hex: "31A24C")

    static let listingCorner: CGFloat = 8
    static let imageCorner: CGFloat = 10
}

extension View {
    /// Flat FB-style listing tile (light border, white body).
    func marketplaceCard() -> some View {
        self
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.listingCorner, style: .continuous))
    }

    func hoyaNavChrome() -> some View {
        self
            .toolbarBackground(AppTheme.hoyaNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (4, 30, 66)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
