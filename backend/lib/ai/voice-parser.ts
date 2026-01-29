/**
 * Voice/text food parsing using AI
 * Converts natural language food descriptions to structured data
 */

export interface ParsedFoodItem {
  name: string;
  quantity: number;
  unit: string;
  estimatedCalories: number;
  estimatedProtein: number;
  estimatedCarbs: number;
  estimatedFat: number;
  confidence: number;
}

export interface VoiceParseResult {
  items: ParsedFoodItem[];
  confidence: number;
  provider: string;
}

const FOOD_PARSE_PROMPT = `Parse the following food description and identify all food items mentioned.

For each food item, provide:
1. Name of the food
2. Quantity and unit (e.g., "2 eggs", "1 cup rice", "1 medium apple")
3. Estimated nutritional values:
   - Calories
   - Protein (grams)
   - Carbohydrates (grams)
   - Fat (grams)
4. Confidence level (0-1)

Return ONLY a valid JSON object in this exact format:
{
  "items": [
    {
      "name": "scrambled eggs",
      "quantity": 2,
      "unit": "large",
      "estimatedCalories": 180,
      "estimatedProtein": 12,
      "estimatedCarbs": 2,
      "estimatedFat": 14,
      "confidence": 0.9
    }
  ],
  "confidence": 0.85
}

Be conservative with estimates. If the quantity is unclear, assume a typical single serving.
If no food is detected, return: {"items": [], "confidence": 0}

Food description: `;

/**
 * Parse food description using OpenAI
 */
async function parseWithOpenAI(text: string): Promise<VoiceParseResult> {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) throw new Error("OpenAI not configured");

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "user",
          content: FOOD_PARSE_PROMPT + text,
        },
      ],
      max_tokens: 1000,
      temperature: 0.2,
    }),
  });

  if (!response.ok) {
    throw new Error(`OpenAI error: ${await response.text()}`);
  }

  const data = await response.json();
  const content = data.choices[0]?.message?.content;

  return { ...parseResponse(content), provider: "openai" };
}

/**
 * Parse food description using Gemini
 */
async function parseWithGemini(text: string): Promise<VoiceParseResult> {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) throw new Error("Gemini not configured");

  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: FOOD_PARSE_PROMPT + text }] }],
        generationConfig: { temperature: 0.2, maxOutputTokens: 1000 },
      }),
    }
  );

  if (!response.ok) {
    throw new Error(`Gemini error: ${await response.text()}`);
  }

  const data = await response.json();
  const content = data.candidates?.[0]?.content?.parts?.[0]?.text;

  return { ...parseResponse(content), provider: "gemini" };
}

function parseResponse(content: string): Omit<VoiceParseResult, "provider"> {
  try {
    const jsonMatch = content.match(/```json\n?([\s\S]*?)\n?```/) ||
                      content.match(/```\n?([\s\S]*?)\n?```/) ||
                      [null, content];
    const jsonStr = jsonMatch[1] || content;
    const result = JSON.parse(jsonStr.trim());

    return {
      items: result.items || [],
      confidence: result.confidence || 0,
    };
  } catch {
    console.error("Failed to parse AI response:", content);
    return { items: [], confidence: 0 };
  }
}

/**
 * Parse food description with fallback between providers
 */
export async function parseFoodDescription(text: string): Promise<VoiceParseResult> {
  const providers = [];

  if (process.env.OPENAI_API_KEY) {
    providers.push(() => parseWithOpenAI(text));
  }
  if (process.env.GEMINI_API_KEY) {
    providers.push(() => parseWithGemini(text));
  }

  if (providers.length === 0) {
    throw new Error("No AI provider configured");
  }

  for (const provider of providers) {
    try {
      return await provider();
    } catch (error) {
      console.error("Provider failed:", error);
    }
  }

  throw new Error("All AI providers failed");
}
