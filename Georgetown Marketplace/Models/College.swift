//
//  College.swift
//  Georgetown Marketplace
//

import Foundation
import SwiftUI

struct BrandTheme: Equatable {
    let primary: Color
    let primaryDeep: Color
    let secondary: Color
    let muted: Color
    let mutedLight: Color
    let ink: Color
    let surface: Color
    let searchFill: Color
    let success: Color

    var price: Color { primary }
}

/// A US college / university that can theme the app.
struct College: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let shortName: String
    let primaryHex: String
    let secondaryHex: String
    let primaryDeepHex: String

    var brand: BrandTheme {
        BrandTheme(
            primary: Color(hex: primaryHex),
            primaryDeep: Color(hex: primaryDeepHex),
            secondary: Color(hex: secondaryHex),
            muted: Color(hex: "8A8680"),
            mutedLight: Color(hex: "B7B0AB"),
            ink: Color(hex: "050505"),
            surface: Color(hex: "F0F2F5"),
            searchFill: Color(hex: "E4E6EB"),
            success: Color(hex: "31A24C")
        )
    }
}

enum CollegeCatalog {
    static let all: [College] = load()

    static var fallback: College {
        all.first(where: { $0.name == "Georgetown University" })
            ?? all.first
            ?? College(
                id: "georgetown",
                name: "Georgetown University",
                shortName: "Georgetown",
                primaryHex: "041E42",
                secondaryHex: "8D817B",
                primaryDeepHex: "021530"
            )
    }

    static func college(id: String) -> College? {
        all.first { $0.id == id }
    }

    static func search(_ query: String) -> [College] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            let featuredNames: Set<String> = [
                "Georgetown University",
                "George Washington University",
                "American University",
                "Howard University",
                "Catholic University of America",
                "University of Maryland",
                "Johns Hopkins University",
                "University of Virginia",
                "Harvard University",
                "Stanford University",
                "Yale University",
                "Princeton University",
                "Massachusetts Institute of Technology",
                "Columbia University",
                "New York University",
                "University of Michigan",
                "University of California, Berkeley",
                "University of California, Los Angeles",
                "Duke University",
                "University of Pennsylvania",
                "Cornell University",
                "Northwestern University",
                "University of Notre Dame",
                "Boston College",
                "Boston University",
                "University of Texas at Austin",
                "University of Florida",
                "Ohio State University",
                "Pennsylvania State University",
                "University of Southern California"
            ]
            let featured = all.filter { featuredNames.contains($0.name) }
                .sorted { $0.name < $1.name }
            if !featured.isEmpty { return featured }
            return Array(all.prefix(40))
        }

        let tokens = q.split(separator: " ").map(String.init)

        return all
            .map { college -> (College, Int) in
                let name = college.name.lowercased()
                let short = college.shortName.lowercased()
                var score = 0
                if name == q || short == q { score += 1000 }
                if name.hasPrefix(q) { score += 400 }
                if short.hasPrefix(q) { score += 350 }
                if name.contains(q) { score += 200 }
                if short.contains(q) { score += 150 }
                for token in tokens where name.contains(token) {
                    score += 40
                }
                return (college, score)
            }
            .filter { $0.1 > 0 }
            .sorted {
                if $0.1 != $1.1 { return $0.1 > $1.1 }
                return $0.0.name < $1.0.name
            }
            .prefix(120)
            .map(\.0)
    }

    private static func load() -> [College] {
        let candidates = [
            Bundle.main.url(forResource: "us_colleges", withExtension: "json"),
            Bundle.main.url(forResource: "us_colleges", withExtension: "json", subdirectory: "Resources")
        ].compactMap { $0 }

        for url in candidates {
            if let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode([College].self, from: data),
               !decoded.isEmpty {
                return decoded
            }
        }

        // Dev fallback if the JSON isn't in the bundle yet.
        return [
            College(
                id: "georgetown",
                name: "Georgetown University",
                shortName: "Georgetown",
                primaryHex: "041E42",
                secondaryHex: "8D817B",
                primaryDeepHex: "021530"
            )
        ]
    }
}
