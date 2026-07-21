//
//  SettingsView.swift
//  Georgetown Marketplace
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: MarketplaceStore
    @ObservedObject private var theme = ThemeCenter.shared
    @State private var showCollegePicker = false

    @AppStorage("gm.notifyMessages") private var notifyMessages = true
    @AppStorage("gm.notifyOffers") private var notifyOffers = true
    @AppStorage("gm.notifySavedDrops") private var notifySavedDrops = false

    var body: some View {
        Form {
            if let user = store.currentUser {
                Section("Account") {
                    LabeledContent("Name", value: user.name)
                    LabeledContent("Email", value: user.email)
                    LabeledContent("Member since", value: user.memberSinceLabel)
                }
            }

            Section("School") {
                Button {
                    showCollegePicker = true
                } label: {
                    HStack(spacing: 12) {
                        HStack(spacing: 0) {
                            Color(hex: currentCollege.primaryHex)
                            Color(hex: currentCollege.secondaryHex)
                        }
                        .frame(width: 36, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentCollege.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.ink)
                                .multilineTextAlignment(.leading)
                            Text("Tap to change — the app recolors to match")
                                .font(.caption)
                                .foregroundStyle(AppTheme.hoyaGray)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.hoyaGrayLight)
                    }
                }
                .buttonStyle(.plain)
            }

            Section {
                Toggle("New messages", isOn: $notifyMessages)
                Toggle("Bids & loan requests", isOn: $notifyOffers)
                Toggle("Price drops on saved items", isOn: $notifySavedDrops)
            } header: {
                Text("Notifications")
            } footer: {
                Text("Preview — push notifications aren't wired up yet.")
            }

            Section("About") {
                LabeledContent("App", value: "HandMeDorm")
                LabeledContent("Made by", value: "Aksel Everything")
                LabeledContent("Version", value: appVersion)
            }

            Section {
                Button(role: .destructive) {
                    store.signOut()
                } label: {
                    Text("Sign out")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .hoyaNavChrome()
        .sheet(isPresented: $showCollegePicker) {
            NavigationStack {
                ZStack {
                    LinearGradient(
                        colors: [AppTheme.hoyaNavy, AppTheme.hoyaNavyDeep, AppTheme.hoyaBlue.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    CollegePickerView(
                        onContinue: {
                            if let selected = theme.college {
                                store.updateCollege(selected)
                            }
                            showCollegePicker = false
                        },
                        showsContinueButton: true,
                        title: "Change your school",
                        subtitle: "Search any U.S. school to retheme the app."
                    )
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { showCollegePicker = false }
                            .foregroundStyle(.white)
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private var currentCollege: College {
        theme.college ?? store.currentUser?.college ?? CollegeCatalog.fallback
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
