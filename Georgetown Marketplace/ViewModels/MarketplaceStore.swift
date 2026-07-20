//
//  MarketplaceStore.swift
//  Georgetown Marketplace
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class MarketplaceStore: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var listings: [Listing] = []
    @Published var conversations: [Conversation] = []
    @Published var offers: [Offer] = []
    @Published var reviews: [UserReview] = []
    @Published var users: [UserProfile] = SampleData.users

    @Published var selectedCategory: ListingCategory = .all
    @Published var searchText: String = ""
    @Published var selectedTab: MarketplaceTab = .browse
    @Published var showFreeOnly: Bool = false
    @Published var showBorrowableOnly: Bool = false
    @Published var sortMode: BrowseSort = .newest

    @Published var isAuthenticated: Bool = false
    @Published var authError: String?
    @Published var needsProfileSetup: Bool = false

    enum BrowseSort: String, CaseIterable, Identifiable {
        case newest = "Newest"
        case priceLow = "Price ↑"
        case priceHigh = "Price ↓"

        var id: String { rawValue }
    }

    private enum StorageKey {
        static let email = "gm.currentUserEmail"
        static let name = "gm.currentUserName"
        static let role = "gm.currentUserRole"
        static let password = "gm.currentUserPassword"
    }

    init() {
        listings = SampleData.listings
        offers = SampleData.offers
        reviews = SampleData.reviews
        restoreSession()
    }

    // MARK: - Auth

    func signUp(name: String, email: String, password: String, confirmPassword: String, role: AccountRole) {
        authError = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            authError = "Enter your name."
            return
        }
        guard Self.isValidEmail(trimmedEmail) else {
            authError = "Enter a valid email address."
            return
        }
        guard password.count >= 6 else {
            authError = "Password must be at least 6 characters."
            return
        }
        guard password == confirmPassword else {
            authError = "Passwords don't match."
            return
        }
        guard !users.contains(where: { $0.email == trimmedEmail }) else {
            authError = "An account with this email already exists. Log in instead."
            return
        }

        let selectedCollege = ThemeCenter.shared.college ?? CollegeCatalog.fallback
        let user = UserProfile(
            id: "u-\(UUID().uuidString.prefix(8))",
            name: trimmedName,
            email: trimmedEmail,
            password: password,
            role: role,
            college: selectedCollege,
            bio: "",
            location: .mainCampus,
            avatarSymbol: "person.crop.circle.fill",
            avatarColorHex: selectedCollege.primaryHex,
            joinedAt: Date(),
            profileComplete: false
        )
        users.append(user)
        currentUser = user
        completeSignIn(promptProfileSetup: true)
    }

    func logIn(email: String, password: String) {
        authError = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard let user = users.first(where: { $0.email == trimmedEmail }) else {
            authError = "No account found with this email. Create one first."
            return
        }
        guard user.password == password else {
            authError = "Incorrect password."
            return
        }

        currentUser = user
        if ThemeCenter.shared.college == nil {
            ThemeCenter.shared.select(user.college)
        } else if let college = ThemeCenter.shared.college,
                  let idx = users.firstIndex(where: { $0.id == user.id }) {
            users[idx].college = college
            currentUser = users[idx]
        }
        completeSignIn(promptProfileSetup: !user.profileComplete)
    }

    func signInAsDemo(role: AccountRole) {
        authError = nil
        let demo = role == .buyer ? SampleData.demoBuyer : SampleData.demoSeller
        if let idx = users.firstIndex(where: { $0.id == demo.id }) {
            currentUser = users[idx]
        } else {
            users.append(demo)
            currentUser = demo
        }
        if let college = ThemeCenter.shared.college {
            // Keep the college they just picked on the welcome flow.
            if let idx = users.firstIndex(where: { $0.id == currentUser?.id }) {
                users[idx].college = college
                currentUser = users[idx]
            }
        } else if let user = currentUser {
            ThemeCenter.shared.select(user.college)
        }
        completeSignIn(promptProfileSetup: false)
    }

    private func completeSignIn(promptProfileSetup: Bool) {
        guard let user = currentUser else { return }
        UserDefaults.standard.set(user.email, forKey: StorageKey.email)
        UserDefaults.standard.set(user.name, forKey: StorageKey.name)
        UserDefaults.standard.set(user.role.rawValue, forKey: StorageKey.role)
        UserDefaults.standard.set(user.password, forKey: StorageKey.password)
        isAuthenticated = true
        selectedTab = .browse
        needsProfileSetup = promptProfileSetup
        conversations = SampleData.seedConversations(currentUserId: user.id)
    }

    private func restoreSession() {
        guard let email = UserDefaults.standard.string(forKey: StorageKey.email) else { return }

        if let user = users.first(where: { $0.email == email }) {
            currentUser = user
            needsProfileSetup = !user.profileComplete
        } else if let name = UserDefaults.standard.string(forKey: StorageKey.name) {
            let role = UserDefaults.standard.string(forKey: StorageKey.role)
                .flatMap(AccountRole.init(rawValue:)) ?? .buyer
            let password = UserDefaults.standard.string(forKey: StorageKey.password) ?? ""
            let user = UserProfile(
                id: "u-\(UUID().uuidString.prefix(8))",
                name: name,
                email: email,
                password: password,
                role: role,
                college: ThemeCenter.shared.college ?? CollegeCatalog.fallback,
                bio: "",
                location: .mainCampus,
                avatarSymbol: "person.crop.circle.fill",
                avatarColorHex: (ThemeCenter.shared.college ?? CollegeCatalog.fallback).primaryHex,
                joinedAt: Date(),
                profileComplete: false
            )
            users.append(user)
            currentUser = user
            needsProfileSetup = true
        } else {
            return
        }

        isAuthenticated = true
        if let user = currentUser {
            if ThemeCenter.shared.college == nil {
                ThemeCenter.shared.college = user.college
            }
            conversations = SampleData.seedConversations(currentUserId: user.id)
        }
    }

    func signOut() {
        currentUser = nil
        isAuthenticated = false
        needsProfileSetup = false
        conversations = []
        UserDefaults.standard.removeObject(forKey: StorageKey.email)
        UserDefaults.standard.removeObject(forKey: StorageKey.name)
        UserDefaults.standard.removeObject(forKey: StorageKey.role)
        UserDefaults.standard.removeObject(forKey: StorageKey.password)
        selectedTab = .browse
    }

    var isSeller: Bool {
        currentUser?.role == .seller
    }

    static func isValidEmail(_ email: String) -> Bool {
        email.range(of: #"^[^@\s]+@[^@\s]+\.[^@\s]{2,}$"#, options: .regularExpression) != nil
    }

    // MARK: - Profile

    func updateProfile(
        name: String,
        bio: String,
        location: CampusArea,
        role: AccountRole,
        college: College,
        avatarColorHex: String
    ) {
        guard let uid = currentUser?.id,
              let idx = users.firstIndex(where: { $0.id == uid }) else { return }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        users[idx].name = trimmedName
        users[idx].bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        users[idx].location = location
        users[idx].role = role
        users[idx].college = college
        users[idx].avatarColorHex = avatarColorHex
        users[idx].profileComplete = true
        currentUser = users[idx]
        needsProfileSetup = false
        ThemeCenter.shared.select(college)

        UserDefaults.standard.set(users[idx].name, forKey: StorageKey.name)
        UserDefaults.standard.set(users[idx].role.rawValue, forKey: StorageKey.role)
    }

    func listings(for userId: String) -> [Listing] {
        listings.filter { $0.sellerId == userId }.sorted { $0.createdAt > $1.createdAt }
    }

    func activeListings(for userId: String) -> [Listing] {
        listings(for: userId).filter { $0.status == .active }
    }

    // MARK: - Reviews

    func reviews(for userId: String) -> [UserReview] {
        reviews.filter { $0.revieweeId == userId }.sorted { $0.createdAt > $1.createdAt }
    }

    func averageRating(for userId: String) -> Double? {
        let list = reviews(for: userId)
        guard !list.isEmpty else { return nil }
        return Double(list.map(\.rating).reduce(0, +)) / Double(list.count)
    }

    func canReview(userId: String) -> Bool {
        guard let uid = currentUser?.id, uid != userId else { return false }
        return !reviews.contains { $0.reviewerId == uid && $0.revieweeId == userId }
    }

    func leaveReview(for userId: String, rating: Int, comment: String, listingId: String? = nil) {
        guard let uid = currentUser?.id, uid != userId, (1...5).contains(rating) else { return }
        guard canReview(userId: userId) else { return }
        reviews.insert(
            UserReview(
                id: "r-\(UUID().uuidString.prefix(8))",
                reviewerId: uid,
                revieweeId: userId,
                listingId: listingId,
                rating: rating,
                comment: comment.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: Date()
            ),
            at: 0
        )
    }

    // MARK: - Listings

    var filteredListings: [Listing] {
        var result = listings
            .filter { $0.status == .active }
            .filter { selectedCategory == .all || $0.category == selectedCategory }
            .filter {
                searchText.isEmpty
                    || $0.title.localizedCaseInsensitiveContains(searchText)
                    || $0.description.localizedCaseInsensitiveContains(searchText)
                    || $0.location.rawValue.localizedCaseInsensitiveContains(searchText)
            }

        if showFreeOnly {
            result = result.filter { $0.price == 0 }
        }
        if showBorrowableOnly {
            result = result.filter { $0.allowsLoan }
        }

        switch sortMode {
        case .newest:
            return result.sorted { $0.createdAt > $1.createdAt }
        case .priceLow:
            return result.sorted { $0.price < $1.price }
        case .priceHigh:
            return result.sorted { $0.price > $1.price }
        }
    }

    func clearBrowseFilters() {
        searchText = ""
        selectedCategory = .all
        showFreeOnly = false
        showBorrowableOnly = false
        sortMode = .newest
    }

    var activeFilterCount: Int {
        var count = 0
        if showFreeOnly { count += 1 }
        if showBorrowableOnly { count += 1 }
        if selectedCategory != .all { count += 1 }
        if !searchText.isEmpty { count += 1 }
        if sortMode != .newest { count += 1 }
        return count
    }

    var savedListings: [Listing] {
        guard let uid = currentUser?.id else { return [] }
        return listings.filter { $0.savedBy.contains(uid) && $0.status == .active }
    }

    var myListings: [Listing] {
        guard let uid = currentUser?.id else { return [] }
        return listings(for: uid)
    }

    func listing(id: String) -> Listing? {
        listings.first { $0.id == id }
    }

    func user(id: String) -> UserProfile? {
        users.first { $0.id == id }
    }

    func toggleSave(_ listing: Listing) {
        guard let uid = currentUser?.id,
              let idx = listings.firstIndex(where: { $0.id == listing.id }) else { return }
        if listings[idx].savedBy.contains(uid) {
            listings[idx].savedBy.removeAll { $0 == uid }
        } else {
            listings[idx].savedBy.append(uid)
        }
    }

    func isSaved(_ listing: Listing) -> Bool {
        guard let uid = currentUser?.id else { return false }
        return listing.savedBy.contains(uid)
    }

    func createListing(
        title: String,
        price: Double,
        category: ListingCategory,
        condition: ItemCondition,
        location: CampusArea,
        description: String,
        allowsLoan: Bool,
        loanPricePerWeek: Double?
    ) {
        guard let uid = currentUser?.id else { return }
        let listing = Listing(
            id: "l-\(UUID().uuidString.prefix(8))",
            sellerId: uid,
            title: title,
            price: price,
            category: category == .all ? .other : category,
            condition: condition,
            location: location,
            description: description,
            imageSymbol: category.systemImage,
            imageColorHex: "041E42",
            createdAt: Date(),
            status: .active,
            savedBy: [],
            allowsLoan: allowsLoan,
            loanPricePerWeek: allowsLoan ? loanPricePerWeek : nil,
            loanUntil: nil
        )
        listings.insert(listing, at: 0)
        selectedTab = .browse
    }

    func markSold(_ listing: Listing) {
        setStatus(listing, to: .sold)
        declinePendingOffers(listingId: listing.id)
    }

    func markReturned(_ listing: Listing) {
        guard let idx = listings.firstIndex(where: { $0.id == listing.id }) else { return }
        listings[idx].status = .active
        listings[idx].loanUntil = nil
    }

    private func setStatus(_ listing: Listing, to status: ListingStatus) {
        guard let idx = listings.firstIndex(where: { $0.id == listing.id }) else { return }
        listings[idx].status = status
    }

    // MARK: - Bids & loans

    func bids(for listingId: String) -> [Offer] {
        offers
            .filter { $0.listingId == listingId && $0.kind == .bid && $0.status != .declined }
            .sorted { $0.amount > $1.amount }
    }

    func topBid(for listingId: String) -> Offer? {
        bids(for: listingId).first
    }

    func pendingOffers(for listingId: String) -> [Offer] {
        offers
            .filter { $0.listingId == listingId && $0.status == .pending }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func myOffer(on listingId: String, kind: OfferKind) -> Offer? {
        guard let uid = currentUser?.id else { return nil }
        return offers.first {
            $0.listingId == listingId && $0.userId == uid && $0.kind == kind && $0.status != .declined
        }
    }

    func placeBid(on listing: Listing, amount: Double) {
        guard let uid = currentUser?.id, uid != listing.sellerId, amount > 0 else { return }
        offers.removeAll { $0.listingId == listing.id && $0.userId == uid && $0.kind == .bid && $0.status == .pending }
        offers.append(
            Offer(
                id: "o-\(UUID().uuidString.prefix(8))",
                listingId: listing.id,
                userId: uid,
                kind: .bid,
                amount: amount,
                weeks: nil,
                createdAt: Date(),
                status: .pending
            )
        )
        if let convo = startOrGetConversation(for: listing) {
            sendMessage(
                conversationId: convo.id,
                text: "I placed a bid of \(Listing.money(amount)) on \"\(listing.title)\"."
            )
        }
    }

    func requestLoan(on listing: Listing, weeks: Int) {
        guard let uid = currentUser?.id,
              uid != listing.sellerId,
              listing.allowsLoan,
              let weekly = listing.loanPricePerWeek,
              weeks > 0 else { return }
        offers.removeAll { $0.listingId == listing.id && $0.userId == uid && $0.kind == .loan && $0.status == .pending }
        let total = weekly * Double(weeks)
        offers.append(
            Offer(
                id: "o-\(UUID().uuidString.prefix(8))",
                listingId: listing.id,
                userId: uid,
                kind: .loan,
                amount: total,
                weeks: weeks,
                createdAt: Date(),
                status: .pending
            )
        )
        if let convo = startOrGetConversation(for: listing) {
            sendMessage(
                conversationId: convo.id,
                text: "I'd like to borrow \"\(listing.title)\" for \(weeks) week\(weeks == 1 ? "" : "s") (\(Listing.money(total)))."
            )
        }
    }

    func buyAtAsk(_ listing: Listing) {
        guard let uid = currentUser?.id, uid != listing.sellerId else { return }
        setStatus(listing, to: .sold)
        declinePendingOffers(listingId: listing.id)

        if let convo = startOrGetConversation(for: listing) {
            sendMessage(
                conversationId: convo.id,
                text: "I'll take \"\(listing.title)\" at the asking price (\(listing.priceLabel)). When can we meet?"
            )
        }
    }

    func acceptOffer(_ offer: Offer) {
        guard let idx = offers.firstIndex(where: { $0.id == offer.id }),
              let listing = listing(id: offer.listingId) else { return }

        offers[idx].status = .accepted

        switch offer.kind {
        case .bid:
            setStatus(listing, to: .sold)
            declinePendingOffers(listingId: listing.id, except: offer.id)
        case .loan:
            guard let lidx = listings.firstIndex(where: { $0.id == listing.id }) else { return }
            listings[lidx].status = .onLoan
            listings[lidx].loanUntil = Date().addingTimeInterval(Double(offer.weeks ?? 1) * 7 * 24 * 3600)
            declinePendingOffers(listingId: listing.id, except: offer.id)
        }

        notifyOfferParty(offer, listing: listing, accepted: true)
    }

    func declineOffer(_ offer: Offer) {
        guard let idx = offers.firstIndex(where: { $0.id == offer.id }) else { return }
        offers[idx].status = .declined
        if let listing = listing(id: offer.listingId) {
            notifyOfferParty(offer, listing: listing, accepted: false)
        }
    }

    private func declinePendingOffers(listingId: String, except offerId: String? = nil) {
        for idx in offers.indices
        where offers[idx].listingId == listingId
            && offers[idx].status == .pending
            && offers[idx].id != offerId {
            offers[idx].status = .declined
        }
    }

    private func notifyOfferParty(_ offer: Offer, listing: Listing, accepted: Bool) {
        guard let uid = currentUser?.id, uid == listing.sellerId else { return }

        let convo: Conversation
        if let existing = conversations.first(where: {
            $0.listingId == listing.id && $0.buyerId == offer.userId
        }) {
            convo = existing
        } else {
            let new = Conversation(
                id: "c-\(UUID().uuidString.prefix(8))",
                listingId: listing.id,
                buyerId: offer.userId,
                sellerId: listing.sellerId,
                updatedAt: Date(),
                messages: [],
                lastReadAtByUser: [listing.sellerId: Date()]
            )
            conversations.insert(new, at: 0)
            convo = new
        }

        let verb = offer.kind == .bid ? "bid" : "loan request"
        let text = accepted
            ? "Your \(verb) of \(offer.amountLabel) on \"\(listing.title)\" was accepted! Let's figure out a meetup."
            : "Your \(verb) of \(offer.amountLabel) on \"\(listing.title)\" was declined."
        sendMessage(conversationId: convo.id, text: text)
    }

    // MARK: - Messaging

    var totalUnreadMessages: Int {
        guard let uid = currentUser?.id else { return 0 }
        return conversations.reduce(0) { $0 + $1.unreadCount(for: uid) }
    }

    func conversation(for listing: Listing) -> Conversation? {
        guard let uid = currentUser?.id else { return nil }
        return conversations.first {
            $0.listingId == listing.id && ($0.buyerId == uid || $0.sellerId == uid)
        }
    }

    @discardableResult
    func startOrGetConversation(for listing: Listing) -> Conversation? {
        guard let uid = currentUser?.id else { return nil }
        if listing.sellerId == uid { return nil }
        if let existing = conversation(for: listing) { return existing }

        let convo = Conversation(
            id: "c-\(UUID().uuidString.prefix(8))",
            listingId: listing.id,
            buyerId: uid,
            sellerId: listing.sellerId,
            updatedAt: Date(),
            messages: [],
            lastReadAtByUser: [uid: Date()]
        )
        conversations.insert(convo, at: 0)
        return convo
    }

    /// Open a chat about a seller's most recent active listing (from their profile).
    @discardableResult
    func startConversation(withSellerId sellerId: String) -> Conversation? {
        guard let uid = currentUser?.id, uid != sellerId else { return nil }
        if let listing = activeListings(for: sellerId).first {
            return startOrGetConversation(for: listing)
        }
        // Fall back to any listing they own so chat still works.
        if let listing = listings(for: sellerId).first {
            return startOrGetConversation(for: listing)
        }
        return nil
    }

    func sendMessage(conversationId: String, text: String) {
        guard let uid = currentUser?.id,
              let idx = conversations.firstIndex(where: { $0.id == conversationId }) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let message = ChatMessage(
            id: "m-\(UUID().uuidString.prefix(8))",
            conversationId: conversationId,
            senderId: uid,
            text: trimmed,
            sentAt: Date()
        )
        conversations[idx].messages.append(message)
        conversations[idx].updatedAt = Date()
        conversations[idx].lastReadAtByUser[uid] = Date()
        conversations.sort { $0.updatedAt > $1.updatedAt }
    }

    func markConversationRead(_ conversationId: String) {
        guard let uid = currentUser?.id,
              let idx = conversations.firstIndex(where: { $0.id == conversationId }) else { return }
        conversations[idx].lastReadAtByUser[uid] = Date()
    }

    var sortedConversations: [Conversation] {
        conversations.sorted { $0.updatedAt > $1.updatedAt }
    }
}
