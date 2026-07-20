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
                    // FB-style search (in-feed, not nav searchable)
                    MarketplaceSearchField(
                        text: $store.searchText,
                        placeholder: "Search Marketplace"
                    )
                    .padding(.horizontal, 12)
                    .padding(.top, 4)

                    // Sell / filters row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if store.isSeller {
                                FilterPill(title: "Sell", systemImage: "plus") {
                                    store.selectedTab = .sell
                                }
                            }
                            FilterPill(title: "Free", systemImage: "gift") {
                                withAnimation {
                                    store.searchText = "Free"
                                }
                            }
                            FilterPill(title: "Saved", systemImage: "bookmark") {
                                store.selectedTab = .saved
                            }
                        }
                        .padding(.horizontal, 12)
                    }

                    // Category circles (FB Marketplace signature)
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

                    // Today's picks
                    HStack(alignment: .firstTextBaseline) {
                        Text("Today's picks")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppTheme.hoyaNavy)
                        Spacer()
                        Text("Local pickup")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.hoyaGray)
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
                                    store.toggleSave(listing)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 28)

                    if store.filteredListings.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "bag")
                                .font(.system(size: 36))
                                .foregroundStyle(AppTheme.hoyaGrayLight)
                            Text("No listings found")
                                .font(.headline)
                                .foregroundStyle(AppTheme.hoyaNavy)
                            Text("Try another category or search.")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.hoyaGray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
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
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 26))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, AppTheme.hoyaBlue)
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
