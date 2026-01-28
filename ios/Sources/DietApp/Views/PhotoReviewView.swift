import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// View for reviewing photo analysis results and confirming food logging
public struct PhotoReviewView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PhotoReviewViewModel

    let imageData: Data
    let mealType: FoodLogRecord.MealType
    let onFoodLogged: () -> Void

    // MARK: - Initialization

    public init(
        imageData: Data,
        mealType: FoodLogRecord.MealType,
        foodService: FoodService,
        onFoodLogged: @escaping () -> Void
    ) {
        self.imageData = imageData
        self.mealType = mealType
        self.onFoodLogged = onFoodLogged
        _viewModel = StateObject(wrappedValue: PhotoReviewViewModel(foodService: foodService))
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo preview
                    photoPreview

                    // Analysis results
                    if viewModel.isAnalyzing {
                        analyzingView
                    } else if let error = viewModel.error {
                        errorView(error)
                    } else if !viewModel.analyzedItems.isEmpty {
                        analysisResultsView
                    }
                }
                .padding()
            }
            .background(Color.groupedBackground)
            .navigationTitle("Review Meal")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Log Meal") {
                        Task {
                            await viewModel.logMeal(mealType: mealType)
                            onFoodLogged()
                            dismiss()
                        }
                    }
                    .disabled(viewModel.analyzedItems.isEmpty || viewModel.isLogging)
                }
            }
        }
        .task {
            await viewModel.analyzePhoto(imageData: imageData)
        }
    }

    // MARK: - Photo Preview

    private var photoPreview: some View {
        Group {
            #if canImport(UIKit)
            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            #else
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 250)
                .overlay {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            #endif
        }
    }

    // MARK: - Analyzing View

    private var analyzingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Analyzing your meal...")
                .font(.headline)

            Text("Our AI is identifying the foods in your photo")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Analysis Failed")
                .font(.headline)

            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await viewModel.analyzePhoto(imageData: imageData)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Analysis Results

    private var analysisResultsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("We identified:")
                    .font(.headline)

                Spacer()

                if let confidence = viewModel.confidence {
                    HStack(spacing: 4) {
                        Image(systemName: confidenceIcon(confidence))
                            .foregroundStyle(confidenceColor(confidence))

                        Text("\(Int(confidence * 100))% confident")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Food items
            ForEach(viewModel.analyzedItems) { item in
                foodItemCard(item)
            }

            // Total nutrition
            totalNutritionCard
        }
    }

    private func foodItemCard(_ item: AnalyzedFoodItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body)
                    .fontWeight(.medium)

                Text("\(item.quantity, specifier: "%.1f") \(item.unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(item.nutrition.calories)) cal")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text("P: \(Int(item.nutrition.proteinG))g")
                    Text("C: \(Int(item.nutrition.carbsG))g")
                    Text("F: \(Int(item.nutrition.fatG))g")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var totalNutritionCard: some View {
        let totals = viewModel.totalNutrition

        return VStack(spacing: 12) {
            Text("Total")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                VStack {
                    Text("\(Int(totals.calories))")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("cal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack {
                    Text("\(Int(totals.protein))g")
                        .font(.headline)
                    Text("protein")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack {
                    Text("\(Int(totals.carbs))g")
                        .font(.headline)
                    Text("carbs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack {
                    Text("\(Int(totals.fat))g")
                        .font(.headline)
                    Text("fat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func confidenceIcon(_ confidence: Double) -> String {
        if confidence >= 0.8 { return "checkmark.circle.fill" }
        if confidence >= 0.6 { return "checkmark.circle" }
        return "questionmark.circle"
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.6 { return .orange }
        return .red
    }
}

// MARK: - View Model

@MainActor
public final class PhotoReviewViewModel: ObservableObject {

    // MARK: - Published State

    @Published public var analyzedItems: [AnalyzedFoodItem] = []
    @Published public var confidence: Double?
    @Published public var isAnalyzing = false
    @Published public var isLogging = false
    @Published public var error: String?

    // MARK: - Dependencies

    private let foodService: FoodService

    // MARK: - Computed Properties

    public var totalNutrition: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let calories = analyzedItems.reduce(0) { $0 + $1.nutrition.calories }
        let protein = analyzedItems.reduce(0) { $0 + $1.nutrition.proteinG }
        let carbs = analyzedItems.reduce(0) { $0 + $1.nutrition.carbsG }
        let fat = analyzedItems.reduce(0) { $0 + $1.nutrition.fatG }
        return (calories, protein, carbs, fat)
    }

    // MARK: - Initialization

    public init(foodService: FoodService) {
        self.foodService = foodService
    }

    // MARK: - Methods

    public func analyzePhoto(imageData: Data) async {
        isAnalyzing = true
        error = nil

        do {
            let response = try await foodService.analyzePhoto(imageData: imageData)
            analyzedItems = response.items
            confidence = response.confidence
        } catch {
            self.error = error.localizedDescription
        }

        isAnalyzing = false
    }

    public func logMeal(mealType: FoodLogRecord.MealType) async {
        guard !analyzedItems.isEmpty else { return }

        isLogging = true

        let today = formatDate(Date())
        let items = analyzedItems.map { item in
            CreateFoodLogItem(
                quantity: item.quantity,
                servingMultiplier: 1,
                nutrition: CreateItemNutrition(
                    calories: item.nutrition.calories,
                    proteinG: item.nutrition.proteinG,
                    carbsG: item.nutrition.carbsG,
                    fatG: item.nutrition.fatG
                ),
                foodSnapshot: CreateFoodSnapshot(
                    name: item.name,
                    servingDescription: "\(item.quantity) \(item.unit)"
                )
            )
        }

        let request = CreateFoodLogRequest(
            loggedDate: today,
            mealType: mealType.rawValue,
            entryMethod: "photo_ai",
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
