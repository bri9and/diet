import SwiftUI

/// View displaying micronutrient intake with progress toward RDA
public struct MicronutrientView: View {
    let nutrition: FullNutrition

    @State private var selectedCategory: NutrientCategory = .vitamins
    @Environment(\.dismiss) private var dismiss

    public init(nutrition: FullNutrition) {
        self.nutrition = nutrition
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Category picker
                    categoryPicker

                    // Nutrient list for selected category
                    nutrientList
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Micronutrients")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        HStack(spacing: 8) {
            ForEach(NutrientCategory.allCases) { category in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = category
                    }
                } label: {
                    Text(category.displayName)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(selectedCategory == category ? category.color : Color.gray.opacity(0.1))
                        .foregroundColor(selectedCategory == category ? .white : .primary)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Nutrient List

    private var nutrientList: some View {
        VStack(spacing: 12) {
            ForEach(nutrients(for: selectedCategory)) { nutrient in
                NutrientRow(nutrient: nutrient, categoryColor: selectedCategory.color)
            }
        }
    }

    // MARK: - Data

    private func nutrients(for category: NutrientCategory) -> [NutrientData] {
        switch category {
        case .vitamins:
            return vitamins
        case .minerals:
            return minerals
        case .lipids:
            return lipids
        }
    }

    private var vitamins: [NutrientData] {
        [
            NutrientData(name: "Vitamin A", value: nutrition.vitaminAMcg, rda: RDAConstants.vitaminAMcg, unit: "mcg"),
            NutrientData(name: "Vitamin C", value: nutrition.vitaminCMg, rda: RDAConstants.vitaminCMg, unit: "mg"),
            NutrientData(name: "Vitamin D", value: nutrition.vitaminDMcg, rda: RDAConstants.vitaminDMcg, unit: "mcg"),
            NutrientData(name: "Vitamin E", value: nutrition.vitaminEMg, rda: RDAConstants.vitaminEMg, unit: "mg"),
            NutrientData(name: "Vitamin K", value: nutrition.vitaminKMcg, rda: RDAConstants.vitaminKMcg, unit: "mcg"),
            NutrientData(name: "Thiamin (B1)", value: nutrition.vitaminB1Mg, rda: RDAConstants.vitaminB1Mg, unit: "mg"),
            NutrientData(name: "Riboflavin (B2)", value: nutrition.vitaminB2Mg, rda: RDAConstants.vitaminB2Mg, unit: "mg"),
            NutrientData(name: "Niacin (B3)", value: nutrition.vitaminB3Mg, rda: RDAConstants.vitaminB3Mg, unit: "mg"),
            NutrientData(name: "Pantothenic Acid (B5)", value: nutrition.vitaminB5Mg, rda: RDAConstants.vitaminB5Mg, unit: "mg"),
            NutrientData(name: "Vitamin B6", value: nutrition.vitaminB6Mg, rda: RDAConstants.vitaminB6Mg, unit: "mg"),
            NutrientData(name: "Folate (B9)", value: nutrition.vitaminB9Mcg, rda: RDAConstants.vitaminB9Mcg, unit: "mcg"),
            NutrientData(name: "Vitamin B12", value: nutrition.vitaminB12Mcg, rda: RDAConstants.vitaminB12Mcg, unit: "mcg"),
            NutrientData(name: "Choline", value: nutrition.cholineMg, rda: RDAConstants.cholineMg, unit: "mg"),
        ]
    }

    private var minerals: [NutrientData] {
        [
            NutrientData(name: "Calcium", value: nutrition.calciumMg, rda: RDAConstants.calciumMg, unit: "mg"),
            NutrientData(name: "Iron", value: nutrition.ironMg, rda: RDAConstants.ironMg, unit: "mg"),
            NutrientData(name: "Magnesium", value: nutrition.magnesiumMg, rda: RDAConstants.magnesiumMg, unit: "mg"),
            NutrientData(name: "Phosphorus", value: nutrition.phosphorusMg, rda: RDAConstants.phosphorusMg, unit: "mg"),
            NutrientData(name: "Potassium", value: nutrition.potassiumMg, rda: RDAConstants.potassiumMg, unit: "mg"),
            NutrientData(name: "Sodium", value: nutrition.sodiumMg, rda: RDAConstants.sodiumMg, unit: "mg", isLimitNutrient: true),
            NutrientData(name: "Zinc", value: nutrition.zincMg, rda: RDAConstants.zincMg, unit: "mg"),
            NutrientData(name: "Copper", value: nutrition.copperMg, rda: RDAConstants.copperMg, unit: "mg"),
            NutrientData(name: "Manganese", value: nutrition.manganeseMg, rda: RDAConstants.manganeseMg, unit: "mg"),
            NutrientData(name: "Selenium", value: nutrition.seleniumMcg, rda: RDAConstants.seleniumMcg, unit: "mcg"),
        ]
    }

    private var lipids: [NutrientData] {
        [
            NutrientData(name: "Saturated Fat", value: nutrition.saturatedFatG, rda: RDAConstants.saturatedFatG, unit: "g", isLimitNutrient: true),
            NutrientData(name: "Monounsaturated Fat", value: nutrition.monounsaturatedFatG, rda: nil, unit: "g"),
            NutrientData(name: "Polyunsaturated Fat", value: nutrition.polyunsaturatedFatG, rda: nil, unit: "g"),
            NutrientData(name: "Trans Fat", value: nutrition.transFatG, rda: 0, unit: "g", isLimitNutrient: true),
            NutrientData(name: "Cholesterol", value: nutrition.cholesterolMg, rda: RDAConstants.cholesterolMg, unit: "mg", isLimitNutrient: true),
        ]
    }
}

// MARK: - Supporting Types

enum NutrientCategory: String, CaseIterable, Identifiable {
    case vitamins
    case minerals
    case lipids

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vitamins: return "Vitamins"
        case .minerals: return "Minerals"
        case .lipids: return "Lipids"
        }
    }

    var color: Color {
        switch self {
        case .vitamins: return .orange
        case .minerals: return .teal
        case .lipids: return .purple
        }
    }
}

struct NutrientData: Identifiable {
    let id = UUID()
    let name: String
    let value: Double?
    let rda: Double?
    let unit: String
    var isLimitNutrient: Bool = false

    var percentage: Double? {
        guard let value = value, let rda = rda, rda > 0 else { return nil }
        return (value / rda) * 100
    }

    var formattedValue: String {
        guard let value = value else { return "--" }
        if value < 1 {
            return String(format: "%.2f", value)
        } else if value < 10 {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.0f", value)
        }
    }
}

// MARK: - Nutrient Row

struct NutrientRow: View {
    let nutrient: NutrientData
    let categoryColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(nutrient.name)
                    .font(.subheadline.weight(.medium))

                Spacer()

                if let value = nutrient.value {
                    Text("\(nutrient.formattedValue) \(nutrient.unit)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let percentage = nutrient.percentage {
                        Text("(\(Int(percentage))%)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(progressColor(percentage: percentage))
                    }
                } else {
                    Text("No data")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }

            if let percentage = nutrient.percentage {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 8)

                        // Progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressColor(percentage: percentage))
                            .frame(width: min(geometry.size.width * CGFloat(percentage / 100), geometry.size.width), height: 8)
                            .animation(.spring(response: 0.5), value: percentage)
                    }
                }
                .frame(height: 8)
            } else if nutrient.value != nil {
                // Show a subtle indicator for nutrients without RDA
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 8)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func progressColor(percentage: Double) -> Color {
        if nutrient.isLimitNutrient {
            // For limit nutrients (sodium, saturated fat, etc.), red is bad
            if percentage > 100 {
                return .red
            } else if percentage > 75 {
                return .orange
            } else {
                return .green
            }
        } else {
            // For beneficial nutrients, green is good
            if percentage >= 100 {
                return .green
            } else if percentage >= 50 {
                return categoryColor
            } else if percentage >= 25 {
                return .orange
            } else {
                return .red.opacity(0.7)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MicronutrientView(
        nutrition: FullNutrition(
            calories: 1500,
            proteinG: 80,
            fatG: 50,
            carbsG: 180,
            fiberG: 25,
            sugarG: 40,
            vitaminAMcg: 600,
            vitaminCMg: 45,
            vitaminDMcg: 10,
            vitaminEMg: 8,
            vitaminKMcg: 80,
            vitaminB1Mg: 0.8,
            vitaminB2Mg: 1.0,
            vitaminB3Mg: 12,
            vitaminB5Mg: 3,
            vitaminB6Mg: 1.2,
            vitaminB9Mcg: 250,
            vitaminB12Mcg: 1.8,
            cholineMg: 300,
            calciumMg: 800,
            ironMg: 12,
            magnesiumMg: 280,
            phosphorusMg: 900,
            potassiumMg: 2500,
            sodiumMg: 1800,
            zincMg: 8,
            copperMg: 0.6,
            manganeseMg: 1.5,
            seleniumMcg: 35,
            saturatedFatG: 15,
            monounsaturatedFatG: 20,
            polyunsaturatedFatG: 10,
            transFatG: 0.5,
            cholesterolMg: 200
        )
    )
}
