import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";

interface OpenFoodFactsProduct {
  code: string;
  product_name?: string;
  brands?: string;
  serving_size?: string;
  nutriments?: {
    "energy-kcal_100g"?: number;
    "energy-kcal_serving"?: number;
    proteins_100g?: number;
    proteins_serving?: number;
    carbohydrates_100g?: number;
    carbohydrates_serving?: number;
    fat_100g?: number;
    fat_serving?: number;
    fiber_100g?: number;
    fiber_serving?: number;
    sugars_100g?: number;
    sugars_serving?: number;
    sodium_100g?: number;
    sodium_serving?: number;
  };
  image_url?: string;
}

interface OpenFoodFactsResponse {
  count: number;
  page: number;
  page_size: number;
  products: OpenFoodFactsProduct[];
}

export async function GET(request: NextRequest) {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const searchParams = request.nextUrl.searchParams;
    const query = searchParams.get("q");
    const limit = parseInt(searchParams.get("limit") || "20", 10);

    if (!query || query.length < 2) {
      return NextResponse.json(
        { error: "Search query must be at least 2 characters" },
        { status: 400 }
      );
    }

    // Search Open Food Facts API
    const searchUrl = new URL("https://world.openfoodfacts.org/cgi/search.pl");
    searchUrl.searchParams.set("search_terms", query);
    searchUrl.searchParams.set("search_simple", "1");
    searchUrl.searchParams.set("action", "process");
    searchUrl.searchParams.set("json", "1");
    searchUrl.searchParams.set("page_size", String(limit));
    searchUrl.searchParams.set("fields", "code,product_name,brands,serving_size,nutriments,image_url");

    const response = await fetch(searchUrl.toString(), {
      headers: {
        "User-Agent": "DietApp/1.0 (contact@dietapp.com)",
      },
    });

    if (!response.ok) {
      throw new Error(`Open Food Facts API error: ${response.status}`);
    }

    const data: OpenFoodFactsResponse = await response.json();

    // Transform to our API format
    const foods = data.products
      .filter((p) => p.product_name && p.nutriments)
      .map((product) => {
        const n = product.nutriments || {};

        // Prefer per-serving values, fall back to per-100g
        const calories = n["energy-kcal_serving"] || n["energy-kcal_100g"] || 0;
        const protein = n.proteins_serving || n.proteins_100g || 0;
        const carbs = n.carbohydrates_serving || n.carbohydrates_100g || 0;
        const fat = n.fat_serving || n.fat_100g || 0;
        const fiber = n.fiber_serving || n.fiber_100g || 0;
        const sugar = n.sugars_serving || n.sugars_100g || 0;
        const sodium = (n.sodium_serving || n.sodium_100g || 0) * 1000; // Convert g to mg

        return {
          id: `off_${product.code}`,
          name: product.product_name || "Unknown",
          brand: product.brands || null,
          servingDescription: product.serving_size || "1 serving (100g)",
          nutrition: {
            calories: Math.round(calories),
            proteinG: Math.round(protein * 10) / 10,
            carbsG: Math.round(carbs * 10) / 10,
            fatG: Math.round(fat * 10) / 10,
            fiberG: Math.round(fiber * 10) / 10,
            sugarG: Math.round(sugar * 10) / 10,
            sodiumMg: Math.round(sodium),
          },
          imageUrl: product.image_url || null,
          source: "open_food_facts",
        };
      });

    return NextResponse.json({
      data: foods,
      query,
      count: foods.length,
    });
  } catch (error) {
    console.error("Error searching foods:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
