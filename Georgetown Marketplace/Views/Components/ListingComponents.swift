//
//  ListingComponents.swift
//  Georgetown Marketplace
//

import SwiftUI

struct ListingImagePlaceholder: View {
    let symbol: String
    let hex: String
    var height: CGFloat = 140
    var cornerRadius: CGFloat = AppTheme.imageCorner

    private var base: Color { Color(hex: hex) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    base.opacity(0.95),
                    AppTheme.hoyaNavy.opacity(0.55),
                    base.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft “photo” vignette
            RadialGradient(
                colors: [.clear, .black.opacity(0.22)],
                center: .center,
                startRadius: 20,
                endRadius: height
            )

            Image(systemName: symbol)
                .font(.system(size: max(28, height * 0.26), weight: .medium))
                .foregroundStyle(.white.opacity(0.95))
                .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// Facebook Marketplace–style listing tile.
struct ListingCard: View {
    let listing: Listing
    let isSaved: Bool
    var onToggleSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                ListingImagePlaceholder(
                    symbol: listing.imageSymbol,
                    hex: listing.imageColorHex,
                    height: 168,
                    cornerRadius: AppTheme.imageCorner
                )

                Button(action: onToggleSave) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isSaved ? AppTheme.hoyaNavy : .white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(isSaved ? Color.white : Color.black.opacity(0.45))
                        )
                }
                .buttonStyle(.plain)
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(listing.askLabel)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppTheme.price)
                    if let loan = listing.loanLabel {
                        Text("· \(loan)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.hoyaBlue)
                    }
                }

                Text(listing.title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 36, alignment: .topLeading)

                Text(listing.location.rawValue)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.hoyaGray)
                    .lineLimit(1)
            }
            .padding(.horizontal, 2)
        }
    }
}

/// FB-style category: icon in circle + label under.
struct CategoryCircle: View {
    let category: ListingCategory
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.hoyaNavy : AppTheme.searchFill)
                        .frame(width: 56, height: 56)
                    Image(systemName: category.systemImage)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : AppTheme.hoyaNavy)
                }
                Text(category == .all ? "All" : category.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? AppTheme.hoyaNavy : AppTheme.hoyaGray)
                    .lineLimit(1)
                    .frame(width: 72)
            }
        }
        .buttonStyle(.plain)
    }
}

struct MarketplaceSearchField: View {
    @Binding var text: String
    var placeholder: String = "Search Marketplace"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.hoyaGray)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.hoyaGrayLight)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.searchFill)
        .clipShape(Capsule())
    }
}

struct FilterPill: View {
    let title: String
    let systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(AppTheme.hoyaNavy)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(AppTheme.hoyaNavy.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct RelativeTimeLabel: View {
    let date: Date

    var body: some View {
        Text(date, style: .relative)
            .font(.caption)
            .foregroundStyle(AppTheme.hoyaGray)
    }
}

struct HoyaPrimaryButton: View {
    let title: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(enabled ? AppTheme.hoyaNavy : AppTheme.hoyaGrayLight)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}
