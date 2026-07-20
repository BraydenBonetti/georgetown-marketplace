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
    @EnvironmentObject private var store: MarketplaceStore
    let listing: Listing
    let isSaved: Bool
    var onToggleSave: () -> Void

    private var seller: UserProfile? {
        store.user(id: listing.sellerId)
    }

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

                if listing.allowsLoan {
                    Text("BORROW")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(0.6)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.hoyaBlue.opacity(0.92))
                        .clipShape(Capsule())
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(listing.askLabel)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppTheme.price)
                        .lineLimit(1)
                    if let loan = listing.loanLabel {
                        Text(loan)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.hoyaBlue)
                            .lineLimit(1)
                    }
                }

                Text(listing.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 34, alignment: .topLeading)

                HStack(spacing: 6) {
                    if let seller {
                        AvatarView(user: seller, size: 16)
                        Text(seller.name.components(separatedBy: " ").first ?? seller.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.hoyaNavy)
                            .lineLimit(1)
                    }
                    Text("·")
                        .foregroundStyle(AppTheme.hoyaGrayLight)
                    Text(listing.location.rawValue)
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.hoyaGray)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

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
                        .shadow(color: isSelected ? AppTheme.hoyaNavy.opacity(0.25) : .clear, radius: 6, y: 2)
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
    var isSelected: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : AppTheme.hoyaNavy)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? AppTheme.hoyaNavy : Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(AppTheme.hoyaNavy.opacity(isSelected ? 0 : 0.2), lineWidth: 1)
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
