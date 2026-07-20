//
//  AppTheme.swift
//  Georgetown Marketplace
//

import SwiftUI
import Combine

/// Observes the selected college and republishes colors so the UI can retheme live.
@MainActor
final class ThemeCenter: ObservableObject {
    static let shared = ThemeCenter()

    @Published var college: College? {
        didSet {
            if let college {
                UserDefaults.standard.set(college.id, forKey: StorageKey.collegeId)
            }
        }
    }

    var brand: BrandTheme {
        (college ?? CollegeCatalog.fallback).brand
    }

    private enum StorageKey {
        static let collegeId = "gm.selectedCollegeId"
    }

    init() {
        if let id = UserDefaults.standard.string(forKey: StorageKey.collegeId),
           let saved = CollegeCatalog.college(id: id) {
            college = saved
        } else if let legacy = UserDefaults.standard.string(forKey: "gm.selectedCollege") {
            // Migrate old enum-style keys if present.
            college = CollegeCatalog.all.first {
                $0.name.lowercased().contains(legacy.replacingOccurrences(of: "georgeWashington", with: "george washington").lowercased())
                    || $0.shortName.lowercased() == legacy.lowercased()
            }
        }
    }

    func select(_ college: College) {
        withAnimation(.easeInOut(duration: 0.35)) {
            self.college = college
        }
    }
}

enum AppTheme {
    private static var brand: BrandTheme { ThemeCenter.shared.brand }

    static var hoyaNavy: Color { brand.primary }
    static var hoyaNavyDeep: Color { brand.primaryDeep }
    static var hoyaBlue: Color { brand.secondary }
    static var hoyaGray: Color { brand.muted }
    static var hoyaGrayLight: Color { brand.mutedLight }
    static var ink: Color { brand.ink }
    static var surface: Color { brand.surface }
    static var searchFill: Color { brand.searchFill }
    static var cardBorder: Color { Color.black.opacity(0.06) }
    static var price: Color { brand.price }
    static var success: Color { brand.success }

    static let listingCorner: CGFloat = 8
    static let imageCorner: CGFloat = 10
}

extension View {
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
