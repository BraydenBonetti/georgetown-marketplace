//
//  AuthView.swift
//  Georgetown Marketplace
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var store: MarketplaceStore
    @State private var route: Route = .welcome

    enum Route {
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
                    Color(hex: "0A2744")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            switch route {
            case .welcome:
                WelcomeView(
                    onLogIn: { go(.logIn) },
                    onSignUp: { go(.signUp) }
                )
                .transition(.move(edge: .leading).combined(with: .opacity))
            case .logIn:
                LogInView(onBack: { go(.welcome) }, onSwitchToSignUp: { go(.signUp) })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .signUp:
                SignUpView(onBack: { go(.welcome) }, onSwitchToLogIn: { go(.logIn) })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.dark)
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
    var onLogIn: () -> Void
    var onSignUp: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            VStack(alignment: .leading, spacing: 12) {
                Text("MARKETPLACE")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2.4)
                    .foregroundStyle(AppTheme.hoyaGrayLight)

                Text("Georgetown\nMarketplace")
                    .font(.system(size: 40, weight: .bold, design: .serif))
                    .foregroundStyle(.white)

                Text("Buy it, bid on it, or borrow it — a cleaner Marketplace with real chat and profiles.")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SampleData.listings.prefix(4)) { listing in
                        VStack(alignment: .leading, spacing: 6) {
                            ListingImagePlaceholder(
                                symbol: listing.imageSymbol,
                                hex: listing.imageColorHex,
                                height: 100,
                                cornerRadius: 10
                            )
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

                HStack(spacing: 10) {
                    demoButton(role: .buyer, label: "Example buyer")
                    demoButton(role: .seller, label: "Example seller")
                }
                .padding(.top, 2)

                Text("Example accounts skip sign-in so you can test the app.")
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

    private func demoButton(role: AccountRole, label: String) -> some View {
        Button {
            store.signInAsDemo(role: role)
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

private struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    var isEmail = false

    var body: some View {
        TextField(placeholder, text: $text)
            .textContentType(isEmail ? .emailAddress : .name)
            .keyboardType(isEmail ? .emailAddress : .default)
            .textInputAutocapitalization(isEmail ? .never : .words)
            .autocorrectionDisabled()
            .padding(14)
            .background(Color.white)
            .foregroundStyle(AppTheme.ink)
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
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .foregroundStyle(AppTheme.hoyaGray)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.white)
        .foregroundStyle(AppTheme.ink)
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

                Text("Example: \(SampleData.demoBuyer.email) · password \(SampleData.demoPassword)")
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
    @State private var role: AccountRole = .buyer

    var body: some View {
        AuthFormContainer(
            title: "Create account",
            subtitle: "Use any personal email. Pick how you'll use the app.",
            onBack: onBack
        ) {
            VStack(spacing: 12) {
                // Buyer / seller selector
                HStack(spacing: 10) {
                    rolePill(.buyer, caption: "Browse & make offers")
                    rolePill(.seller, caption: "Post & manage listings")
                }

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
                        confirmPassword: confirmPassword,
                        role: role
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

    private func rolePill(_ target: AccountRole, caption: String) -> some View {
        Button {
            role = target
        } label: {
            VStack(spacing: 4) {
                Image(systemName: target.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                Text(target.rawValue)
                    .font(.system(size: 14, weight: .bold))
                Text(caption)
                    .font(.system(size: 10))
                    .opacity(0.7)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(role == target ? Color.white : Color.white.opacity(0.10))
            .foregroundStyle(role == target ? AppTheme.hoyaNavy : .white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
