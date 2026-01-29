import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import { RDA_VALUES } from "@/lib/usda/client";

/**
 * Get Recommended Daily Allowances (RDA) for micronutrients
 * Based on FDA daily values for adults
 */
export async function GET(request: NextRequest) {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    // Return RDA values with display names and units
    const rda = {
      // Macros
      calories: { value: 2000, unit: "kcal", name: "Calories" },
      proteinG: { value: 50, unit: "g", name: "Protein" },
      fatG: { value: 78, unit: "g", name: "Total Fat" },
      carbsG: { value: 275, unit: "g", name: "Carbohydrates" },
      fiberG: { value: 28, unit: "g", name: "Fiber" },
      sugarG: { value: 50, unit: "g", name: "Sugar" },

      // Vitamins
      vitaminAMcg: { value: 900, unit: "mcg", name: "Vitamin A" },
      vitaminCMg: { value: 90, unit: "mg", name: "Vitamin C" },
      vitaminDMcg: { value: 20, unit: "mcg", name: "Vitamin D" },
      vitaminEMg: { value: 15, unit: "mg", name: "Vitamin E" },
      vitaminKMcg: { value: 120, unit: "mcg", name: "Vitamin K" },
      vitaminB1Mg: { value: 1.2, unit: "mg", name: "Thiamin (B1)" },
      vitaminB2Mg: { value: 1.3, unit: "mg", name: "Riboflavin (B2)" },
      vitaminB3Mg: { value: 16, unit: "mg", name: "Niacin (B3)" },
      vitaminB5Mg: { value: 5, unit: "mg", name: "Pantothenic Acid (B5)" },
      vitaminB6Mg: { value: 1.7, unit: "mg", name: "Vitamin B6" },
      vitaminB9Mcg: { value: 400, unit: "mcg", name: "Folate (B9)" },
      vitaminB12Mcg: { value: 2.4, unit: "mcg", name: "Vitamin B12" },
      cholineMg: { value: 550, unit: "mg", name: "Choline" },

      // Minerals
      calciumMg: { value: 1300, unit: "mg", name: "Calcium" },
      ironMg: { value: 18, unit: "mg", name: "Iron" },
      magnesiumMg: { value: 420, unit: "mg", name: "Magnesium" },
      phosphorusMg: { value: 1250, unit: "mg", name: "Phosphorus" },
      potassiumMg: { value: 4700, unit: "mg", name: "Potassium" },
      sodiumMg: { value: 2300, unit: "mg", name: "Sodium" },
      zincMg: { value: 11, unit: "mg", name: "Zinc" },
      copperMg: { value: 0.9, unit: "mg", name: "Copper" },
      manganeseMg: { value: 2.3, unit: "mg", name: "Manganese" },
      seleniumMcg: { value: 55, unit: "mcg", name: "Selenium" },

      // Lipids
      saturatedFatG: { value: 20, unit: "g", name: "Saturated Fat" },
      transFatG: { value: 0, unit: "g", name: "Trans Fat" },
      cholesterolMg: { value: 300, unit: "mg", name: "Cholesterol" },
    };

    return NextResponse.json({
      success: true,
      data: rda,
    });
  } catch (error) {
    console.error("Error fetching RDA values:", error);
    return NextResponse.json(
      { error: "Failed to fetch RDA values" },
      { status: 500 }
    );
  }
}
