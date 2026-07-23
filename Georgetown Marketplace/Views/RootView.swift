//
//  RootView.swift
//  Georgetown Marketplace
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: MarketplaceStore
    @ObservedObject private var theme = ThemeCenter.shared

    var body: some View {
        Group {
            if store.isAuthenticated {
                MainTabView()
                    // Every surface in the main app is a hardcoded light color, so pin
                    // light mode — otherwise system dark mode turns default-colored
                    // text white-on-white (the auth flow pins dark for the same reason).
                    .preferredColorScheme(.light)
                    .sheet(isPresented: $store.needsProfileSetup) {
                        EditProfileView(isOnboarding: true)
                            .interactiveDismissDisabled()
                    }
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.isAuthenticated)
        .animation(.easeInOut(duration: 0.35), value: theme.college)
        .tint(AppTheme.hoyaNavy)
        .id(theme.college?.id ?? "none")
    }
}

struct MainTabView: View {
    @EnvironmentObject private var store: MarketplaceStore
    @ObservedObject private var theme = ThemeCenter.shared

    var body: some View {
        TabView(selection: $store.selectedTab) {
            BrowseView()
                .tabItem { Label("Browse", systemImage: "storefront.fill") }
                .tag(MarketplaceTab.browse)

            InboxView()
                .tabItem { Label("Inbox", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(MarketplaceTab.inbox)
                .badge(store.totalUnreadMessages)

            AIAssistantView()
                .tabItem { Label("AI Assistant", systemImage: "sparkles") }
                .tag(MarketplaceTab.assistant)

            SellView()
                .tabItem { Label("Sell", systemImage: "plus.circle.fill") }
                .tag(MarketplaceTab.sell)

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
        .id(theme.college?.id ?? "none")
    }
}
