//
//  Models.swift
//  Georgetown Marketplace
//

import Foundation
import SwiftUI

enum ListingCategory: String, CaseIterable, Identifiable, Codable {
    case all = "All"
    case furniture = "Furniture"
    case electronics = "Electronics"
    case textbooks = "Textbooks"
    case clothing = "Clothing"
    case dorm = "Dorm Essentials"
    case tickets = "Tickets"
    case other = "Other"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .furniture: return "sofa"
        case .electronics: return "laptopcomputer"
        case .textbooks: return "book"
        case .clothing: return "tshirt"
        case .dorm: return "lamp.desk"
        case .tickets: return "ticket"
        case .other: return "tag"
        }
    }
}

enum ItemCondition: String, CaseIterable, Identifiable, Codable {
    case new = "New"
    case likeNew = "Like new"
    case good = "Good"
    case fair = "Fair"

    var id: String { rawValue }
}

enum CampusArea: String, CaseIterable, Identifiable, Codable {
    case mainCampus = "Main Campus"
    case villageA = "Village A"
    case villageC = "Village C"
    case nevils = "Nevils"
    case harbin = "Harbin"
    case copley = "Copley"
    case offCampus = "Off Campus"

    var id: String { rawValue }
}

enum AccountRole: String, Codable, CaseIterable, Identifiable {
    case buyer = "Buyer"
    case seller = "Seller"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .buyer: return "bag.fill"
        case .seller: return "tag.fill"
        }
    }
}

struct UserProfile: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var email: String
    var password: String
    var role: AccountRole
    var bio: String
    var location: CampusArea
    var avatarSymbol: String
    var avatarColorHex: String
    var joinedAt: Date
    var profileComplete: Bool

    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var memberSinceLabel: String {
        joinedAt.formatted(.dateTime.month(.abbreviated).year())
    }
}

enum ListingStatus: String, Codable {
    case active
    case sold
    case onLoan

    var label: String {
        switch self {
        case .active: return "Active"
        case .sold: return "Sold"
        case .onLoan: return "On loan"
        }
    }
}

struct Listing: Identifiable, Codable, Hashable {
    var id: String
    var sellerId: String
    var title: String
    var price: Double
    var category: ListingCategory
    var condition: ItemCondition
    var location: CampusArea
    var description: String
    var imageSymbol: String
    var imageColorHex: String
    var createdAt: Date
    var status: ListingStatus
    var savedBy: [String]
    var allowsLoan: Bool
    var loanPricePerWeek: Double?
    var loanUntil: Date?

    var priceLabel: String {
        Listing.money(price)
    }

    var askLabel: String {
        price == 0 ? "Free" : "Ask \(Listing.money(price))"
    }

    var loanLabel: String? {
        guard allowsLoan, let weekly = loanPricePerWeek else { return nil }
        return "\(Listing.money(weekly))/wk"
    }

    static func money(_ value: Double) -> String {
        if value == 0 { return "Free" }
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "$\(Int(value))"
        }
        return String(format: "$%.2f", value)
    }
}

enum OfferKind: String, Codable {
    case bid
    case loan
}

enum OfferStatus: String, Codable {
    case pending
    case accepted
    case declined
}

struct Offer: Identifiable, Codable, Hashable {
    var id: String
    var listingId: String
    var userId: String
    var kind: OfferKind
    var amount: Double
    var weeks: Int?
    var createdAt: Date
    var status: OfferStatus

    var amountLabel: String {
        Listing.money(amount)
    }
}

struct UserReview: Identifiable, Codable, Hashable {
    var id: String
    var reviewerId: String
    var revieweeId: String
    var listingId: String?
    var rating: Int // 1...5
    var comment: String
    var createdAt: Date
}

struct ChatMessage: Identifiable, Codable, Hashable {
    var id: String
    var conversationId: String
    var senderId: String
    var text: String
    var sentAt: Date
}

struct Conversation: Identifiable, Codable, Hashable {
    var id: String
    var listingId: String
    var buyerId: String
    var sellerId: String
    var updatedAt: Date
    var messages: [ChatMessage]
    /// Last time each participant opened the thread.
    var lastReadAtByUser: [String: Date]

    func otherUserId(currentUserId: String) -> String {
        currentUserId == buyerId ? sellerId : buyerId
    }

    var lastMessage: ChatMessage? {
        messages.sorted { $0.sentAt < $1.sentAt }.last
    }

    func unreadCount(for userId: String) -> Int {
        let lastRead = lastReadAtByUser[userId] ?? .distantPast
        return messages.filter { $0.senderId != userId && $0.sentAt > lastRead }.count
    }
}

enum MarketplaceTab: Hashable {
    case browse
    case inbox
    case sell
    case saved
    case you
}
