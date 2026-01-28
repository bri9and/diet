import SwiftUI

/// View for displaying barcode lookup results and logging food
public struct BarcodeResultView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: BarcodeResultViewModel

    let barcode: String
    let mealType: FoodLogRecord.MealType
    let onFoodLogged: () -> Void

    // MARK: - Initialization

    public init(
        barcode: String,
        mealType: FoodLogRecord.MealType,
        foodService: FoodService,
        onFoodLogged: @escaping () -> Void
    ) {
        self.barcode = barcode
        self.mealType = mealType
        self.onFoodLogged = onFoodLogged
        _viewModel = StateObject(wrappedValue: BarcodeResultViewModel(foodService: foodService))
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error)
                } else if let product = viewModel.product {
                    productView(product)
                }
            }
            .navigationTitle("Product Found")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if viewModel.product != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            Task {
                                await viewModel.logProduct(mealType: mealType)
                                onFoodLogged()
                                dismiss()
                            }
                        }
                        .disabled(viewModel.isLogging)
                    }
                }
            }
        }
        .task {
            await viewModel.lookupBarcode(barcode)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Looking up product...")
                .font(.headline)

            Text("Barcode: \(barcode)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "barcode")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Product Not Found")
                .font(.title2)
                .fontWeight(.semibold)

            Text(error)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 12) {
                Button("Try Again") {
                    Task {
                        await viewModel.lookupBarcode(barcode)
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Scan Different Barcode") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Product View

    private func productView(_ product: BarcodeProduct) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Product image
                if let imageUrl = product.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure:
                            productPlaceholder
                        case .empty:
                            ProgressView()
                                .frame(height: 200)
                        @unknown default:
                            productPlaceholder
                        }
                    }
                } else {
                    productPlaceholder
                }

                // Product info
                VStack(alignment: .leading, spacing: 8) {
                    Text(product.name)
                        .font(.title2)
                        .fontWeight(.semibold)

                    if let brand = product.brand {
                        Text(brand)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let serving = product.servingSize {
                        Text("Serving: \(serving)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Source badge
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text("From \(product.source.replacingOccurrences(of: "_", with: " ").capitalized)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Serving size adjuster
                servingSizeSection

                // Nutrition card
                nutritionCard(product.nutrition)
            }
            .padding()
        }
        .background(Color.groupedBackground)
    }

    private var productPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.secondary.opacity(0.2))
            .frame(height: 150)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            }
    }

    private var servingSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Servings")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Button {
                    if viewModel.servings > 0.5 {
                        viewModel.servings -= 0.5
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                }

                Text("\(viewModel.servings, specifier: "%.1f")")
                    .font(.title)
                    .fontWeight(.semibold)
                    .frame(minWidth: 60)

                Button {
                    viewModel.servings += 0.5
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundStyle(.blue)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func nutritionCard(_ nutrition: BarcodeNutrition) -> some View {
        let multiplier = viewModel.servings

        return VStack(spacing: 16) {
            Text("Nutrition")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                VStack {
                    Text("\(Int(nutrition.calories * multiplier))")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("cal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack {
                    Text("\(Int(nutrition.proteinG * multiplier))g")
                        .font(.headline)
                    Text("protein")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack {
                    Text("\(Int(nutrition.carbsG * multiplier))g")
                        .font(.headline)
                    Text("carbs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack {
                    Text("\(Int(nutrition.fatG * multiplier))g")
                        .font(.headline)
                    Text("fat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Additional nutrients if available
            if nutrition.fiberG != nil || nutrition.sugarG != nil {
                Divider()

                HStack(spacing: 24) {
                    if let fiber = nutrition.fiberG {
                        VStack {
                            Text("\(Int(fiber * multiplier))g")
                                .font(.subheadline)
                            Text("fiber")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let sugar = nutrition.sugarG {
                        VStack {
                            Text("\(Int(sugar * multiplier))g")
                                .font(.subheadline)
                            Text("sugar")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let sodium = nutrition.sodiumMg {
                        VStack {
                            Text("\(Int(sodium * multiplier))mg")
                                .font(.subheadline)
                            Text("sodium")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - View Model

@MainActor
public final class BarcodeResultViewModel: ObservableObject {

    @Published public var product: BarcodeProduct?
    @Published public var isLoading = false
    @Published public var isLogging = false
    @Published public var error: String?
    @Published public var servings: Double = 1.0

    private let foodService: FoodService

    public init(foodService: FoodService) {
        self.foodService = foodService
    }

    public func lookupBarcode(_ barcode: String) async {
        isLoading = true
        error = nil

        do {
            let response = try await foodService.lookupBarcode(barcode)
            if response.success, let product = response.product {
                self.product = product
            } else {
                self.error = "This product isn't in our database yet."
            }
        } catch {
            self.error = "Could not look up product. Check your connection."
        }

        isLoading = false
    }

    public func logProduct(mealType: FoodLogRecord.MealType) async {
        guard let product = product else { return }

        isLogging = true

        let today = formatDate(Date())
        let nutrition = product.nutrition

        let items = [
            CreateFoodLogItem(
                quantity: servings,
                servingMultiplier: 1,
                nutrition: CreateItemNutrition(
                    calories: nutrition.calories * servings,
                    proteinG: nutrition.proteinG * servings,
                    carbsG: nutrition.carbsG * servings,
                    fatG: nutrition.fatG * servings
                ),
                foodSnapshot: CreateFoodSnapshot(
                    name: product.name,
                    brand: product.brand,
                    servingDescription: product.servingSize
                )
            )
        ]

        let request = CreateFoodLogRequest(
            loggedDate: today,
            mealType: mealType.rawValue,
            entryMethod: "barcode",
            items: items
        )

        do {
            _ = try await foodService.createFoodLog(request)
        } catch {
            self.error = error.localizedDescription
        }

        isLogging = false
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
