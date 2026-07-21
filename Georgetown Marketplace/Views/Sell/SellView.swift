//
//  SellView.swift
//  Georgetown Marketplace
//

import SwiftUI
import PhotosUI

struct SellView: View {
    @EnvironmentObject private var store: MarketplaceStore

    private static let maxPhotos = 4

    @State private var title = ""
    @State private var priceText = ""
    @State private var category: ListingCategory = .dorm
    @State private var condition: ItemCondition = .good
    @State private var location: CampusArea = .mainCampus
    @State private var description = ""
    @State private var allowsLoan = false
    @State private var loanWeeklyText = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var photos: [Data] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    photoSection

                    fieldBlock("Title") {
                        TextField("What are you selling?", text: $title)
                            .padding(12)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    fieldBlock("Asking price") {
                        HStack {
                            Text("$")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(AppTheme.hoyaNavy)
                            TextField("Price", text: $priceText)
                                .keyboardType(.decimalPad)
                        }
                        .padding(12)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    fieldBlock("Lending") {
                        VStack(spacing: 10) {
                            Toggle(isOn: $allowsLoan.animation(.easeInOut(duration: 0.18))) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Offer as a loan too")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(AppTheme.ink)
                                    Text("Let people borrow it by the week instead of buying")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.hoyaGray)
                                }
                            }
                            .tint(AppTheme.hoyaNavy)

                            if allowsLoan {
                                HStack {
                                    Text("$")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundStyle(AppTheme.hoyaNavy)
                                    TextField("Price per week", text: $loanWeeklyText)
                                        .keyboardType(.decimalPad)
                                    Text("/week")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(AppTheme.hoyaGray)
                                }
                                .padding(12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                        .padding(12)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    fieldBlock("Category") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ListingCategory.allCases.filter { $0 != .all }) { cat in
                                    Button {
                                        category = cat
                                    } label: {
                                        Text(cat.rawValue)
                                            .font(.system(size: 13, weight: .semibold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(category == cat ? AppTheme.hoyaNavy : AppTheme.surface)
                                            .foregroundStyle(category == cat ? .white : AppTheme.hoyaNavy)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    fieldBlock("Condition") {
                        Picker("Condition", selection: $condition) {
                            ForEach(ItemCondition.allCases) { c in
                                Text(c.rawValue).tag(c)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    fieldBlock("Meetup location") {
                        Picker("Location", selection: $location) {
                            ForEach(CampusArea.allCases) { area in
                                Text(area.rawValue).tag(area)
                            }
                        }
                        .padding(4)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    fieldBlock("Description") {
                        TextField("Describe your item…", text: $description, axis: .vertical)
                            .lineLimit(4...8)
                            .padding(12)
                            .frame(minHeight: 100, alignment: .topLeading)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    HoyaPrimaryButton(title: "Publish") {
                        publish()
                    }
                    .padding(.top, 4)
                }
                .padding(16)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("Create listing")
            .navigationBarTitleDisplayMode(.inline)
            .hoyaNavChrome()
            .alert("Can't publish", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Photos

    @ViewBuilder
    private var photoSection: some View {
        if photos.isEmpty {
            PhotosPicker(
                selection: $pickerItems,
                maxSelectionCount: Self.maxPhotos,
                matching: .images
            ) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.surface)
                        .frame(height: 160)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(AppTheme.hoyaNavy.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [7]))
                        )

                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppTheme.hoyaNavy)
                        Text("Add photos")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.hoyaNavy)
                        Text("Up to \(Self.maxPhotos) — the first is your cover")
                            .font(.caption)
                            .foregroundStyle(AppTheme.hoyaGray)
                    }
                }
            }
            .buttonStyle(.plain)
            .onChange(of: pickerItems) { _, newItems in
                loadPhotos(from: newItems)
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(photos.enumerated()), id: \.offset) { index, data in
                        photoThumb(data, index: index)
                    }

                    if photos.count < Self.maxPhotos {
                        PhotosPicker(
                            selection: $pickerItems,
                            maxSelectionCount: Self.maxPhotos - photos.count,
                            matching: .images
                        ) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(AppTheme.surface)
                                .frame(width: 92, height: 92)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(AppTheme.hoyaNavy)
                                )
                        }
                        .buttonStyle(.plain)
                        .onChange(of: pickerItems) { _, newItems in
                            loadPhotos(from: newItems)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func photoThumb(_ data: Data, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    AppTheme.surface
                }
            }
            .frame(width: 92, height: 92)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    _ = photos.remove(at: index)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.black.opacity(0.55)))
            }
            .buttonStyle(.plain)
            .padding(4)

            if index == 0 {
                Text("COVER")
                    .font(.system(size: 8, weight: .heavy))
                    .tracking(0.5)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(AppTheme.hoyaNavy.opacity(0.92))
                    .clipShape(Capsule())
                    .padding(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
    }

    private func loadPhotos(from items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        pickerItems = []
        Task {
            for item in items {
                guard photos.count < Self.maxPhotos else { break }
                if let raw = try? await item.loadTransferable(type: Data.self),
                   let processed = Self.processedJPEG(raw) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        photos.append(processed)
                    }
                }
            }
        }
    }

    /// Downscale to a sane size so in-memory listings stay light.
    private static func processedJPEG(_ data: Data, maxDimension: CGFloat = 1200) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let largest = max(image.size.width, image.size.height)
        guard largest > 0 else { return nil }
        let scale = min(1, maxDimension / largest)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }

    private func fieldBlock<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.hoyaNavy)
            content()
        }
    }

    private func publish() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Add a title."
            showError = true
            return
        }
        let price = Double(priceText.replacingOccurrences(of: "$", with: "")) ?? -1
        guard price > 0 else {
            errorMessage = "Enter a price greater than $0."
            showError = true
            return
        }
        let trimmedDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDesc.isEmpty else {
            errorMessage = "Add a short description."
            showError = true
            return
        }

        var weeklyPrice: Double?
        if allowsLoan {
            guard let weekly = Double(loanWeeklyText.replacingOccurrences(of: "$", with: "")), weekly > 0 else {
                errorMessage = "Enter a weekly loan price."
                showError = true
                return
            }
            weeklyPrice = weekly
        }

        store.createListing(
            title: trimmedTitle,
            price: price,
            category: category,
            condition: condition,
            location: location,
            description: trimmedDesc,
            allowsLoan: allowsLoan,
            loanPricePerWeek: weeklyPrice,
            photosData: photos
        )

        title = ""
        priceText = ""
        description = ""
        category = .dorm
        condition = .good
        location = .mainCampus
        allowsLoan = false
        loanWeeklyText = ""
        photos = []
        pickerItems = []
    }
}
