//
//  AvatarView.swift
//  Georgetown Marketplace
//

import SwiftUI

struct AvatarView: View {
    let user: UserProfile
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: user.avatarColorHex))
            Text(user.initials)
                .font(.system(size: size * 0.36, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

struct StarRatingView: View {
    let rating: Double
    var maxStars: Int = 5
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxStars, id: \.self) { star in
                Image(systemName: star <= Int(rating.rounded()) ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(star <= Int(rating.rounded()) ? Color(hex: "F5A623") : AppTheme.hoyaGrayLight)
            }
        }
    }
}

struct RatingSummary: View {
    let average: Double?
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            if let average {
                StarRatingView(rating: average)
                Text(String(format: "%.1f", average))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.hoyaNavy)
            } else {
                Text("New")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.hoyaGray)
            }
            Text("· \(count) review\(count == 1 ? "" : "s")")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.hoyaGray)
        }
    }
}
