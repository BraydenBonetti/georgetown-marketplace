//
//  SavedView.swift
//  Georgetown Marketplace
//

import SwiftUI

struct SavedView: View {
    @EnvironmentObject private var store: MarketplaceStore

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if store.savedListings.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(AppTheme.hoyaNavy.opacity(0.3))
                        Text("No saved items")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppTheme.hoyaNavy)
                        Text("Tap the bookmark on a listing to save it here.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.hoyaGray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.surface)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(store.savedListings) { listing in
                                NavigationLink(value: listing.id) {
                                    ListingCard(
                                        listing: listing,
                                        isSaved: true
                                    ) {
                                        store.toggleSave(listing)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(12)
                    }
                    .background(AppTheme.surface)
                }
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.inline)
            .hoyaNavChrome()
            .navigationDestination(for: String.self) { id in
                if let listing = store.listing(id: id) {
                    ListingDetailView(listing: listing)
                }
            }
        }
    }
}
