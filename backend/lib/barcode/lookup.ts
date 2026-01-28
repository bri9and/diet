/**
 * Barcode lookup service using Open Food Facts API
 * Free, open-source food product database
 */

export interface BarcodeProduct {
  barcode: string;
  name: string;
  brand?: string;
  servingSize?: string;
  servingUnit?: string;
  nutrition: {
    calories: number;
    proteinG: number;
    carbsG: number;
    fatG: number;
    fiberG?: number;
    sugarG?: number;
    sodiumMg?: number;
  };
  imageUrl?: string;
  source: "open_food_facts" | "nutritionix";
}

export interface LookupResult {
  found: boolean;
  product?: BarcodeProduct;
  error?: string;
}

/**
 * Look up a product by barcode using Open Food Facts
 */
export async function lookupBarcode(barcode: string): Promise<LookupResult> {
  // Validate barcode format (UPC-A, EAN-13, etc.)
  const cleanBarcode = barcode.replace(/[^0-9]/g, "");

  if (cleanBarcode.length < 8 || cleanBarcode.length > 14) {
    return { found: false, error: "Invalid barcode format" };
  }

  try {
    // Try Open Food Facts first
    const result = await lookupOpenFoodFacts(cleanBarcode);
    if (result.found) {
      return result;
    }

    // Could add Nutritionix as fallback here if API key is configured
    if (process.env.NUTRITIONIX_APP_ID && process.env.NUTRITIONIX_API_KEY) {
      const nutritionixResult = await lookupNutritionix(cleanBarcode);
      if (nutritionixResult.found) {
        return nutritionixResult;
      }
    }

    return { found: false, error: "Product not found" };
  } catch (error) {
    console.error("Barcode lookup error:", error);
    return {
      found: false,
      error: error instanceof Error ? error.message : "Lookup failed"
    };
  }
}

/**
 * Open Food Facts API lookup
 */
async function lookupOpenFoodFacts(barcode: string): Promise<LookupResult> {
  const response = await fetch(
    `https://world.openfoodfacts.org/api/v2/product/${barcode}.json`,
    {
      headers: {
        "User-Agent": "DietApp/1.0 (contact@example.com)",
      },
    }
  );

  if (!response.ok) {
    return { found: false };
  }

  const data = await response.json();

  if (data.status !== 1 || !data.product) {
    return { found: false };
  }

  const product = data.product;
  const nutriments = product.nutriments || {};

  // Extract serving size
  let servingSize = product.serving_size || "100g";
  let servingUnit = "serving";

  // Parse serving size if it's like "30g" or "1 cup (240ml)"
  const servingMatch = servingSize.match(/^(\d+(?:\.\d+)?)\s*([a-zA-Z]+)/);
  if (servingMatch) {
    servingSize = servingMatch[1];
    servingUnit = servingMatch[2];
  }

  // Get nutrition per serving, fallback to per 100g
  const perServing = nutriments["energy-kcal_serving"] !== undefined;
  const suffix = perServing ? "_serving" : "_100g";

  return {
    found: true,
    product: {
      barcode,
      name: product.product_name || product.product_name_en || "Unknown Product",
      brand: product.brands,
      servingSize: product.serving_size || "100g",
      servingUnit,
      nutrition: {
        calories: nutriments[`energy-kcal${suffix}`] || nutriments[`energy${suffix}`] / 4.184 || 0,
        proteinG: nutriments[`proteins${suffix}`] || 0,
        carbsG: nutriments[`carbohydrates${suffix}`] || 0,
        fatG: nutriments[`fat${suffix}`] || 0,
        fiberG: nutriments[`fiber${suffix}`],
        sugarG: nutriments[`sugars${suffix}`],
        sodiumMg: nutriments[`sodium${suffix}`] ? nutriments[`sodium${suffix}`] * 1000 : undefined,
      },
      imageUrl: product.image_front_url || product.image_url,
      source: "open_food_facts",
    },
  };
}

/**
 * Nutritionix API lookup (requires API key)
 */
async function lookupNutritionix(barcode: string): Promise<LookupResult> {
  const appId = process.env.NUTRITIONIX_APP_ID;
  const apiKey = process.env.NUTRITIONIX_API_KEY;

  if (!appId || !apiKey) {
    return { found: false };
  }

  const response = await fetch(
    `https://trackapi.nutritionix.com/v2/search/item?upc=${barcode}`,
    {
      headers: {
        "x-app-id": appId,
        "x-app-key": apiKey,
      },
    }
  );

  if (!response.ok) {
    return { found: false };
  }

  const data = await response.json();
  const food = data.foods?.[0];

  if (!food) {
    return { found: false };
  }

  return {
    found: true,
    product: {
      barcode,
      name: food.food_name,
      brand: food.brand_name,
      servingSize: `${food.serving_qty} ${food.serving_unit}`,
      servingUnit: food.serving_unit,
      nutrition: {
        calories: food.nf_calories || 0,
        proteinG: food.nf_protein || 0,
        carbsG: food.nf_total_carbohydrate || 0,
        fatG: food.nf_total_fat || 0,
        fiberG: food.nf_dietary_fiber,
        sugarG: food.nf_sugars,
        sodiumMg: food.nf_sodium,
      },
      imageUrl: food.photo?.thumb,
      source: "nutritionix",
    },
  };
}
