//
//  ProfileView.swift
//  Georgetown Marketplace
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: MarketplaceStore
    @State private var showEdit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if let user = store.currentUser {
                        VStack(spacing: 12) {
                            AvatarView(user: user, size: 88)

                            Text(user.name)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(AppTheme.hoyaNavy)

                            Text(user.email)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.hoyaGray)

                            RatingSummary(
                                average: store.averageRating(for: user.id),
                                count: store.reviews(for: user.id).count
                            )

                            if !user.bio.isEmpty {
                                Text(user.bio)
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppTheme.ink.opacity(0.85))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 12)
                            }

                            HStack(spacing: 8) {
                                chip(user.role.rawValue, icon: user.role.systemImage)
                                chip((ThemeCenter.shared.college ?? user.college).shortName, icon: "building.columns.fill")
                                chip(user.location.rawValue, icon: "mappin")
                            }

                            Button {
                                showEdit = true
                            } label: {
                                Text("Edit profile")
                                    .font(.system(size: 15, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(AppTheme.hoyaNavy)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        statsRow(user)

                        if store.isSeller {
                            listingsCard
                        }

                        reviewsCard(user)

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Local meetups only", systemImage: "mappin.and.ellipse")
                            Label("Buy, bid, or borrow on every listing", systemImage: "arrow.left.arrow.right")
                            Label("Not affiliated with Meta / Facebook", systemImage: "info.circle")
                        }
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.hoyaNavy)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        Button {
                            store.signOut()
                        } label: {
                            Text("Sign out")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color(hex: "8B1E1E"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
            }
            .background(AppTheme.surface.ignoresSafeArea())
            .navigationTitle("You")
            .navigationBarTitleDisplayMode(.inline)
            .hoyaNavChrome()
            .sheet(isPresented: $showEdit) {
                EditProfileView()
            }
        }
    }

    private func chip(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(AppTheme.hoyaNavy)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppTheme.surface)
        .clipShape(Capsule())
    }

    private func statsRow(_ user: UserProfile) -> some View {
        HStack(spacing: 0) {
            stat("Listings", value: "\(store.listings(for: user.id).count)")
            Divider().frame(height: 36)
            stat("Saved", value: "\(store.savedListings.count)")
            Divider().frame(height: 36)
            stat("Chats", value: "\(store.conversations.count)")
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func stat(_ title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.hoyaNavy)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.hoyaGray)
        }
        .frame(maxWidth: .infinity)
    }

    private var listingsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your listings")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.hoyaNavy)

            if store.myListings.isEmpty {
                Text("You haven't listed anything yet.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.hoyaGray)
                    .padding(.vertical, 8)
            } else {
                ForEach(store.myListings) { listing in
                    NavigationLink {
                        ListingDetailView(listing: listing)
                    } label: {
                        HStack(spacing: 12) {
                            ListingImagePlaceholder(
                                symbol: listing.imageSymbol,
                                hex: listing.imageColorHex,
                                height: 56,
                                cornerRadius: 8
                            )
                            .frame(width: 56)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(listing.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AppTheme.ink)
                                    .lineLimit(1)
                                Text(listing.status == .active ? listing.askLabel : listing.status.label)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(listing.status == .sold ? Color.red.opacity(0.8) : AppTheme.hoyaNavy)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AppTheme.hoyaGrayLight)
                        }
                        .padding(10)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func reviewsCard(_ user: UserProfile) -> some View {
        let list = store.reviews(for: user.id)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Reviews about you")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.hoyaNavy)

            if list.isEmpty {
                Text("No reviews yet — complete a meetup to get your first one.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.hoyaGray)
            } else {
                ForEach(list.prefix(5)) { review in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            if let reviewer = store.user(id: review.reviewerId) {
                                Text(reviewer.name)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            Spacer()
                            StarRatingView(rating: Double(review.rating), size: 11)
                        }
                        if !review.comment.isEmpty {
                            Text(review.comment)
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.ink.opacity(0.85))
                        }
                    }
                    .padding(10)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
