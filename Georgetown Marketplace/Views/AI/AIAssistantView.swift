//
//  AIAssistantView.swift
//  Georgetown Marketplace
//

import SwiftUI

struct AIAssistantView: View {
    @EnvironmentObject private var store: MarketplaceStore

    @State private var input = ""
    @State private var messages: [AssistantMessage] = []
    @State private var shoppingList: [ShoppingListItem] = []
    @State private var isThinking = false
    @FocusState private var fieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            if messages.isEmpty {
                                welcomeCard
                                    .padding(.top, 8)
                            }

                            ForEach(messages) { message in
                                messageBubble(message)
                                    .id(message.id)
                            }

                            if !shoppingList.isEmpty {
                                shoppingListCard
                                    .id("list")
                            }

                            if isThinking {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("Building your list…")
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.hoyaGray)
                                }
                                .padding(.horizontal, 4)
                                .id("thinking")
                            }
                        }
                        .padding(12)
                        .padding(.bottom, 8)
                    }
                    .background(AppTheme.surface)
                    .onChange(of: messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(messages.last?.id ?? "list", anchor: .bottom)
                        }
                    }
                    .onChange(of: shoppingList.count) { _ in
                        withAnimation {
                            proxy.scrollTo("list", anchor: .bottom)
                        }
                    }
                }

                composer
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .hoyaNavChrome()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !shoppingList.isEmpty {
                        Button("Clear") {
                            shoppingList = []
                            appendAssistant("List cleared. What are we shopping for next?")
                        }
                        .foregroundStyle(.white)
                    }
                }
            }
            .navigationDestination(for: String.self) { id in
                if let listing = store.listing(id: id) {
                    ListingDetailView(listing: listing)
                }
            }
            .onAppear {
                if messages.isEmpty {
                    appendAssistant(
                        "Tell me what you need and I’ll build a campus shopping list.\n\nTry: “moving into a dorm”, “calc and bio textbooks”, or “cheap study setup under $100”."
                    )
                }
            }
        }
    }

    // MARK: - Sections

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Campus shopping, planned for you")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.hoyaNavy)
            Text("Describe your situation and I’ll turn it into a checklist — then link anything already listed on Marketplace.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.hoyaGray)
                .fixedSize(horizontal: false, vertical: true)

            FlowChips(
                titles: [
                    "Moving into a dorm",
                    "Calc + bio textbooks",
                    "Study desk setup",
                    "Kitchen basics",
                    "Under $50 essentials"
                ]
            ) { chip in
                input = chip
                send()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }

    private var shoppingListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your shopping list")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.hoyaNavy)
                Spacer()
                Text("\(shoppingList.filter(\.isChecked).count)/\(shoppingList.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.hoyaGray)
            }

            ForEach($shoppingList) { $item in
                shoppingRow($item)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }

    private func shoppingRow(_ item: Binding<ShoppingListItem>) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                item.wrappedValue.isChecked.toggle()
            } label: {
                Image(systemName: item.wrappedValue.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(item.wrappedValue.isChecked ? AppTheme.success : AppTheme.hoyaGrayLight)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.wrappedValue.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .strikethrough(item.wrappedValue.isChecked)
                Text(item.wrappedValue.reason)
                    .font(.caption)
                    .foregroundStyle(AppTheme.hoyaGray)
                HStack(spacing: 8) {
                    Text(item.wrappedValue.category.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.hoyaNavy)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.hoyaNavy.opacity(0.08))
                        .clipShape(Capsule())
                    if let budget = item.wrappedValue.budgetLabel {
                        Text("~\(budget)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.price)
                    }
                }

                if let listingId = item.wrappedValue.matchedListingId,
                   let listing = store.listing(id: listingId) {
                    NavigationLink(value: listingId) {
                        HStack(spacing: 6) {
                            Image(systemName: "storefront.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("View \(listing.title)")
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Text(listing.priceLabel)
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.hoyaNavy)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func messageBubble(_ message: AssistantMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 36) }
            Text(message.text)
                .font(.system(size: 15))
                .foregroundStyle(message.role == .user ? Color.white : AppTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.role == .user
                        ? AppTheme.hoyaNavy
                        : Color.white
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(message.role == .user ? Color.clear : AppTheme.cardBorder, lineWidth: 1)
                )
            if message.role == .assistant { Spacer(minLength: 36) }
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("What do you need?", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .focused($fieldFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.searchFill)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? AppTheme.hoyaNavy : AppTheme.hoyaGrayLight)
            }
            .disabled(!canSend || isThinking)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.cardBorder)
                .frame(height: 1)
        }
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(
            AssistantMessage(
                id: UUID().uuidString,
                role: .user,
                text: text,
                listSnapshot: shoppingList,
                createdAt: Date()
            )
        )
        input = ""
        fieldFocused = false
        isThinking = true

        // Brief delay so it feels like an assistant responding
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            let result = ShoppingListAI.reply(
                to: text,
                existingList: shoppingList,
                listings: store.listings
            )
            shoppingList = result.list
            appendAssistant(result.message)
            isThinking = false
        }
    }

    private func appendAssistant(_ text: String) {
        messages.append(
            AssistantMessage(
                id: UUID().uuidString,
                role: .assistant,
                text: text,
                listSnapshot: shoppingList,
                createdAt: Date()
            )
        )
    }
}

private struct FlowChips: View {
    let titles: [String]
    let onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(titles, id: \.self) { title in
                Button {
                    onTap(title)
                } label: {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.hoyaNavy)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.hoyaNavy.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }
}
