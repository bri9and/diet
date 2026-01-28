import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import { connectToDatabase } from "@/lib/mongodb";
import { Food } from "@/lib/models/Food";

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

    await connectToDatabase();

    // Text search with scoring
    const foods = await Food.find(
      {
        $text: { $search: query },
        deletedAt: null,
        $or: [{ isPublic: true }, { isVerified: true }],
      },
      { score: { $meta: "textScore" } }
    )
      .sort({ score: { $meta: "textScore" }, globalUseCount: -1 })
      .limit(limit);

    return NextResponse.json({
      data: foods,
      query,
    });
  } catch (error) {
    console.error("Error searching foods:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
