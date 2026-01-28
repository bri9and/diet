import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import { lookupBarcode } from "@/lib/barcode/lookup";

export async function GET(request: NextRequest) {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const barcode = searchParams.get("code");

    if (!barcode) {
      return NextResponse.json(
        { error: "Barcode is required" },
        { status: 400 }
      );
    }

    const result = await lookupBarcode(barcode);

    if (!result.found) {
      return NextResponse.json(
        {
          success: false,
          error: result.error || "Product not found"
        },
        { status: 404 }
      );
    }

    return NextResponse.json({
      success: true,
      product: result.product,
    });
  } catch (error) {
    console.error("Barcode lookup error:", error);
    return NextResponse.json(
      { error: "Failed to lookup barcode" },
      { status: 500 }
    );
  }
}
