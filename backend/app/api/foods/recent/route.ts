import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import { connectToDatabase } from "@/lib/mongodb";
import { User } from "@/lib/models/User";
import { FoodLog } from "@/lib/models/FoodLog";

export async function GET(request: NextRequest) {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const searchParams = request.nextUrl.searchParams;
    const limit = parseInt(searchParams.get("limit") || "20", 10);

    await connectToDatabase();

    let user = await User.findOne({ clerkId: userId, deletedAt: null });
    if (!user) {
      // Auto-create user on first access
      user = await User.create({
        clerkId: userId,
        email: `${userId}@placeholder.local`,
        timezone: "UTC",
      });
    }

    // Aggregate recent food items from user's food logs
    const recentFoods = await FoodLog.aggregate([
      {
        $match: {
          userId: user._id,
          deletedAt: null,
        },
      },
      { $unwind: "$items" },
      {
        $group: {
          _id: "$items.foodSnapshot.name",
          name: { $first: "$items.foodSnapshot.name" },
          brand: { $first: "$items.foodSnapshot.brand" },
          nutrition: { $first: "$items.nutrition" },
          foodId: { $first: "$items.foodId" },
          lastUsed: { $max: "$loggedAt" },
          useCount: { $sum: 1 },
        },
      },
      { $sort: { lastUsed: -1 } },
      { $limit: limit },
      {
        $project: {
          _id: 0,
          name: 1,
          brand: 1,
          nutrition: 1,
          foodId: 1,
          lastUsed: 1,
          useCount: 1,
        },
      },
    ]);

    return NextResponse.json({
      data: recentFoods,
    });
  } catch (error) {
    console.error("Error fetching recent foods:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
