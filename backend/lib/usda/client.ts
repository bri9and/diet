/**
 * USDA FoodData Central API Client
 * https://fdc.nal.usda.gov/api-guide/
 *
 * Free API with 1,000 requests/hour limit
 */

const USDA_BASE_URL = "https://api.nal.usda.gov/fdc/v1";

// Use environment variable or DEMO_KEY for testing
const getApiKey = () => process.env.USDA_API_KEY || "DEMO_KEY";

// Nutrient IDs we want to track (USDA nutrient numbers)
export const NUTRIENT_IDS = {
  // Macros
  energy: 208,        // Energy (kcal)
  protein: 203,       // Protein (g)
  fat: 204,           // Total fat (g)
  carbs: 205,         // Carbohydrates (g)
  fiber: 291,         // Fiber (g)
  sugar: 269,         // Sugars (g)

  // Vitamins
  vitaminA: 320,      // Vitamin A, RAE (mcg)
  vitaminC: 401,      // Vitamin C (mg)
  vitaminD: 328,      // Vitamin D (D2 + D3) (mcg)
  vitaminE: 323,      // Vitamin E (mg)
  vitaminK: 430,      // Vitamin K (mcg)
  vitaminB1: 404,     // Thiamin (mg)
  vitaminB2: 405,     // Riboflavin (mg)
  vitaminB3: 406,     // Niacin (mg)
  vitaminB5: 410,     // Pantothenic acid (mg)
  vitaminB6: 415,     // Vitamin B6 (mg)
  vitaminB9: 435,     // Folate, DFE (mcg)
  vitaminB12: 418,    // Vitamin B12 (mcg)
  choline: 421,       // Choline (mg)

  // Minerals
  calcium: 301,       // Calcium (mg)
  iron: 303,          // Iron (mg)
  magnesium: 304,     // Magnesium (mg)
  phosphorus: 305,    // Phosphorus (mg)
  potassium: 306,     // Potassium (mg)
  sodium: 307,        // Sodium (mg)
  zinc: 309,          // Zinc (mg)
  copper: 312,        // Copper (mg)
  manganese: 315,     // Manganese (mg)
  selenium: 317,      // Selenium (mcg)

  // Lipids
  saturatedFat: 606,  // Saturated fat (g)
  monounsaturatedFat: 645, // Monounsaturated fat (g)
  polyunsaturatedFat: 646, // Polyunsaturated fat (g)
  transFat: 605,      // Trans fat (g)
  cholesterol: 601,   // Cholesterol (mg)
};

// All nutrient numbers as array for API requests
export const ALL_NUTRIENT_NUMBERS = Object.values(NUTRIENT_IDS);

export interface USDAFoodNutrient {
  nutrientId: number;
  nutrientName: string;
  nutrientNumber: string;
  unitName: string;
  value: number;
}

export interface USDAFood {
  fdcId: number;
  description: string;
  dataType: string;
  brandOwner?: string;
  brandName?: string;
  gtinUpc?: string;
  ingredients?: string;
  servingSize?: number;
  servingSizeUnit?: string;
  householdServingFullText?: string;
  foodNutrients: USDAFoodNutrient[];
  foodCategory?: string;
  publishedDate?: string;
}

export interface USDASearchResponse {
  totalHits: number;
  currentPage: number;
  totalPages: number;
  foods: USDAFood[];
}

export interface USDAFoodDetails extends USDAFood {
  labelNutrients?: Record<string, { value: number }>;
}

/**
 * Search USDA FoodData Central
 */
export async function searchFoods(
  query: string,
  options: {
    dataType?: ("Foundation" | "SR Legacy" | "Branded" | "Survey (FNDDS)")[];
    pageSize?: number;
    pageNumber?: number;
    brandOwner?: string;
  } = {}
): Promise<USDASearchResponse> {
  const apiKey = getApiKey();

  const response = await fetch(`${USDA_BASE_URL}/foods/search?api_key=${apiKey}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      query,
      dataType: options.dataType || ["SR Legacy", "Foundation", "Branded"],
      pageSize: options.pageSize || 25,
      pageNumber: options.pageNumber || 1,
      brandOwner: options.brandOwner,
    }),
  });

  if (!response.ok) {
    throw new Error(`USDA API error: ${response.status} ${response.statusText}`);
  }

  return response.json();
}

/**
 * Get detailed food information by FDC ID
 */
export async function getFoodDetails(fdcId: number): Promise<USDAFoodDetails> {
  const apiKey = getApiKey();

  // Request specific nutrients to reduce response size
  const nutrientParams = ALL_NUTRIENT_NUMBERS.map(n => `nutrients=${n}`).join("&");

  const response = await fetch(
    `${USDA_BASE_URL}/food/${fdcId}?api_key=${apiKey}&${nutrientParams}`,
    {
      headers: {
        "Content-Type": "application/json",
      },
    }
  );

  if (!response.ok) {
    throw new Error(`USDA API error: ${response.status} ${response.statusText}`);
  }

  return response.json();
}

/**
 * Get multiple foods by FDC IDs (max 20 per request)
 */
export async function getMultipleFoods(fdcIds: number[]): Promise<USDAFoodDetails[]> {
  const apiKey = getApiKey();

  if (fdcIds.length > 20) {
    throw new Error("Maximum 20 FDC IDs per request");
  }

  const response = await fetch(`${USDA_BASE_URL}/foods?api_key=${apiKey}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      fdcIds,
      format: "full",
      nutrients: ALL_NUTRIENT_NUMBERS,
    }),
  });

  if (!response.ok) {
    throw new Error(`USDA API error: ${response.status} ${response.statusText}`);
  }

  return response.json();
}

/**
 * Extract nutrition values from USDA food nutrients array
 */
export function extractNutrition(foodNutrients: USDAFoodNutrient[]): MicronutrientData {
  const getNutrient = (nutrientId: number): number | undefined => {
    const nutrient = foodNutrients.find(n => n.nutrientId === nutrientId);
    return nutrient?.value;
  };

  return {
    // Macros
    calories: getNutrient(NUTRIENT_IDS.energy) || 0,
    proteinG: getNutrient(NUTRIENT_IDS.protein) || 0,
    fatG: getNutrient(NUTRIENT_IDS.fat) || 0,
    carbsG: getNutrient(NUTRIENT_IDS.carbs) || 0,
    fiberG: getNutrient(NUTRIENT_IDS.fiber),
    sugarG: getNutrient(NUTRIENT_IDS.sugar),

    // Vitamins
    vitaminAMcg: getNutrient(NUTRIENT_IDS.vitaminA),
    vitaminCMg: getNutrient(NUTRIENT_IDS.vitaminC),
    vitaminDMcg: getNutrient(NUTRIENT_IDS.vitaminD),
    vitaminEMg: getNutrient(NUTRIENT_IDS.vitaminE),
    vitaminKMcg: getNutrient(NUTRIENT_IDS.vitaminK),
    vitaminB1Mg: getNutrient(NUTRIENT_IDS.vitaminB1),
    vitaminB2Mg: getNutrient(NUTRIENT_IDS.vitaminB2),
    vitaminB3Mg: getNutrient(NUTRIENT_IDS.vitaminB3),
    vitaminB5Mg: getNutrient(NUTRIENT_IDS.vitaminB5),
    vitaminB6Mg: getNutrient(NUTRIENT_IDS.vitaminB6),
    vitaminB9Mcg: getNutrient(NUTRIENT_IDS.vitaminB9),
    vitaminB12Mcg: getNutrient(NUTRIENT_IDS.vitaminB12),
    cholineMg: getNutrient(NUTRIENT_IDS.choline),

    // Minerals
    calciumMg: getNutrient(NUTRIENT_IDS.calcium),
    ironMg: getNutrient(NUTRIENT_IDS.iron),
    magnesiumMg: getNutrient(NUTRIENT_IDS.magnesium),
    phosphorusMg: getNutrient(NUTRIENT_IDS.phosphorus),
    potassiumMg: getNutrient(NUTRIENT_IDS.potassium),
    sodiumMg: getNutrient(NUTRIENT_IDS.sodium),
    zincMg: getNutrient(NUTRIENT_IDS.zinc),
    copperMg: getNutrient(NUTRIENT_IDS.copper),
    manganeseMg: getNutrient(NUTRIENT_IDS.manganese),
    seleniumMcg: getNutrient(NUTRIENT_IDS.selenium),

    // Lipids
    saturatedFatG: getNutrient(NUTRIENT_IDS.saturatedFat),
    monounsaturatedFatG: getNutrient(NUTRIENT_IDS.monounsaturatedFat),
    polyunsaturatedFatG: getNutrient(NUTRIENT_IDS.polyunsaturatedFat),
    transFatG: getNutrient(NUTRIENT_IDS.transFat),
    cholesterolMg: getNutrient(NUTRIENT_IDS.cholesterol),
  };
}

/**
 * Full micronutrient data structure
 */
export interface MicronutrientData {
  // Macros (required)
  calories: number;
  proteinG: number;
  fatG: number;
  carbsG: number;

  // Macros (optional)
  fiberG?: number;
  sugarG?: number;

  // Vitamins
  vitaminAMcg?: number;
  vitaminCMg?: number;
  vitaminDMcg?: number;
  vitaminEMg?: number;
  vitaminKMcg?: number;
  vitaminB1Mg?: number;
  vitaminB2Mg?: number;
  vitaminB3Mg?: number;
  vitaminB5Mg?: number;
  vitaminB6Mg?: number;
  vitaminB9Mcg?: number;
  vitaminB12Mcg?: number;
  cholineMg?: number;

  // Minerals
  calciumMg?: number;
  ironMg?: number;
  magnesiumMg?: number;
  phosphorusMg?: number;
  potassiumMg?: number;
  sodiumMg?: number;
  zincMg?: number;
  copperMg?: number;
  manganeseMg?: number;
  seleniumMcg?: number;

  // Lipids
  saturatedFatG?: number;
  monounsaturatedFatG?: number;
  polyunsaturatedFatG?: number;
  transFatG?: number;
  cholesterolMg?: number;
}

/**
 * RDA (Recommended Daily Allowances) for adults
 * Based on FDA daily values
 */
export const RDA_VALUES: Record<keyof MicronutrientData, number | undefined> = {
  calories: 2000,
  proteinG: 50,
  fatG: 78,
  carbsG: 275,
  fiberG: 28,
  sugarG: 50,

  // Vitamins
  vitaminAMcg: 900,
  vitaminCMg: 90,
  vitaminDMcg: 20,
  vitaminEMg: 15,
  vitaminKMcg: 120,
  vitaminB1Mg: 1.2,
  vitaminB2Mg: 1.3,
  vitaminB3Mg: 16,
  vitaminB5Mg: 5,
  vitaminB6Mg: 1.7,
  vitaminB9Mcg: 400,
  vitaminB12Mcg: 2.4,
  cholineMg: 550,

  // Minerals
  calciumMg: 1300,
  ironMg: 18,
  magnesiumMg: 420,
  phosphorusMg: 1250,
  potassiumMg: 4700,
  sodiumMg: 2300,
  zincMg: 11,
  copperMg: 0.9,
  manganeseMg: 2.3,
  seleniumMcg: 55,

  // Lipids
  saturatedFatG: 20,
  monounsaturatedFatG: undefined, // No RDA
  polyunsaturatedFatG: undefined, // No RDA
  transFatG: 0, // Should be as low as possible
  cholesterolMg: 300,
};
