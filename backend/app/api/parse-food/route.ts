import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import { parseFoodDescription } from "@/lib/ai/voice-parser";

export async function POST(request: NextRequest) {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const { text } = body;

    if (!text || typeof text !== "string") {
      return NextResponse.json(
        { error: "Text description is required" },
        { status: 400 }
      );
    }

    if (text.length > 1000) {
      return NextResponse.json(
        { error: "Text too long. Maximum 1000 characters." },
        { status: 400 }
      );
    }

    const result = await parseFoodDescription(text);

    return NextResponse.json({
      success: true,
      provider: result.provider,
      confidence: result.confidence,
      items: result.items.map((item) => ({
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        nutrition: {
          calories: item.estimatedCalories,
          proteinG: item.estimatedProtein,
          carbsG: item.estimatedCarbs,
          fatG: item.estimatedFat,
        },
        confidence: item.confidence,
      })),
    });
  } catch (error) {
    console.error("Food parsing error:", error);

    const message = error instanceof Error ? error.message : "Failed to parse food";

    if (message.includes("No AI provider configured")) {
      return NextResponse.json(
        { error: "AI service not configured" },
        { status: 503 }
      );
    }

    return NextResponse.json({ error: message }, { status: 500 });
  }
}
