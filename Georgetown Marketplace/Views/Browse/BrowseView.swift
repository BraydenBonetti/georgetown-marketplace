//
//  BrowseView.swift
//  Georgetown Marketplace
//

import SwiftUI

struct BrowseView: View {
    @EnvironmentObject private var store: MarketplaceStore

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    MarketplaceSearchField(
                        text: $store.searchText,
                        placeholder: "Search Marketplace"
                    )
                    .padding(.horizontal, 12)
                    .padding(.top, 4)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterPill(title: "Sell", systemImage: "plus") {
                                store.selectedTab = .sell
                            }
                            FilterPill(
                                title: "Free",
                                systemImage: "gift",
                                isSelected: store.showFreeOnly
                            ) {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    store.showFreeOnly.toggle()
                                    if store.showFreeOnly { store.searchText = "" }
                                }
                            }
                            FilterPill(
                                title: "Borrow",
                                systemImage: "clock.arrow.circlepath",
                                isSelected: store.showBorrowableOnly
                            ) {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    store.showBorrowableOnly.toggle()
                                }
                            }
                            FilterPill(title: "Saved", systemImage: "bookmark") {
                                store.selectedTab = .saved
                            }
                            if store.activeFilterCount > 0 {
                                FilterPill(title: "Clear", systemImage: "xmark") {
                                    withAnimation { store.clearBrowseFilters() }
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 4) {
                            ForEach(ListingCategory.allCases) { category in
                                CategoryCircle(
                                    category: category,
                                    isSelected: store.selectedCategory == category
                                ) {
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        store.selectedCategory = category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                    }

                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Today's picks")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(AppTheme.hoyaNavy)
                            Text("\(store.filteredListings.count) listing\(store.filteredListings.count == 1 ? "" : "s")")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.hoyaGray)
                        }
                        Spacer()
                        Menu {
                            ForEach(MarketplaceStore.BrowseSort.allCases) { mode in
                                Button {
                                    store.sortMode = mode
                                } label: {
                                    HStack {
                                        Text(mode.rawValue)
                                        if store.sortMode == mode {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.arrow.down")
                                Text(store.sortMode.rawValue)
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.hoyaNavy)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.white)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 4)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(store.filteredListings) { listing in
                            NavigationLink(value: listing.id) {
                                ListingCard(
                                    listing: listing,
                                    isSaved: store.isSaved(listing)
                                ) {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                                        store.toggleSave(listing)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 28)

                    if store.filteredListings.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 36))
                                .foregroundStyle(AppTheme.hoyaGrayLight)
                            Text("No listings found")
                                .font(.headline)
                                .foregroundStyle(AppTheme.hoyaNavy)
                            Text("Try another category, clear filters, or check back later.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.hoyaGray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                            if store.activeFilterCount > 0 {
                                Button("Clear filters") {
                                    store.clearBrowseFilters()
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.hoyaNavy)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                        .padding(.bottom, 40)
                    }
                }
            }
            .background(AppTheme.surface.ignoresSafeArea())
            .navigationTitle("Marketplace")
            .navigationBarTitleDisplayMode(.inline)
            .hoyaNavChrome()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.selectedTab = .you
                    } label: {
                        if let user = store.currentUser {
                            AvatarView(user: user, size: 28)
                                .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1.5))
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .navigationDestination(for: String.self) { id in
                if let listing = store.listing(id: id) {
                    ListingDetailView(listing: listing)
                }
            }
        }
    }
}
