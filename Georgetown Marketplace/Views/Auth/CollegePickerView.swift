//
//  CollegePickerView.swift
//  Georgetown Marketplace
//

import SwiftUI

struct CollegePickerView: View {
    @ObservedObject private var theme = ThemeCenter.shared
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    var onContinue: (() -> Void)? = nil
    var showsContinueButton: Bool = true
    var title: String = "Which college do you go to?"
    var subtitle: String = "Search any U.S. school — we'll color the app with its colors."

    private var results: [College] {
        CollegeCatalog.search(searchText)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("YOUR SCHOOL")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2.2)
                    .foregroundStyle(Color.white.opacity(0.55))

                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.7))

                // Search
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white.opacity(0.55))
                    TextField("Search colleges…", text: $searchText)
                        .focused($searchFocused)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .foregroundStyle(.white)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.top, 6)

                Text(searchText.isEmpty
                      ? "\(CollegeCatalog.all.count) schools · showing popular matches"
                      : "\(results.count) result\(results.count == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            ScrollView {
                LazyVStack(spacing: 8) {
                    if let selected = theme.college, searchText.isEmpty {
                        collegeRow(selected, pinned: true)
                    }

                    ForEach(results.filter { $0.id != theme.college?.id }) { college in
                        collegeRow(college)
                    }

                    if results.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "building.columns")
                                .font(.system(size: 28))
                                .foregroundStyle(.white.opacity(0.35))
                            Text("No schools found")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Try another spelling or a shorter search.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }

            if showsContinueButton {
                Button {
                    searchFocused = false
                    onContinue?()
                } label: {
                    Text(theme.college == nil ? "Pick a college to continue" : "Continue with \(theme.college?.shortName ?? "")")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(theme.college == nil ? Color.white.opacity(0.25) : Color.white)
                        .foregroundStyle(theme.college == nil ? .white.opacity(0.6) : AppTheme.hoyaNavy)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .disabled(theme.college == nil)
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
                .padding(.top, 8)
            }
        }
        .onAppear {
            // Warm the catalog on first paint.
            _ = CollegeCatalog.all.count
        }
    }

    private func collegeRow(_ college: College, pinned: Bool = false) -> some View {
        let selected = theme.college?.id == college.id
        return Button {
            theme.select(college)
        } label: {
            HStack(spacing: 14) {
                HStack(spacing: 0) {
                    Color(hex: college.primaryHex)
                    Color(hex: college.secondaryHex)
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(college.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                        if pinned {
                            Text("SELECTED")
                                .font(.system(size: 9, weight: .heavy))
                                .tracking(0.5)
                                .foregroundStyle(AppTheme.hoyaNavy)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                    }
                    Text(college.shortName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }

                Spacer()

                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? Color.white.opacity(0.55) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CollegePickerScreen: View {
    @ObservedObject private var theme = ThemeCenter.shared
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.hoyaNavy,
                    AppTheme.hoyaNavyDeep,
                    AppTheme.hoyaBlue.opacity(0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.35), value: theme.college?.id)

            CollegePickerView(onContinue: onContinue)
        }
        .preferredColorScheme(.dark)
    }
}
