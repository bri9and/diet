import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// View for adding food to a meal
public struct AddFoodView: View {

    // MARK: - Properties

    @StateObject private var viewModel: AddFoodViewModel
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    @State private var showCamera = false
    @State private var showPhotoReview = false
    @State private var capturedPhotoData: Data?
    @State private var showBarcodeScanner = false
    @State private var showBarcodeResult = false
    @State private var scannedBarcode: String?
    @State private var showVoiceInput = false

    let mealType: FoodLogRecord.MealType
    let onFoodAdded: () -> Void

    // MARK: - Initialization

    public init(
        mealType: FoodLogRecord.MealType,
        viewModel: AddFoodViewModel,
        onFoodAdded: @escaping () -> Void
    ) {
        self.mealType = mealType
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onFoodAdded = onFoodAdded
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Quick actions
                quickActionsBar

                // Search bar
                searchBar

                // Content
                if viewModel.searchQuery.isEmpty {
                    recentFoodsSection
                } else {
                    searchResultsSection
                }
            }
            .navigationTitle("Add to \(mealType.displayName)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { photoData in
                    capturedPhotoData = photoData
                    showPhotoReview = true
                }
            }
            #endif
            .sheet(isPresented: $showPhotoReview) {
                if let photoData = capturedPhotoData {
                    PhotoReviewView(
                        imageData: photoData,
                        mealType: mealType,
                        foodService: environment.foodService
                    ) {
                        onFoodAdded()
                        dismiss()
                    }
                }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showBarcodeScanner) {
                BarcodeScannerView { barcode in
                    scannedBarcode = barcode
                    showBarcodeResult = true
                }
            }
            #endif
            .sheet(isPresented: $showBarcodeResult) {
                if let barcode = scannedBarcode {
                    BarcodeResultView(
                        barcode: barcode,
                        mealType: mealType,
                        foodService: environment.foodService
                    ) {
                        onFoodAdded()
                        dismiss()
                    }
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showVoiceInput) {
                VoiceInputView(
                    mealType: mealType,
                    foodService: environment.foodService
                ) {
                    onFoodAdded()
                    dismiss()
                }
            }
            #endif
        }
    }

    // MARK: - Quick Actions Bar

    private var quickActionsBar: some View {
        HStack(spacing: 16) {
            #if os(iOS)
            // Camera button
            Button {
                showCamera = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                    Text("Photo")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.searchBarBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            #endif

            #if os(iOS)
            // Barcode button
            Button {
                showBarcodeScanner = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.title2)
                    Text("Barcode")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.searchBarBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            #endif

            #if os(iOS)
            // Voice button
            Button {
                showVoiceInput = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "mic.fill")
                        .font(.title2)
                    Text("Voice")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.searchBarBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            #endif
        }
        .padding()
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search foods...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onSubmit {
                    Task {
                        await viewModel.search()
                    }
                }

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                    viewModel.searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.searchBarBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding()
        .onChange(of: viewModel.searchQuery) { _, newValue in
            if newValue.count >= 2 {
                Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    if viewModel.searchQuery == newValue {
                        await viewModel.search()
                    }
                }
            }
        }
    }

    // MARK: - Recent Foods

    private var recentFoodsSection: some View {
        Group {
            if viewModel.isLoadingRecent {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.recentFoods.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        Text("Recent Foods")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.bottom, 8)

                        ForEach(viewModel.recentFoods) { food in
                            recentFoodRow(food)
                        }
                    }
                    .padding(.top)
                }
            }
        }
        .task {
            await viewModel.loadRecentFoods()
        }
    }

    private func recentFoodRow(_ food: RecentFood) -> some View {
        Button {
            Task {
                await viewModel.logRecentFood(food, mealType: mealType)
                onFoodAdded()
                dismiss()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if let brand = food.brand {
                        Text(brand)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text("\(Int(food.nutrition.calories)) cal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .padding()
            .background(Color.cardBackground)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search Results

    private var searchResultsSection: some View {
        Group {
            if viewModel.isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                noResultsView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.searchResults) { food in
                            searchResultRow(food)
                        }
                    }
                }
            }
        }
    }

    private func searchResultRow(_ food: APIFood) -> some View {
        Button {
            Task {
                await viewModel.logFood(food, mealType: mealType)
                onFoodAdded()
                dismiss()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.name)
                        .font(.body)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        if let brand = food.brand {
                            Text(brand)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let serving = food.servingDescription {
                            Text(serving)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(food.nutrition.calories))")
                        .font(.headline)

                    Text("cal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .padding()
            .background(Color.cardBackground)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty States

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No recent foods")
                .font(.headline)

            Text("Search for foods or scan a barcode to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No results found")
                .font(.headline)

            Text("Try a different search term")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
