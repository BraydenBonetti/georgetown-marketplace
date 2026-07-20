//
//  ContentView.swift
//  Georgetown Marketplace
//
//  Created by Brayden Bonetti on 7/20/26.
//

import SwiftUI

/// Kept for Xcode previews; app entry uses `RootView`.
struct ContentView: View {
    var body: some View {
        RootView()
            .environmentObject(MarketplaceStore())
    }
}

#Preview {
    ContentView()
}
