//
//  EditProfileView.swift
//  Georgetown Marketplace
//

import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var store: MarketplaceStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeCenter.shared

    var isOnboarding: Bool = false

    @State private var name = ""
    @State private var bio = ""
    @State private var location: CampusArea = .mainCampus
    @State private var role: AccountRole = .buyer
    @State private var college: College = CollegeCatalog.fallback
    @State private var colorHex = "041E42"
    @State private var showCollegePicker = false

    private let colors = ["041E42", "1A3A6B", "6B4F3A", "8B1E1E", "2F5D50", "5B7C99", "4A3F6B", "57068C", "C8102E", "115740"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 88, height: 88)
                            Text(previewInitials)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(colors, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 34, height: 34)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: colorHex == hex ? 3 : 0)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(AppTheme.hoyaNavy, lineWidth: colorHex == hex ? 1.5 : 0)
                                    )
                                    .onTapGesture { colorHex = hex }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Avatar")
                }

                Section("College") {
                    Button {
                        showCollegePicker = true
                    } label: {
                        HStack(spacing: 12) {
                            HStack(spacing: 0) {
                                Color(hex: college.primaryHex)
                                Color(hex: college.secondaryHex)
                            }
                            .frame(width: 36, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(college.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AppTheme.ink)
                                    .multilineTextAlignment(.leading)
                                Text("Tap to search \(CollegeCatalog.all.count) schools")
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

                Section("About you") {
                    TextField("Display name", text: $name)
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                    Picker("Meetup area", selection: $location) {
                        ForEach(CampusArea.allCases) { area in
                            Text(area.rawValue).tag(area)
                        }
                    }
                }

                Section("Account type") {
                    Picker("I mostly want to", selection: $role) {
                        Text("Buy").tag(AccountRole.buyer)
                        Text("Sell").tag(AccountRole.seller)
                    }
                    .pickerStyle(.segmented)

                    Text(role == .seller
                         ? "You'll get a Sell tab to post listings, set asks, and accept bids or loans."
                         : "You'll browse, bid, borrow, and message sellers. You can switch later.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.hoyaGray)
                }
            }
            .navigationTitle(isOnboarding ? "Set up your profile" : "Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .hoyaNavChrome()
            .id(theme.college?.id ?? "none")
            .toolbar {
                if !isOnboarding {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(.white)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isOnboarding ? "Done" : "Save") {
                        store.updateProfile(
                            name: name,
                            bio: bio,
                            location: location,
                            role: role,
                            college: college,
                            avatarColorHex: colorHex
                        )
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
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
                                    college = selected
                                    colorHex = selected.primaryHex
                                }
                                showCollegePicker = false
                            },
                            showsContinueButton: true,
                            title: "Change your college",
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
            .onAppear {
                if let user = store.currentUser {
                    name = user.name
                    bio = user.bio
                    location = user.location
                    role = user.role
                    college = theme.college ?? user.college
                    colorHex = user.avatarColorHex
                }
            }
            .onChange(of: theme.college) { _, newValue in
                if let newValue {
                    college = newValue
                    colorHex = newValue.primaryHex
                }
            }
        }
    }

    private var previewInitials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String((name.isEmpty ? "?" : name).prefix(2)).uppercased()
    }
}
