/**
 * AI Provider abstractions for food photo analysis
 * Supports OpenAI Vision and Google Gemini
 */

export interface FoodAnalysisResult {
  items: FoodItem[];
  confidence: number;
  rawResponse?: string;
}

export interface FoodItem {
  name: string;
  quantity: number;
  unit: string;
  estimatedCalories: number;
  estimatedProtein: number;
  estimatedCarbs: number;
  estimatedFat: number;
  confidence: number;
}

export interface AIProvider {
  name: string;
  analyzePhoto(base64Image: string, mimeType: string): Promise<FoodAnalysisResult>;
}

const FOOD_ANALYSIS_PROMPT = `Analyze this food photo and identify all food items visible.

For each food item, provide:
1. Name of the food
2. Estimated quantity and unit (e.g., "1 cup", "200g", "1 medium")
3. Estimated nutritional values per the quantity shown:
   - Calories
   - Protein (grams)
   - Carbohydrates (grams)
   - Fat (grams)
4. Confidence level (0-1) for the identification

Return ONLY a valid JSON object in this exact format:
{
  "items": [
    {
      "name": "food name",
      "quantity": 1,
      "unit": "cup",
      "estimatedCalories": 200,
      "estimatedProtein": 10,
      "estimatedCarbs": 25,
      "estimatedFat": 8,
      "confidence": 0.85
    }
  ],
  "confidence": 0.9
}

Be conservative with estimates. If uncertain, provide a range by using the lower estimate.
If no food is detected, return: {"items": [], "confidence": 0}`;

/**
 * OpenAI Vision Provider (GPT-4 Vision)
 */
export class OpenAIProvider implements AIProvider {
  name = "openai";
  private apiKey: string;

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async analyzePhoto(base64Image: string, mimeType: string): Promise<FoodAnalysisResult> {
    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify({
        model: "gpt-4o",
        messages: [
          {
            role: "user",
            content: [
              { type: "text", text: FOOD_ANALYSIS_PROMPT },
              {
                type: "image_url",
                image_url: {
                  url: `data:${mimeType};base64,${base64Image}`,
                  detail: "high",
                },
              },
            ],
          },
        ],
        max_tokens: 1000,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`OpenAI API error: ${error}`);
    }

    const data = await response.json();
    const content = data.choices[0]?.message?.content;

    return this.parseResponse(content);
  }

  private parseResponse(content: string): FoodAnalysisResult {
    try {
      // Extract JSON from the response (handle markdown code blocks)
      const jsonMatch = content.match(/```json\n?([\s\S]*?)\n?```/) ||
                        content.match(/```\n?([\s\S]*?)\n?```/) ||
                        [null, content];
      const jsonStr = jsonMatch[1] || content;
      const result = JSON.parse(jsonStr.trim());

      return {
        items: result.items || [],
        confidence: result.confidence || 0,
        rawResponse: content,
      };
    } catch (error) {
      console.error("Failed to parse OpenAI response:", content);
      return { items: [], confidence: 0, rawResponse: content };
    }
  }
}

/**
 * Google Gemini Provider
 */
export class GeminiProvider implements AIProvider {
  name = "gemini";
  private apiKey: string;

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async analyzePhoto(base64Image: string, mimeType: string): Promise<FoodAnalysisResult> {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${this.apiKey}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                { text: FOOD_ANALYSIS_PROMPT },
                {
                  inline_data: {
                    mime_type: mimeType,
                    data: base64Image,
                  },
                },
              ],
            },
          ],
          generationConfig: {
            temperature: 0.2,
            maxOutputTokens: 1000,
          },
        }),
      }
    );

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Gemini API error: ${error}`);
    }

    const data = await response.json();
    const content = data.candidates?.[0]?.content?.parts?.[0]?.text;

    return this.parseResponse(content);
  }

  private parseResponse(content: string): FoodAnalysisResult {
    try {
      // Extract JSON from the response
      const jsonMatch = content.match(/```json\n?([\s\S]*?)\n?```/) ||
                        content.match(/```\n?([\s\S]*?)\n?```/) ||
                        [null, content];
      const jsonStr = jsonMatch[1] || content;
      const result = JSON.parse(jsonStr.trim());

      return {
        items: result.items || [],
        confidence: result.confidence || 0,
        rawResponse: content,
      };
    } catch (error) {
      console.error("Failed to parse Gemini response:", content);
      return { items: [], confidence: 0, rawResponse: content };
    }
  }
}

/**
 * Get the configured AI provider based on environment
 */
export function getAIProvider(): AIProvider {
  // Prefer OpenAI if available, fall back to Gemini
  if (process.env.OPENAI_API_KEY) {
    return new OpenAIProvider(process.env.OPENAI_API_KEY);
  }

  if (process.env.GEMINI_API_KEY) {
    return new GeminiProvider(process.env.GEMINI_API_KEY);
  }

  throw new Error("No AI provider configured. Set OPENAI_API_KEY or GEMINI_API_KEY");
}

/**
 * Analyze photo with fallback between providers
 */
export async function analyzePhotoWithFallback(
  base64Image: string,
  mimeType: string
): Promise<FoodAnalysisResult & { provider: string }> {
  const providers: AIProvider[] = [];

  if (process.env.OPENAI_API_KEY) {
    providers.push(new OpenAIProvider(process.env.OPENAI_API_KEY));
  }
  if (process.env.GEMINI_API_KEY) {
    providers.push(new GeminiProvider(process.env.GEMINI_API_KEY));
  }

  if (providers.length === 0) {
    throw new Error("No AI provider configured");
  }

  let lastError: Error | null = null;

  for (const provider of providers) {
    try {
      const result = await provider.analyzePhoto(base64Image, mimeType);
      return { ...result, provider: provider.name };
    } catch (error) {
      console.error(`${provider.name} failed:`, error);
      lastError = error as Error;
    }
  }

  throw lastError || new Error("All AI providers failed");
}
