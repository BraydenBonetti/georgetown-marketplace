//
//  ShoppingListAI.swift
//  Georgetown Marketplace
//
//  On-device shopping-list assistant — parses what you need and matches
//  live marketplace listings when possible.
//

import Foundation

struct ShoppingListItem: Identifiable, Hashable {
    let id: String
    var name: String
    var category: ListingCategory
    var reason: String
    var isChecked: Bool
    var matchedListingId: String?
    var estimatedBudget: Double?

    var budgetLabel: String? {
        guard let estimatedBudget else { return nil }
        return Listing.money(estimatedBudget)
    }
}

struct AssistantMessage: Identifiable, Hashable {
    enum Role: Hashable {
        case user
        case assistant
    }

    let id: String
    let role: Role
    let text: String
    let listSnapshot: [ShoppingListItem]
    let createdAt: Date
}

enum ShoppingListAI {
    static func reply(
        to rawInput: String,
        existingList: [ShoppingListItem],
        listings: [Listing]
    ) -> (message: String, list: [ShoppingListItem]) {
        let input = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            return ("Tell me what you’re shopping for — dorm setup, textbooks, a weekend kit, whatever.", existingList)
        }

        let lower = input.lowercased()

        if looksLikeGreeting(lower) && existingList.isEmpty {
            return (
                "Hey! I’m your campus shopping assistant.\n\nTell me what you need — e.g. “moving into a dorm”, “calc + biology textbooks”, or “cheap desk setup under $100” — and I’ll build a checklist, then pull matching Marketplace listings when I can.",
                existingList
            )
        }

        if looksLikeClear(lower) {
            return ("Cleared your list. What should we shop for next?", [])
        }

        if looksLikeShowList(lower) {
            if existingList.isEmpty {
                return ("Your list is empty. Tell me what you need and I’ll build one.", existingList)
            }
            return (summarizeList(existingList), existingList)
        }

        var list = existingList
        let removals = extractRemovals(from: lower)
        if !removals.isEmpty {
            list = list.filter { item in
                !removals.contains { item.name.lowercased().contains($0) || item.category.rawValue.lowercased().contains($0) }
            }
        }

        let additions = generateItems(from: lower, listings: listings)
        for item in additions {
            if !list.contains(where: { $0.name.localizedCaseInsensitiveCompare(item.name) == .orderedSame }) {
                list.append(item)
            }
        }

        // Refresh matches against current marketplace inventory
        list = list.map { item in
            var copy = item
            if copy.matchedListingId == nil {
                copy.matchedListingId = bestMatch(for: copy, in: listings)?.id
            }
            return copy
        }

        if additions.isEmpty && removals.isEmpty {
            return (
                "I wasn’t sure what to add. Try something like “dorm essentials”, “textbooks for econ and calc”, “gaming setup”, or “kitchen basics”.",
                list
            )
        }

        let addedNames = additions.map(\.name)
        var parts: [String] = []
        if !addedNames.isEmpty {
            parts.append("Added \(addedNames.count) item\(addedNames.count == 1 ? "" : "s"): \(addedNames.prefix(6).joined(separator: ", "))\(addedNames.count > 6 ? "…" : "").")
        }
        if !removals.isEmpty {
            parts.append("Removed anything matching: \(removals.joined(separator: ", ")).")
        }
        let matched = list.filter { $0.matchedListingId != nil }.count
        if matched > 0 {
            parts.append("\(matched) item\(matched == 1 ? "" : "s") already have a match on Marketplace — tap to open.")
        }
        parts.append("Check things off as you go, or tell me what else you need.")

        return (parts.joined(separator: "\n\n"), list)
    }

    // MARK: - Generation

    private static func generateItems(from lower: String, listings: [Listing]) -> [ShoppingListItem] {
        var items: [ShoppingListItem] = []

        func add(
            _ name: String,
            _ category: ListingCategory,
            _ reason: String,
            budget: Double? = nil
        ) {
            guard !items.contains(where: { $0.name == name }) else { return }
            let match = bestMatch(
                for: ShoppingListItem(
                    id: UUID().uuidString,
                    name: name,
                    category: category,
                    reason: reason,
                    isChecked: false,
                    matchedListingId: nil,
                    estimatedBudget: budget
                ),
                in: listings
            )
            items.append(
                ShoppingListItem(
                    id: UUID().uuidString,
                    name: name,
                    category: category,
                    reason: reason,
                    isChecked: false,
                    matchedListingId: match?.id,
                    estimatedBudget: budget ?? match?.price
                )
            )
        }

        // Scenario packs
        if matchesAny(lower, ["dorm", "move in", "move-in", "moving in", "residence", "freshman", "first year", "new room"]) {
            add("Twin XL sheets", .dorm, "Dorm beds need Twin XL", budget: 20)
            add("Desk lamp", .dorm, "Late-night studying", budget: 15)
            add("Mini fridge", .dorm, "Snacks + leftovers", budget: 60)
            add("Hangers", .dorm, "Closet basics", budget: 8)
            add("Laundry hamper", .furniture, "Weekly laundry runs", budget: 18)
            add("Power strip", .electronics, "Limited outlets", budget: 15)
            add("Storage bins", .dorm, "Under-bed storage", budget: 20)
        }

        if matchesAny(lower, ["textbook", "text book", "class books", "syllabus", "semester books"])
            || matchesAny(lower, ["calc", "calculus", "biology", "chem", "chemistry", "econ", "economics", "physics", "psych", "government", "govt"]) {
            if matchesAny(lower, ["calc", "calculus", "math"]) {
                add("Calculus textbook (Stewart)", .textbooks, "You mentioned calc/math", budget: 30)
            }
            if matchesAny(lower, ["bio", "biology"]) {
                add("Campbell Biology", .textbooks, "You mentioned biology", budget: 55)
            }
            if matchesAny(lower, ["chem", "chemistry", "organic"]) {
                add("Organic Chemistry / Gen Chem text", .textbooks, "You mentioned chemistry", budget: 45)
            }
            if matchesAny(lower, ["econ", "economics", "mankiw", "micro", "macro"]) {
                add("Economics textbook (Mankiw)", .textbooks, "You mentioned econ", budget: 40)
            }
            if matchesAny(lower, ["physics"]) {
                add("Physics for Scientists & Engineers", .textbooks, "You mentioned physics", budget: 50)
            }
            if matchesAny(lower, ["psych", "psychology"]) {
                add("Intro Psychology textbook", .textbooks, "You mentioned psych", budget: 35)
            }
            if matchesAny(lower, ["gov", "government", "politics", "poli sci"]) {
                add("American Government textbook", .textbooks, "You mentioned government/politics", budget: 25)
            }
            if lower.contains("textbook") || lower.contains("text book") || lower.contains("class books") {
                if items.allSatisfy({ $0.category != .textbooks }) {
                    add("Course textbooks", .textbooks, "General textbook request — tell me the classes for specifics", budget: 40)
                }
            }
        }

        if matchesAny(lower, ["desk", "study setup", "homework setup", "workspace"]) {
            add("Desk", .furniture, "Study space", budget: 45)
            add("Desk chair", .furniture, "Comfort for long sessions", budget: 40)
            add("Desk lamp", .dorm, "Task lighting", budget: 15)
        }

        if matchesAny(lower, ["gaming", "game", "monitor", "keyboard", "mouse", "switch", "console"]) {
            add("Monitor", .electronics, "Gaming / productivity", budget: 180)
            add("Keyboard", .electronics, "Better typing + games", budget: 65)
            add("Mouse", .electronics, "Precision control", budget: 30)
            if lower.contains("switch") || lower.contains("nintendo") {
                add("Nintendo Switch", .electronics, "You mentioned Switch", budget: 250)
            }
        }

        if matchesAny(lower, ["tech", "electronics", "charger", "laptop", "headphones", "earbuds", "airpods", "ipad"]) {
            if matchesAny(lower, ["charger", "charging", "cable"]) {
                add("Phone / laptop charger", .electronics, "Always useful on campus", budget: 25)
            }
            if matchesAny(lower, ["headphone", "earbuds", "airpods", "noise cancel"]) {
                add("Headphones / earbuds", .electronics, "Library + commute", budget: 80)
            }
            if matchesAny(lower, ["ipad", "tablet"]) {
                add("iPad / tablet", .electronics, "Notes + reading", budget: 220)
            }
            if lower.contains("laptop") {
                add("Laptop sleeve", .electronics, "Protect your machine", budget: 15)
            }
            if items.filter({ $0.category == .electronics }).isEmpty {
                add("Portable charger", .electronics, "Long campus days", budget: 20)
            }
        }

        if matchesAny(lower, ["kitchen", "cook", "cooking", "meal prep", "food"]) {
            add("Electric kettle", .dorm, "Tea, coffee, ramen", budget: 22)
            add("Microwave-safe dishes", .other, "Dorm meals", budget: 15)
            add("Mini fridge", .dorm, "Keep food cold", budget: 60)
            add("Cast iron / skillet", .other, "Simple cooking", budget: 20)
        }

        if matchesAny(lower, ["clothes", "clothing", "hoodie", "jacket", "shoes", "outfit", "winter", "cold"]) {
            add("Hoodie / sweatshirt", .clothing, "Campus layering", budget: 25)
            if matchesAny(lower, ["winter", "cold", "jacket", "rain"]) {
                add("Rain / winter jacket", .clothing, "DC weather", budget: 40)
            }
            if matchesAny(lower, ["shoe", "sneaker", "dunk"]) {
                add("Everyday sneakers", .clothing, "Walking campus", budget: 50)
            }
        }

        if matchesAny(lower, ["ticket", "game", "concert", "show", "wizards", "nationals", "hoyas"]) {
            add("Event tickets", .tickets, "Something fun this week", budget: 40)
        }

        if matchesAny(lower, ["bike", "bicycle", "scooter", "commute"]) {
            if lower.contains("scooter") {
                add("Electric scooter", .other, "Faster campus commute", budget: 220)
            } else {
                add("Bike", .other, "Campus + neighborhood rides", budget: 280)
            }
            add("Bike lock", .other, "Don’t skip this", budget: 25)
        }

        if matchesAny(lower, ["workout", "gym", "fitness", "yoga", "weights"]) {
            add("Yoga mat", .other, "Stretching / workouts", budget: 45)
            add("Dumbbells", .other, "Dorm-friendly strength work", budget: 30)
        }

        // Explicit item mentions (single words / short phrases)
        let explicit: [(String, ListingCategory, String, Double?)] = [
            ("mini fridge", .dorm, "You asked for a mini fridge", 60),
            ("fridge", .dorm, "You asked for a fridge", 60),
            ("lamp", .dorm, "You asked for a lamp", 15),
            ("airpods", .electronics, "You asked for AirPods", 120),
            ("headphones", .electronics, "You asked for headphones", 80),
            ("monitor", .electronics, "You asked for a monitor", 180),
            ("desk", .furniture, "You asked for a desk", 45),
            ("chair", .furniture, "You asked for a chair", 40),
            ("backpack", .clothing, "You asked for a backpack", 45),
            ("hoodie", .clothing, "You asked for a hoodie", 25),
            ("mattress topper", .dorm, "Dorm bed upgrade", 40),
            ("vacuum", .dorm, "Room cleanup", 80),
            ("printer", .other, "Printing on campus is pricey", 45),
            ("suitcase", .other, "Breaks / travel", 120),
            ("plant", .other, "Make the room feel alive", 25),
            ("fan", .other, "Warm dorm nights", 15),
            ("whiteboard", .dorm, "Reminders + brainstorming", 12)
        ]
        for (keyword, cat, reason, budget) in explicit {
            if lower.contains(keyword) {
                let pretty = keyword.split(separator: " ").map { $0.capitalized }.joined(separator: " ")
                add(pretty == "Fridge" ? "Mini fridge" : pretty, cat, reason, budget: budget)
            }
        }

        // Budget-aware note: if they say "cheap" / "under $X", prefer lower budget items already added
        if let cap = extractBudgetCap(from: lower) {
            items = items.map { item in
                var copy = item
                if let est = copy.estimatedBudget, est > cap {
                    copy.reason += " (look for deals under \(Listing.money(cap)))"
                }
                return copy
            }
        }

        return items
    }

    private static func bestMatch(for item: ShoppingListItem, in listings: [Listing]) -> Listing? {
        let active = listings.filter { $0.status == .active }
        let tokens = item.name.lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { $0.count > 2 }

        let scored: [(Listing, Int)] = active.compactMap { listing in
            let hay = (listing.title + " " + listing.description + " " + listing.category.rawValue).lowercased()
            var score = 0
            if listing.category == item.category { score += 3 }
            for token in tokens where hay.contains(token) {
                score += 2
            }
            // Prefer cheaper when budgets exist
            if let budget = item.estimatedBudget, listing.price <= budget * 1.25 {
                score += 1
            }
            return score > 0 ? (listing, score) : nil
        }

        return scored.sorted { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
            return lhs.0.price < rhs.0.price
        }.first?.0
    }

    // MARK: - Helpers

    private static func matchesAny(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }

    private static func looksLikeGreeting(_ text: String) -> Bool {
        let greets = ["hi", "hello", "hey", "yo", "sup", "help", "what can you do"]
        return greets.contains(where: { text == $0 || text.hasPrefix($0 + " ") || text.hasPrefix($0 + ",") })
    }

    private static func looksLikeClear(_ text: String) -> Bool {
        matchesAny(text, ["clear list", "reset list", "start over", "delete list", "clear my list", "new list"])
    }

    private static func looksLikeShowList(_ text: String) -> Bool {
        matchesAny(text, ["show list", "my list", "what's on my list", "whats on my list", "see list", "shopping list"])
            && !matchesAny(text, ["make", "build", "create", "need", "want"])
    }

    private static func extractRemovals(from text: String) -> [String] {
        guard matchesAny(text, ["don't need", "do not need", "remove", "without", "no more", "skip"]) else { return [] }
        var found: [String] = []
        let candidates = [
            "clothing", "clothes", "textbooks", "textbook", "electronics", "furniture",
            "tickets", "fridge", "lamp", "desk", "chair", "hoodie", "headphones"
        ]
        for c in candidates where text.contains(c) {
            found.append(c)
        }
        return found
    }

    private static func extractBudgetCap(from text: String) -> Double? {
        // under $100 / under 100 / budget 50
        let patterns = [
            #"under\s*\$?\s*(\d+(?:\.\d+)?)"#,
            #"below\s*\$?\s*(\d+(?:\.\d+)?)"#,
            #"budget\s*(?:of\s*)?\$?\s*(\d+(?:\.\d+)?)"#,
            #"max\s*\$?\s*(\d+(?:\.\d+)?)"#
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..<text.endIndex, in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range),
                   match.numberOfRanges > 1,
                   let r = Range(match.range(at: 1), in: text) {
                    return Double(text[r])
                }
            }
        }
        if text.contains("cheap") || text.contains("budget") || text.contains("affordable") {
            return 40
        }
        return nil
    }

    private static func summarizeList(_ list: [ShoppingListItem]) -> String {
        let open = list.filter { !$0.isChecked }
        let done = list.filter(\.isChecked)
        var lines = ["Here’s your list (\(open.count) left, \(done.count) done):"]
        for item in list {
            let mark = item.isChecked ? "✓" : "•"
            let match = item.matchedListingId == nil ? "" : " — match on Marketplace"
            lines.append("\(mark) \(item.name)\(match)")
        }
        return lines.joined(separator: "\n")
    }
}
