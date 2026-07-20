//
//  RootView.swift
//  Georgetown Marketplace
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: MarketplaceStore

    var body: some View {
        Group {
            if store.isAuthenticated {
                MainTabView()
                    .sheet(isPresented: $store.needsProfileSetup) {
                        EditProfileView(isOnboarding: true)
                            .interactiveDismissDisabled()
                    }
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.isAuthenticated)
        .tint(AppTheme.hoyaNavy)
    }
}

struct MainTabView: View {
    @EnvironmentObject private var store: MarketplaceStore

    var body: some View {
        TabView(selection: $store.selectedTab) {
            BrowseView()
                .tabItem { Label("Browse", systemImage: "storefront.fill") }
                .tag(MarketplaceTab.browse)

            InboxView()
                .tabItem { Label("Inbox", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(MarketplaceTab.inbox)
                .badge(store.totalUnreadMessages)

            if store.isSeller {
                SellView()
                    .tabItem { Label("Sell", systemImage: "plus.circle.fill") }
                    .tag(MarketplaceTab.sell)
            }

            SavedView()
                .tabItem { Label("Saved", systemImage: "bookmark.fill") }
                .tag(MarketplaceTab.saved)

            ProfileView()
                .tabItem { Label("You", systemImage: "person.crop.circle.fill") }
                .tag(MarketplaceTab.you)
        }
        .tint(AppTheme.hoyaNavy)
        .toolbarBackground(Color.white, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
