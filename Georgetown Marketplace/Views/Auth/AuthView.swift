//
//  AuthView.swift
//  Georgetown Marketplace
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var store: MarketplaceStore
    @ObservedObject private var theme = ThemeCenter.shared
    @State private var route: Route = .college

    enum Route {
        case college
        case welcome
        case logIn
        case signUp
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.hoyaNavy,
                    AppTheme.hoyaNavyDeep,
                    AppTheme.hoyaBlue.opacity(0.45)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.35), value: theme.college)

            switch route {
            case .college:
                CollegePickerView {
                    go(.welcome)
                }
                .transition(.opacity)
            case .welcome:
                WelcomeView(
                    onLogIn: { go(.logIn) },
                    onSignUp: { go(.signUp) },
                    onChangeCollege: { go(.college) }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            case .logIn:
                LogInView(onBack: { go(.welcome) }, onSwitchToSignUp: { go(.signUp) })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .signUp:
                SignUpView(onBack: { go(.welcome) }, onSwitchToLogIn: { go(.logIn) })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Returning users who already picked a school can skip straight to welcome.
            if theme.college != nil, route == .college {
                route = .welcome
            }
        }
    }

    private func go(_ target: Route) {
        withAnimation(.easeInOut(duration: 0.22)) {
            store.authError = nil
            route = target
        }
    }
}

// MARK: - Welcome

private struct WelcomeView: View {
    @EnvironmentObject private var store: MarketplaceStore
    @ObservedObject private var theme = ThemeCenter.shared
    var onLogIn: () -> Void
    var onSignUp: () -> Void
    var onChangeCollege: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            VStack(alignment: .leading, spacing: 12) {
                Text("MARKETPLACE")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2.4)
                    .foregroundStyle(Color.white.opacity(0.55))

                Text("\(theme.college?.shortName ?? "Campus")\nMarketplace")
                    .font(.system(size: 40, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .animation(.easeInOut(duration: 0.25), value: theme.college)

                Text("Buy it, bid on it, or borrow it — a cleaner Marketplace with real chat and profiles.")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)

                if let college = theme.college {
                    Button(action: onChangeCollege) {
                        HStack(spacing: 8) {
                            HStack(spacing: 0) {
                                Color(hex: college.primaryHex)
                                Color(hex: college.secondaryHex)
                            }
                            .frame(width: 28, height: 18)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            Text(college.name)
                                .font(.system(size: 13, weight: .semibold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SampleData.listings.prefix(4)) { listing in
                        VStack(alignment: .leading, spacing: 6) {
                            ListingPhotoView(listing: listing, height: 100, cornerRadius: 10)
                                .frame(width: 120)
                            Text(listing.askLabel)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                            Text(listing.title)
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.7))
                                .lineLimit(1)
                                .frame(width: 120, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, 28)
            }
            .padding(.top, 26)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onLogIn) {
                    Text("Log in")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.white)
                        .foregroundStyle(AppTheme.hoyaNavy)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onSignUp) {
                    Text("Create account")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.white.opacity(0.14))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)

                demoButton(label: "Example account")
                    .padding(.top, 2)

                Text("The example account skips sign-in so you can test the app.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
    }

    private func demoButton(label: String) -> some View {
        Button {
            store.signInAsDemo()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.10))
            .foregroundStyle(.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared form scaffolding

private struct AuthFormContainer<Content: View>: View {
    let title: String
    let subtitle: String
    var onBack: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("Back")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 32)

                content
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 28)
                    .padding(.bottom, 28)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

/// Auth fields sit on dark gradients while the whole flow is forced into dark mode,
/// so they pin their own light-mode colors — otherwise placeholders render white-on-white.
private enum AuthFieldStyle {
    static let text = Color(hex: "1C1C1E")
    static let placeholder = Color(hex: "8A8680")
}

private struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    var isEmail = false

    var body: some View {
        TextField(
            placeholder,
            text: $text,
            prompt: Text(placeholder).foregroundStyle(AuthFieldStyle.placeholder)
        )
        .textContentType(isEmail ? .emailAddress : .name)
        .keyboardType(isEmail ? .emailAddress : .default)
        .textInputAutocapitalization(isEmail ? .never : .words)
        .autocorrectionDisabled()
        .padding(14)
        .background(Color.white)
        .foregroundStyle(AuthFieldStyle.text)
        .environment(\.colorScheme, .light)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AuthSecureField: View {
    let placeholder: String
    @Binding var text: String
    @State private var isRevealed = false

    var body: some View {
        HStack {
            Group {
                if isRevealed {
                    TextField(
                        placeholder,
                        text: $text,
                        prompt: Text(placeholder).foregroundStyle(AuthFieldStyle.placeholder)
                    )
                } else {
                    SecureField(
                        placeholder,
                        text: $text,
                        prompt: Text(placeholder).foregroundStyle(AuthFieldStyle.placeholder)
                    )
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .foregroundStyle(AuthFieldStyle.placeholder)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.white)
        .foregroundStyle(AuthFieldStyle.text)
        .environment(\.colorScheme, .light)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AuthErrorText: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.footnote.weight(.medium))
            .foregroundStyle(Color(hex: "FFB4B4"))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Log in

private struct LogInView: View {
    @EnvironmentObject private var store: MarketplaceStore
    var onBack: () -> Void
    var onSwitchToSignUp: () -> Void

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        AuthFormContainer(
            title: "Welcome back",
            subtitle: "Log in with your email and password.",
            onBack: onBack
        ) {
            VStack(spacing: 12) {
                AuthTextField(placeholder: "Email address", text: $email, isEmail: true)
                AuthSecureField(placeholder: "Password", text: $password)

                if let error = store.authError {
                    AuthErrorText(message: error)
                }

                Button {
                    store.logIn(email: email, password: password)
                } label: {
                    Text("Log in")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.white)
                        .foregroundStyle(AppTheme.hoyaNavy)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onSwitchToSignUp) {
                    Text("New here? **Create an account**")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

                Text("Example: \(SampleData.demoUser.email) · password \(SampleData.demoPassword)")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Sign up

private struct SignUpView: View {
    @EnvironmentObject private var store: MarketplaceStore
    var onBack: () -> Void
    var onSwitchToLogIn: () -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        AuthFormContainer(
            title: "Create account",
            subtitle: "Use any personal email. Every account can buy and sell.",
            onBack: onBack
        ) {
            VStack(spacing: 12) {
                AuthTextField(placeholder: "Full name", text: $name)
                AuthTextField(placeholder: "Email address", text: $email, isEmail: true)
                AuthSecureField(placeholder: "Password (6+ characters)", text: $password)
                AuthSecureField(placeholder: "Confirm password", text: $confirmPassword)

                if let error = store.authError {
                    AuthErrorText(message: error)
                }

                Button {
                    store.signUp(
                        name: name,
                        email: email,
                        password: password,
                        confirmPassword: confirmPassword
                    )
                } label: {
                    Text("Create account")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.white)
                        .foregroundStyle(AppTheme.hoyaNavy)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onSwitchToLogIn) {
                    Text("Already have an account? **Log in**")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }

}
