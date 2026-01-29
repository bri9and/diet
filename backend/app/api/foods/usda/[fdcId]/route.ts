import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import { getFoodDetails, extractNutrition } from "@/lib/usda/client";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ fdcId: string }> }
) {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { fdcId } = await params;
    const fdcIdNum = parseInt(fdcId, 10);

    if (isNaN(fdcIdNum)) {
      return NextResponse.json(
        { error: "Invalid FDC ID" },
        { status: 400 }
      );
    }

    // Get food details from USDA
    const food = await getFoodDetails(fdcIdNum);

    // Extract full nutrition data
    const nutrition = extractNutrition(food.foodNutrients);

    // Build response
    const result = {
      _id: `usda_${food.fdcId}`,
      fdcId: food.fdcId,
      source: "usda",
      dataType: food.dataType,
      name: food.description,
      brand: food.brandOwner || null,
      barcode: food.gtinUpc || null,
      category: food.foodCategory || null,
      ingredients: food.ingredients || null,
      servingSize: food.servingSize || 100,
      servingUnit: food.servingSizeUnit || "g",
      servingDescription: food.householdServingFullText || `${food.servingSize || 100}${food.servingSizeUnit || "g"}`,
      nutrition,
      // Include raw nutrients for debugging/advanced users
      rawNutrients: food.foodNutrients.map(n => ({
        id: n.nutrientId,
        name: n.nutrientName,
        amount: n.value,
        unit: n.unitName,
      })),
    };

    return NextResponse.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error("Error fetching USDA food details:", error);
    return NextResponse.json(
      { error: "Failed to fetch food details", details: error instanceof Error ? error.message : "Unknown error" },
      { status: 500 }
    );
  }
}
