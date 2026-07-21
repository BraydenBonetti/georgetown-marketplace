//
//  ListingDetailView.swift
//  Georgetown Marketplace
//

import SwiftUI

struct ListingDetailView: View {
    @EnvironmentObject private var store: MarketplaceStore
    let listing: Listing

    @State private var showChat = false
    @State private var activeConversationId: String?
    @State private var showBidSheet = false
    @State private var showLoanSheet = false
    @State private var showBuyConfirm = false

    private var liveListing: Listing {
        store.listing(id: listing.id) ?? listing
    }

    private var seller: UserProfile? {
        store.user(id: liveListing.sellerId)
    }

    private var isMine: Bool {
        store.currentUser?.id == liveListing.sellerId
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    ListingHeroPhotos(listing: liveListing, height: 300)

                    if liveListing.status != .active {
                        Text(liveListing.status.label.uppercased())
                            .font(.system(size: 12, weight: .heavy))
                            .tracking(1.2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(liveListing.status == .sold ? Color(hex: "8B1E1E") : AppTheme.hoyaBlue)
                            .clipShape(Capsule())
                            .padding(12)
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(liveListing.title)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppTheme.ink)

                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                            Text(liveListing.location.rawValue)
                            Text("·")
                            RelativeTimeLabel(date: liveListing.createdAt)
                        }
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.hoyaGray)
                    }

                    marketPanel

                    HStack(spacing: 8) {
                        metaChip(liveListing.condition.rawValue)
                        metaChip(liveListing.category.rawValue)
                        if liveListing.allowsLoan {
                            metaChip("Borrowable")
                        }
                    }

                    if let until = liveListing.loanUntil, liveListing.status == .onLoan {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Due back \(until.formatted(date: .abbreviated, time: .omitted))")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.hoyaBlue)
                    }

                    Divider().overlay(AppTheme.searchFill)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.hoyaNavy)
                        Text(liveListing.description)
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.ink.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if isMine {
                        offerInbox
                    }

                    if let seller {
                        Divider().overlay(AppTheme.searchFill)

                        Text("Seller information")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.hoyaNavy)

                        NavigationLink {
                            PublicProfileView(userId: seller.id)
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(user: seller, size: 48)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(seller.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(AppTheme.ink)
                                    RatingSummary(
                                        average: store.averageRating(for: seller.id),
                                        count: store.reviews(for: seller.id).count
                                    )
                                    if !seller.bio.isEmpty {
                                        Text(seller.bio)
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.hoyaGray)
                                            .lineLimit(2)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.hoyaGrayLight)
                            }
                            .padding(12)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .padding(.bottom, 90)
            }
        }
        .background(Color.white)
        .navigationBarTitleDisplayMode(.inline)
        .hoyaNavChrome()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.toggleSave(liveListing)
                } label: {
                    Image(systemName: store.isSaved(liveListing) ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(.white)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .navigationDestination(isPresented: $showChat) {
            if let id = activeConversationId,
               let convo = store.conversations.first(where: { $0.id == id }) {
                ChatThreadView(conversation: convo)
            }
        }
        .sheet(isPresented: $showBidSheet) {
            BidSheet(listing: liveListing)
                .presentationDetents([.height(340)])
        }
        .sheet(isPresented: $showLoanSheet) {
            LoanSheet(listing: liveListing)
                .presentationDetents([.height(380)])
        }
        .alert("Buy at asking price?", isPresented: $showBuyConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Buy for \(liveListing.priceLabel)") {
                store.buyAtAsk(liveListing)
                if let convo = store.conversation(for: liveListing) {
                    activeConversationId = convo.id
                    showChat = true
                }
            }
        } message: {
            Text("This tells the seller you'll take \"\(liveListing.title)\" at \(liveListing.priceLabel) and opens a chat to arrange pickup.")
        }
    }

    // MARK: - Stock-style ask / bid panel

    private var marketPanel: some View {
        let top = store.topBid(for: liveListing.id)
        let bidCount = store.bids(for: liveListing.id).count

        return HStack(spacing: 0) {
            marketStat(title: "ASK", value: liveListing.priceLabel, emphasized: true)
            divider
            marketStat(title: "TOP BID", value: top.map(\.amountLabel) ?? "—")
            divider
            if let loan = liveListing.loanLabel {
                marketStat(title: "BORROW", value: loan)
            } else {
                marketStat(title: "BIDS", value: "\(bidCount)")
            }
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(AppTheme.hoyaNavy)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.15))
            .frame(width: 1, height: 36)
    }

    private func marketStat(title: String, value: String, emphasized: Bool = false) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.system(size: emphasized ? 20 : 17, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Seller's offer inbox

    @ViewBuilder
    private var offerInbox: some View {
        let pending = store.pendingOffers(for: liveListing.id)

        Divider().overlay(AppTheme.searchFill)

        VStack(alignment: .leading, spacing: 10) {
            Text("Offers")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.hoyaNavy)

            if pending.isEmpty {
                Text("No pending offers yet.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.hoyaGray)
            } else {
                ForEach(pending) { offer in
                    offerRow(offer)
                }
            }
        }
    }

    private func offerRow(_ offer: Offer) -> some View {
        HStack(spacing: 10) {
            Image(systemName: offer.kind == .bid ? "chart.line.uptrend.xyaxis" : "clock.arrow.circlepath")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.hoyaNavy)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(store.user(id: offer.userId)?.name ?? "User")
                    .font(.system(size: 14, weight: .semibold))
                Text(
                    offer.kind == .bid
                        ? "Bid \(offer.amountLabel)"
                        : "Borrow \(offer.weeks ?? 1) wk · \(offer.amountLabel)"
                )
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.hoyaGray)
            }

            Spacer()

            Button("Accept") {
                store.acceptOffer(offer)
            }
            .font(.system(size: 13, weight: .bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(AppTheme.hoyaNavy)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .buttonStyle(.plain)

            Button {
                store.declineOffer(offer)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.hoyaGray)
                    .padding(8)
                    .background(AppTheme.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Misc

    private func metaChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppTheme.hoyaNavy)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(AppTheme.surface)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            if isMine {
                sellerBottomBar
            } else {
                buyerBottomBar
            }
        }
    }

    @ViewBuilder
    private var sellerBottomBar: some View {
        Group {
            switch liveListing.status {
            case .active:
                HoyaPrimaryButton(title: "Mark as sold") {
                    store.markSold(liveListing)
                }
            case .onLoan:
                HoyaPrimaryButton(title: "Mark as returned") {
                    store.markReturned(liveListing)
                }
            case .sold:
                HoyaPrimaryButton(title: "Sold", enabled: false) {}
            }
        }
        .padding(12)
        .background(Color.white)
    }

    @ViewBuilder
    private var buyerBottomBar: some View {
        if liveListing.status == .active {
            VStack(spacing: 8) {
                if let myBid = store.myOffer(on: liveListing.id, kind: .bid), myBid.status == .pending {
                    Text("Your bid: \(myBid.amountLabel) · Pending")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.hoyaBlue)
                }
                if let myLoan = store.myOffer(on: liveListing.id, kind: .loan), myLoan.status == .pending {
                    Text("Borrow request: \(myLoan.weeks ?? 1) wk (\(myLoan.amountLabel)) · Pending")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.hoyaBlue)
                }

                HStack(spacing: 8) {
                    Button {
                        showBuyConfirm = true
                    } label: {
                        VStack(spacing: 1) {
                            Text("Buy")
                                .font(.system(size: 15, weight: .bold))
                            Text(liveListing.priceLabel)
                                .font(.system(size: 11, weight: .semibold))
                                .opacity(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.hoyaNavy)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        showBidSheet = true
                    } label: {
                        VStack(spacing: 1) {
                            Text("Bid")
                                .font(.system(size: 15, weight: .bold))
                            Text("name a price")
                                .font(.system(size: 11, weight: .semibold))
                                .opacity(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.hoyaBlue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    if liveListing.allowsLoan {
                        Button {
                            showLoanSheet = true
                        } label: {
                            VStack(spacing: 1) {
                                Text("Borrow")
                                    .font(.system(size: 15, weight: .bold))
                                Text(liveListing.loanLabel ?? "")
                                    .font(.system(size: 11, weight: .semibold))
                                    .opacity(0.8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .foregroundStyle(AppTheme.hoyaNavy)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(AppTheme.hoyaNavy, lineWidth: 1.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        if let convo = store.startOrGetConversation(for: liveListing) {
                            activeConversationId = convo.id
                            showChat = true
                        }
                    } label: {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 17))
                            .foregroundStyle(AppTheme.hoyaNavy)
                            .frame(width: 48)
                            .frame(maxHeight: .infinity)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color.white)
        } else {
            HStack {
                Text(liveListing.status == .sold ? "This item has been sold." : "This item is currently on loan.")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.hoyaGray)
                Spacer()
            }
            .padding(16)
            .background(Color.white)
        }
    }
}

// MARK: - Bid sheet

private struct BidSheet: View {
    @EnvironmentObject private var store: MarketplaceStore
    @Environment(\.dismiss) private var dismiss
    let listing: Listing

    @State private var bidText = ""

    private var topBid: Offer? {
        store.topBid(for: listing.id)
    }

    private var bidValue: Double? {
        Double(bidText.replacingOccurrences(of: "$", with: ""))
    }

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(AppTheme.hoyaGrayLight)
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            Text("Place a bid")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.hoyaNavy)

            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("ASK")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.hoyaGray)
                    Text(listing.priceLabel)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.hoyaNavy)
                }
                VStack(spacing: 2) {
                    Text("TOP BID")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppTheme.hoyaGray)
                    Text(topBid?.amountLabel ?? "—")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.hoyaNavy)
                }
            }

            HStack {
                Text("$")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.hoyaNavy)
                TextField("Your bid", text: $bidText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 22, weight: .bold))
            }
            .padding(14)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.horizontal, 20)

            HoyaPrimaryButton(
                title: "Submit bid",
                enabled: (bidValue ?? 0) > 0
            ) {
                if let value = bidValue {
                    store.placeBid(on: listing, amount: value)
                    dismiss()
                }
            }
            .padding(.horizontal, 20)

            Text("The seller can accept your bid, or someone can outbid you.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.hoyaGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer(minLength: 0)
        }
        .presentationDragIndicator(.hidden)
        .background(Color.white)
    }
}

// MARK: - Loan sheet

private struct LoanSheet: View {
    @EnvironmentObject private var store: MarketplaceStore
    @Environment(\.dismiss) private var dismiss
    let listing: Listing

    @State private var weeks = 1

    private var weekly: Double {
        listing.loanPricePerWeek ?? 0
    }

    private var total: Double {
        weekly * Double(weeks)
    }

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(AppTheme.hoyaGrayLight)
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            Text("Borrow this item")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.hoyaNavy)

            Text("\(Listing.money(weekly)) per week")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.hoyaGray)

            HStack(spacing: 20) {
                stepButton("minus") {
                    if weeks > 1 { weeks -= 1 }
                }

                VStack(spacing: 2) {
                    Text("\(weeks)")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(AppTheme.hoyaNavy)
                    Text(weeks == 1 ? "week" : "weeks")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.hoyaGray)
                }
                .frame(width: 90)

                stepButton("plus") {
                    if weeks < 12 { weeks += 1 }
                }
            }

            Text("Total: \(Listing.money(total))")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppTheme.hoyaNavy)

            HoyaPrimaryButton(title: "Request to borrow") {
                store.requestLoan(on: listing, weeks: weeks)
                dismiss()
            }
            .padding(.horizontal, 20)

            Text("The seller approves borrow requests. You return the item when time's up.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.hoyaGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer(minLength: 0)
        }
        .background(Color.white)
    }

    private func stepButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppTheme.hoyaNavy)
                .frame(width: 44, height: 44)
                .background(AppTheme.surface)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
