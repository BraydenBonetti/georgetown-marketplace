//
//  SampleData.swift
//  Georgetown Marketplace
//

import Foundation

enum SampleData {
    static let demoPassword = "demo1234"

    /// Loads bundled sample-listing photos by resource name (JPEG). Returns [] while
    /// the files don't exist yet, so those listings fall back to symbol placeholders.
    static func bundledPhotos(_ names: String...) -> [Data] {
        names.compactMap { name in
            let url = Bundle.main.url(forResource: name, withExtension: "jpg")
                ?? Bundle.main.url(forResource: name, withExtension: "jpg", subdirectory: "SamplePhotos")
                ?? Bundle.main.url(forResource: name, withExtension: "jpg", subdirectory: "Resources/SamplePhotos")
            return url.flatMap { try? Data(contentsOf: $0) }
        }
    }

    static let demoUser = UserProfile(
        id: "u-demo",
        name: "Demo Student",
        email: "demo@example.com",
        password: demoPassword,
        college: CollegeCatalog.fallback,
        bio: "Hunting for dorm essentials, clearing out what I don't use. Happy to meet on campus.",
        location: .mainCampus,
        avatarSymbol: "person.crop.circle.fill",
        avatarColorHex: "1A3A6B",
        joinedAt: Date().addingTimeInterval(-86400 * 40),
        profileComplete: true
    )

    static let users: [UserProfile] = [
        demoUser,
        UserProfile(
            id: "u-maya",
            name: "Maya Chen",
            email: "maya.chen@gmail.com",
            password: "password",
            college: CollegeCatalog.fallback,
            bio: "Neighborhood thrift queen. Fast replies, fair prices, easy meetups.",
            location: .harbin,
            avatarSymbol: "person.crop.circle.fill",
            avatarColorHex: "6B4F3A",
            joinedAt: Date().addingTimeInterval(-86400 * 200),
            profileComplete: true
        ),
        UserProfile(
            id: "u-jordan",
            name: "Jordan Lee",
            email: "jordanlee@outlook.com",
            password: "password",
            college: CollegeCatalog.fallback,
            bio: "Textbooks + tech. Prefer Leavey or library pickups.",
            location: .mainCampus,
            avatarSymbol: "person.crop.circle.fill",
            avatarColorHex: "2F2F2F",
            joinedAt: Date().addingTimeInterval(-86400 * 90),
            profileComplete: true
        ),
        UserProfile(
            id: "u-sam",
            name: "Sam Ortiz",
            email: "sam.ortiz@yahoo.com",
            password: "password",
            college: CollegeCatalog.fallback,
            bio: "Moving out — everything must go this week.",
            location: .offCampus,
            avatarSymbol: "person.crop.circle.fill",
            avatarColorHex: "8B1E1E",
            joinedAt: Date().addingTimeInterval(-86400 * 30),
            profileComplete: true
        )
    ]

    static let listings: [Listing] = [
        Listing(
            id: "l1", sellerId: "u-maya", title: "IKEA desk + chair", price: 45,
            category: .furniture, condition: .good, location: .harbin,
            description: "Solid desk from last year. Chair included. Pickup from Harbin lobby.",
            imageSymbol: "desk", imageColorHex: "4A6FA5",
            createdAt: Date().addingTimeInterval(-3600 * 5), status: .active, savedBy: [],
            allowsLoan: false, loanPricePerWeek: nil, loanUntil: nil,
            photosData: SampleData.bundledPhotos("sample-desk")
        ),
        Listing(
            id: "l2", sellerId: "u-jordan", title: "MacBook Air M1 charger", price: 25,
            category: .electronics, condition: .likeNew, location: .mainCampus,
            description: "Original Apple 30W USB-C charger. Works perfectly.",
            imageSymbol: "cable.connector", imageColorHex: "2F2F2F",
            createdAt: Date().addingTimeInterval(-3600 * 12), status: .active,
            savedBy: ["u-demo"], allowsLoan: true, loanPricePerWeek: 4, loanUntil: nil,
            photosData: SampleData.bundledPhotos("sample-charger")
        ),
        Listing(
            id: "l3", sellerId: "u-demo", title: "Calc III textbook (Stewart)", price: 30,
            category: .textbooks, condition: .good, location: .copley,
            description: "Highlights in a few chapters. No missing pages. Buy it, or borrow it for the semester.",
            imageSymbol: "book.closed", imageColorHex: "6B4F3A",
            createdAt: Date().addingTimeInterval(-3600 * 28), status: .active, savedBy: [],
            allowsLoan: true, loanPricePerWeek: 5, loanUntil: nil,
            photosData: SampleData.bundledPhotos("sample-textbook")
        ),
        Listing(
            id: "l4", sellerId: "u-maya", title: "Mini fridge", price: 60,
            category: .dorm, condition: .good, location: .villageA,
            description: "Quiet mini fridge. Cleaned out. Perfect for a dorm or small room.",
            imageSymbol: "refrigerator", imageColorHex: "5B7C99",
            createdAt: Date().addingTimeInterval(-3600 * 48), status: .active, savedBy: [],
            allowsLoan: true, loanPricePerWeek: 10, loanUntil: nil,
            photosData: SampleData.bundledPhotos("sample-fridge")
        ),
        Listing(
            id: "l5", sellerId: "u-jordan", title: "Navy hoodie — L", price: 20,
            category: .clothing, condition: .likeNew, location: .mainCampus,
            description: "Worn twice. Size L. Smoke-free apartment.",
            imageSymbol: "tshirt", imageColorHex: "041E42",
            createdAt: Date().addingTimeInterval(-3600 * 8), status: .active, savedBy: [],
            allowsLoan: false, loanPricePerWeek: nil, loanUntil: nil,
            photosData: SampleData.bundledPhotos("sample-hoodie")
        ),
        Listing(
            id: "l6", sellerId: "u-demo", title: "Desk study lamp", price: 15,
            category: .dorm, condition: .good, location: .nevils,
            description: "Clip lamp + soft lamp. Great for late nights.",
            imageSymbol: "lamp.desk", imageColorHex: "C4A35A",
            createdAt: Date().addingTimeInterval(-3600 * 72), status: .active, savedBy: [],
            allowsLoan: true, loanPricePerWeek: 3, loanUntil: nil,
            photosData: SampleData.bundledPhotos("sample-lamp")
        ),
        Listing(
            id: "l7", sellerId: "u-maya", title: "Free — closet hangers", price: 0,
            category: .dorm, condition: .good, location: .harbin,
            description: "Bunch of plastic hangers. Free if you pick up today.",
            imageSymbol: "hanger", imageColorHex: "8A8A8A",
            createdAt: Date().addingTimeInterval(-3600 * 3), status: .active, savedBy: [],
            allowsLoan: false, loanPricePerWeek: nil, loanUntil: nil,
            photosData: SampleData.bundledPhotos("sample-hangers")
        ),
        Listing(
            id: "l8", sellerId: "u-jordan", title: "AirPods Pro (2nd gen)", price: 120,
            category: .electronics, condition: .likeNew, location: .villageC,
            description: "Case included, lightly used. No scratches.",
            imageSymbol: "airpods.pro", imageColorHex: "1A1A1A",
            createdAt: Date().addingTimeInterval(-3600 * 20), status: .active,
            savedBy: ["u-demo"], allowsLoan: false, loanPricePerWeek: nil, loanUntil: nil,
            photosData: SampleData.bundledPhotos("sample-airpods")
        ),
        Listing(
            id: "l9", sellerId: "u-sam", title: "Basketball tickets (pair)", price: 40,
            category: .tickets, condition: .new, location: .mainCampus,
            description: "Two seats together. Transfer via Ticketmaster.",
            imageSymbol: "ticket", imageColorHex: "8B1E1E",
            createdAt: Date().addingTimeInterval(-3600 * 6), status: .active, savedBy: [],
            allowsLoan: false, loanPricePerWeek: nil, loanUntil: nil,
            photosData: SampleData.bundledPhotos("sample-tickets")
        )
    ]

    static let offers: [Offer] = [
        Offer(id: "o1", listingId: "l3", userId: "u-jordan", kind: .bid, amount: 24, weeks: nil,
              createdAt: Date().addingTimeInterval(-3600 * 2), status: .pending),
        Offer(id: "o2", listingId: "l3", userId: "u-maya", kind: .bid, amount: 26, weeks: nil,
              createdAt: Date().addingTimeInterval(-3600), status: .pending),
        Offer(id: "o3", listingId: "l6", userId: "u-sam", kind: .loan, amount: 6, weeks: 2,
              createdAt: Date().addingTimeInterval(-1800), status: .pending),
        Offer(id: "o4", listingId: "l1", userId: "u-demo", kind: .bid, amount: 38, weeks: nil,
              createdAt: Date().addingTimeInterval(-900), status: .pending)
    ]

    static let reviews: [UserReview] = [
        UserReview(
            id: "r1", reviewerId: "u-jordan", revieweeId: "u-maya", listingId: "l4",
            rating: 5, comment: "Super easy meetup. Fridge was spotless.",
            createdAt: Date().addingTimeInterval(-86400 * 10)
        ),
        UserReview(
            id: "r2", reviewerId: "u-sam", revieweeId: "u-maya", listingId: nil,
            rating: 5, comment: "Honest descriptions and quick replies.",
            createdAt: Date().addingTimeInterval(-86400 * 20)
        ),
        UserReview(
            id: "r3", reviewerId: "u-maya", revieweeId: "u-jordan", listingId: "l5",
            rating: 4, comment: "Hoodie as described. Slightly late but cool.",
            createdAt: Date().addingTimeInterval(-86400 * 5)
        ),
        UserReview(
            id: "r4", reviewerId: "u-demo", revieweeId: "u-jordan", listingId: "l2",
            rating: 5, comment: "Charger works great. Would buy again.",
            createdAt: Date().addingTimeInterval(-86400 * 2)
        )
    ]

    static let quickReplies = [
        "Is this still available?",
        "Can you do a lower price?",
        "Where can we meet?",
        "I'm interested — when works for you?"
    ]

    static func seedConversations(currentUserId: String) -> [Conversation] {
        let now = Date()
        var seeded: [Conversation] = []

        // A chat where the current user is buying (someone else's listing).
        if let listing = listings.first(where: { $0.sellerId != currentUserId }) {
            let convoId = "c1"
            seeded.append(
                Conversation(
                    id: convoId,
                    listingId: listing.id,
                    buyerId: currentUserId,
                    sellerId: listing.sellerId,
                    updatedAt: now.addingTimeInterval(-1800),
                    messages: [
                        ChatMessage(
                            id: "m1", conversationId: convoId, senderId: currentUserId,
                            text: "Hey — is this still available?",
                            sentAt: now.addingTimeInterval(-3600)
                        ),
                        ChatMessage(
                            id: "m2", conversationId: convoId, senderId: listing.sellerId,
                            text: "Yep! Can meet at the library tomorrow after 3.",
                            sentAt: now.addingTimeInterval(-1800)
                        )
                    ],
                    lastReadAtByUser: [
                        currentUserId: now.addingTimeInterval(-4000),
                        listing.sellerId: now
                    ]
                )
            )
        }

        // A chat where the current user is selling (an inbound buyer on their listing).
        if let listing = listings.first(where: { $0.sellerId == currentUserId }),
           let buyer = users.first(where: { $0.id != currentUserId }) {
            let convoId = "c2"
            seeded.append(
                Conversation(
                    id: convoId,
                    listingId: listing.id,
                    buyerId: buyer.id,
                    sellerId: currentUserId,
                    updatedAt: now.addingTimeInterval(-600),
                    messages: [
                        ChatMessage(
                            id: "m3", conversationId: convoId, senderId: buyer.id,
                            text: "Hi! Would you take a bit less if I pick it up today?",
                            sentAt: now.addingTimeInterval(-600)
                        )
                    ],
                    lastReadAtByUser: [
                        buyer.id: now,
                        currentUserId: now.addingTimeInterval(-3600)
                    ]
                )
            )
        }

        return seeded
    }
}
