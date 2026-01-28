import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import { analyzePhotoWithFallback } from "@/lib/ai/providers";

export const maxDuration = 30; // Allow up to 30 seconds for AI processing

export async function POST(request: NextRequest) {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const { image, mimeType } = body;

    if (!image) {
      return NextResponse.json(
        { error: "Image is required" },
        { status: 400 }
      );
    }

    // Validate mime type
    const validMimeTypes = ["image/jpeg", "image/png", "image/webp", "image/gif"];
    const actualMimeType = mimeType || "image/jpeg";

    if (!validMimeTypes.includes(actualMimeType)) {
      return NextResponse.json(
        { error: "Invalid image type. Supported: JPEG, PNG, WebP, GIF" },
        { status: 400 }
      );
    }

    // Remove data URL prefix if present
    const base64Image = image.replace(/^data:image\/\w+;base64,/, "");

    // Validate base64
    if (!/^[A-Za-z0-9+/]+=*$/.test(base64Image)) {
      return NextResponse.json(
        { error: "Invalid base64 image data" },
        { status: 400 }
      );
    }

    // Check image size (max 10MB)
    const imageSizeBytes = (base64Image.length * 3) / 4;
    const maxSizeBytes = 10 * 1024 * 1024;

    if (imageSizeBytes > maxSizeBytes) {
      return NextResponse.json(
        { error: "Image too large. Maximum size is 10MB" },
        { status: 400 }
      );
    }

    // Analyze with AI
    const result = await analyzePhotoWithFallback(base64Image, actualMimeType);

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
    console.error("Photo analysis error:", error);

    const message = error instanceof Error ? error.message : "Failed to analyze photo";

    // Check for specific error types
    if (message.includes("No AI provider configured")) {
      return NextResponse.json(
        { error: "AI service not configured" },
        { status: 503 }
      );
    }

    return NextResponse.json(
      { error: message },
      { status: 500 }
    );
  }
}
