//
//  Georgetown_MarketplaceApp.swift
//  Georgetown Marketplace
//
//  Created by Brayden Bonetti on 7/20/26.
//

import SwiftUI

@main
struct Georgetown_MarketplaceApp: App {
    @StateObject private var store = MarketplaceStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
