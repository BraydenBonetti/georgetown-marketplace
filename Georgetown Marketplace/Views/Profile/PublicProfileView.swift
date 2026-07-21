//
//  PublicProfileView.swift
//  Georgetown Marketplace
//

import SwiftUI

struct PublicProfileView: View {
    @EnvironmentObject private var store: MarketplaceStore
    let userId: String

    @State private var showChat = false
    @State private var activeConversationId: String?
    @State private var showReviewSheet = false

    private var user: UserProfile? {
        store.user(id: userId)
    }

    private var isMe: Bool {
        store.currentUser?.id == userId
    }

    var body: some View {
        Group {
            if let user {
                ScrollView {
                    VStack(spacing: 14) {
                        header(user)

                        if !isMe {
                            actionRow(user)
                        }

                        listingsSection
                        reviewsSection(user)
                    }
                    .padding(12)
                    .padding(.bottom, 24)
                }
                .background(AppTheme.surface.ignoresSafeArea())
            } else {
                ContentUnavailableView("Profile not found", systemImage: "person.slash")
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .hoyaNavChrome()
        .navigationDestination(isPresented: $showChat) {
            if let id = activeConversationId,
               let convo = store.conversations.first(where: { $0.id == id }) {
                ChatThreadView(conversation: convo)
            }
        }
        .sheet(isPresented: $showReviewSheet) {
            LeaveReviewSheet(userId: userId)
                .presentationDetents([.height(360)])
        }
    }

    private func header(_ user: UserProfile) -> some View {
        VStack(spacing: 12) {
            AvatarView(user: user, size: 92)

            Text(user.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.hoyaNavy)

            RatingSummary(
                average: store.averageRating(for: user.id),
                count: store.reviews(for: user.id).count
            )

            if !user.bio.isEmpty {
                Text(user.bio)
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.ink.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            HStack(spacing: 16) {
                labelChip(user.location.rawValue, icon: "mappin")
                labelChip("Joined \(user.memberSinceLabel)", icon: "calendar")
            }
            .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func labelChip(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(AppTheme.hoyaNavy)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppTheme.surface)
        .clipShape(Capsule())
    }

    private func actionRow(_ user: UserProfile) -> some View {
        HStack(spacing: 10) {
            Button {
                if let convo = store.startConversation(withSellerId: user.id) {
                    activeConversationId = convo.id
                    showChat = true
                }
            } label: {
                Label("Message", systemImage: "bubble.left.fill")
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(AppTheme.hoyaNavy)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(store.activeListings(for: user.id).isEmpty && store.listings(for: user.id).isEmpty)

            if store.canReview(userId: user.id) {
                Button {
                    showReviewSheet = true
                } label: {
                    Label("Rate", systemImage: "star.fill")
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color.white)
                        .foregroundStyle(AppTheme.hoyaNavy)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(AppTheme.hoyaNavy, lineWidth: 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var listingsSection: some View {
        let items = store.activeListings(for: userId)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Listings")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.hoyaNavy)

            if items.isEmpty {
                Text("No active listings.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.hoyaGray)
            } else {
                ForEach(items) { listing in
                    NavigationLink {
                        ListingDetailView(listing: listing)
                    } label: {
                        HStack(spacing: 12) {
                            ListingPhotoView(listing: listing, height: 56, cornerRadius: 8)
                                .frame(width: 56)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(listing.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AppTheme.ink)
                                    .lineLimit(1)
                                Text(listing.askLabel)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(AppTheme.hoyaNavy)
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

    private func reviewsSection(_ user: UserProfile) -> some View {
        let list = store.reviews(for: user.id)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Reviews")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.hoyaNavy)

            if list.isEmpty {
                Text("No reviews yet.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.hoyaGray)
            } else {
                ForEach(list) { review in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            if let reviewer = store.user(id: review.reviewerId) {
                                AvatarView(user: reviewer, size: 28)
                                Text(reviewer.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppTheme.ink)
                            }
                            Spacer()
                            StarRatingView(rating: Double(review.rating), size: 11)
                        }
                        if !review.comment.isEmpty {
                            Text(review.comment)
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.ink.opacity(0.85))
                        }
                        Text(review.createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(AppTheme.hoyaGray)
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

private struct LeaveReviewSheet: View {
    @EnvironmentObject private var store: MarketplaceStore
    @Environment(\.dismiss) private var dismiss
    let userId: String

    @State private var rating = 5
    @State private var comment = ""

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(AppTheme.hoyaGrayLight)
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            Text("Leave a review")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.hoyaNavy)

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        rating = star
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.system(size: 28))
                            .foregroundStyle(star <= rating ? Color(hex: "F5A623") : AppTheme.hoyaGrayLight)
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField("How was the meetup?", text: $comment, axis: .vertical)
                .lineLimit(3...5)
                .padding(12)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.horizontal, 20)

            HoyaPrimaryButton(title: "Submit review") {
                store.leaveReview(for: userId, rating: rating, comment: comment)
                dismiss()
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
        .background(Color.white)
    }
}
