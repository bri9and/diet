import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import { searchFoods, extractNutrition } from "@/lib/usda/client";

export async function GET(request: NextRequest) {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const searchParams = request.nextUrl.searchParams;
    const query = searchParams.get("q");
    const limit = parseInt(searchParams.get("limit") || "25", 10);
    const page = parseInt(searchParams.get("page") || "1", 10);
    const dataType = searchParams.get("dataType"); // Optional: Foundation, SR Legacy, Branded

    if (!query || query.length < 2) {
      return NextResponse.json(
        { error: "Search query must be at least 2 characters" },
        { status: 400 }
      );
    }

    // Parse data types
    let dataTypes: ("Foundation" | "SR Legacy" | "Branded" | "Survey (FNDDS)")[] | undefined;
    if (dataType) {
      dataTypes = dataType.split(",") as any;
    }

    // Search USDA
    const response = await searchFoods(query, {
      pageSize: Math.min(limit, 50),
      pageNumber: page,
      dataType: dataTypes,
    });

    // Transform to our API format
    const foods = response.foods.map((food) => {
      const nutrition = extractNutrition(food.foodNutrients);

      return {
        _id: `usda_${food.fdcId}`,
        fdcId: food.fdcId,
        source: "usda",
        dataType: food.dataType,
        name: food.description,
        brand: food.brandOwner || food.brandName || null,
        barcode: food.gtinUpc || null,
        category: food.foodCategory || null,
        servingSize: food.servingSize || 100,
        servingUnit: food.servingSizeUnit || "g",
        servingDescription: food.householdServingFullText || `${food.servingSize || 100}${food.servingSizeUnit || "g"}`,
        nutrition,
      };
    });

    return NextResponse.json({
      success: true,
      data: foods,
      query,
      totalHits: response.totalHits,
      currentPage: response.currentPage,
      totalPages: response.totalPages,
    });
  } catch (error) {
    console.error("Error searching USDA foods:", error);
    return NextResponse.json(
      { error: "Failed to search foods", details: error instanceof Error ? error.message : "Unknown error" },
      { status: 500 }
    );
  }
}
