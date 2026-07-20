//
//  InboxView.swift
//  Georgetown Marketplace
//

import SwiftUI

struct InboxView: View {
    @EnvironmentObject private var store: MarketplaceStore

    var body: some View {
        NavigationStack {
            Group {
                if store.sortedConversations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(AppTheme.hoyaNavy.opacity(0.35))
                        Text("No messages yet")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppTheme.hoyaNavy)
                        Text("Message a seller from any listing or profile.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.hoyaGray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.surface)
                } else {
                    List(store.sortedConversations) { convo in
                        NavigationLink {
                            ChatThreadView(conversation: convo)
                        } label: {
                            ConversationRow(conversation: convo)
                        }
                        .listRowBackground(Color.white)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.surface)
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.inline)
            .hoyaNavChrome()
        }
    }
}

struct ConversationRow: View {
    @EnvironmentObject private var store: MarketplaceStore
    let conversation: Conversation

    private var other: UserProfile? {
        guard let uid = store.currentUser?.id else { return nil }
        return store.user(id: conversation.otherUserId(currentUserId: uid))
    }

    private var listing: Listing? {
        store.listing(id: conversation.listingId)
    }

    private var unread: Int {
        guard let uid = store.currentUser?.id else { return 0 }
        return conversation.unreadCount(for: uid)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                ListingImagePlaceholder(
                    symbol: listing?.imageSymbol ?? "bag",
                    hex: listing?.imageColorHex ?? "041E42",
                    height: 56,
                    cornerRadius: 8
                )
                .frame(width: 56)

                if let other {
                    AvatarView(user: other, size: 22)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: 4, y: 4)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(other?.name ?? "User")
                        .font(.system(size: 15, weight: unread > 0 ? .heavy : .bold))
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    if let last = conversation.lastMessage {
                        Text(last.sentAt, style: .time)
                            .font(.system(size: 12, weight: unread > 0 ? .bold : .regular))
                            .foregroundStyle(unread > 0 ? AppTheme.hoyaNavy : AppTheme.hoyaGray)
                    }
                }
                Text(listing.map { "\($0.askLabel) · \($0.title)" } ?? "Listing")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.hoyaNavy)
                    .lineLimit(1)
                HStack {
                    if let last = conversation.lastMessage {
                        Text(last.text)
                            .font(.system(size: 13, weight: unread > 0 ? .semibold : .regular))
                            .foregroundStyle(unread > 0 ? AppTheme.ink : AppTheme.hoyaGray)
                            .lineLimit(1)
                    }
                    Spacer()
                    if unread > 0 {
                        Text("\(unread)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(AppTheme.hoyaNavy)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ChatThreadView: View {
    @EnvironmentObject private var store: MarketplaceStore
    let conversation: Conversation
    @State private var draft = ""

    private var live: Conversation {
        store.conversations.first(where: { $0.id == conversation.id }) ?? conversation
    }

    private var listing: Listing? {
        store.listing(id: live.listingId)
    }

    private var other: UserProfile? {
        guard let uid = store.currentUser?.id else { return nil }
        return store.user(id: live.otherUserId(currentUserId: uid))
    }

    private var sortedMessages: [ChatMessage] {
        live.messages.sorted { $0.sentAt < $1.sentAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let listing {
                NavigationLink {
                    ListingDetailView(listing: listing)
                } label: {
                    HStack(spacing: 10) {
                        ListingImagePlaceholder(
                            symbol: listing.imageSymbol,
                            hex: listing.imageColorHex,
                            height: 48,
                            cornerRadius: 8
                        )
                        .frame(width: 48)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(listing.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.ink)
                                .lineLimit(1)
                            Text(listing.askLabel)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.hoyaNavy)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.hoyaGrayLight)
                    }
                    .padding(12)
                    .background(Color.white)
                }
                .buttonStyle(.plain)
                Divider()
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(sortedMessages) { message in
                            MessageBubble(
                                message: message,
                                isMine: message.senderId == store.currentUser?.id,
                                showTime: true
                            )
                            .id(message.id)
                        }
                    }
                    .padding(14)
                }
                .background(AppTheme.surface)
                .onAppear {
                    store.markConversationRead(live.id)
                    if let last = sortedMessages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
                .onChange(of: live.messages.count) { _, _ in
                    store.markConversationRead(live.id)
                    if let last = sortedMessages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Quick replies
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SampleData.quickReplies, id: \.self) { reply in
                        Button {
                            store.sendMessage(conversationId: live.id, text: reply)
                        } label: {
                            Text(reply)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.hoyaNavy)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .overlay(
                                    Capsule().stroke(AppTheme.hoyaNavy.opacity(0.2), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(Color.white)

            Divider()
            HStack(spacing: 10) {
                TextField("Message…", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(AppTheme.searchFill)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Button {
                    store.sendMessage(conversationId: live.id, text: draft)
                    draft = ""
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(AppTheme.hoyaNavy)
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(10)
            .background(Color.white)
        }
        .navigationTitle(other?.name ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .hoyaNavChrome()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let other {
                    NavigationLink {
                        PublicProfileView(userId: other.id)
                    } label: {
                        AvatarView(user: other, size: 28)
                    }
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isMine: Bool
    var showTime: Bool = false

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 56) }
            VStack(alignment: isMine ? .trailing : .leading, spacing: 3) {
                Text(message.text)
                    .font(.system(size: 15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isMine ? AppTheme.hoyaNavy : Color.white)
                    .foregroundStyle(isMine ? .white : AppTheme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                if showTime {
                    Text(message.sentAt, style: .time)
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.hoyaGray)
                        .padding(.horizontal, 4)
                }
            }
            if !isMine { Spacer(minLength: 56) }
        }
    }
}
