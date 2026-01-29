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
    const date = searchParams.get("date");
    const startDate = searchParams.get("startDate");
    const endDate = searchParams.get("endDate");
    const limit = parseInt(searchParams.get("limit") || "50", 10);
    const offset = parseInt(searchParams.get("offset") || "0", 10);

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

    const query: Record<string, unknown> = {
      userId: user._id,
      deletedAt: null,
    };

    if (date) {
      query.loggedDate = date;
    } else if (startDate && endDate) {
      query.loggedDate = { $gte: startDate, $lte: endDate };
    }

    const foodLogs = await FoodLog.find(query)
      .sort({ loggedDate: -1, loggedAt: -1 })
      .skip(offset)
      .limit(limit);

    const total = await FoodLog.countDocuments(query);

    return NextResponse.json({
      data: foodLogs,
      pagination: {
        total,
        limit,
        offset,
        hasMore: offset + foodLogs.length < total,
      },
    });
  } catch (error) {
    console.error("Error fetching food logs:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}

export async function POST(request: Request) {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();

    await connectToDatabase();

    let user = await User.findOne({ clerkId: userId, deletedAt: null });
    if (!user) {
      // Auto-create user on first food log
      user = await User.create({
        clerkId: userId,
        email: `${userId}@placeholder.local`,
        timezone: "UTC",
      });
    }

    // Calculate totals from items
    const totals = {
      calories: 0,
      proteinG: 0,
      carbsG: 0,
      fatG: 0,
      fiberG: 0,
      sugarG: 0,
      sodiumMg: 0,
      itemCount: body.items?.length || 0,
    };

    if (body.items) {
      for (const item of body.items) {
        if (item.nutrition) {
          totals.calories += item.nutrition.calories || 0;
          totals.proteinG += item.nutrition.proteinG || 0;
          totals.carbsG += item.nutrition.carbsG || 0;
          totals.fatG += item.nutrition.fatG || 0;
          totals.fiberG += item.nutrition.fiberG || 0;
          totals.sugarG += item.nutrition.sugarG || 0;
          totals.sodiumMg += item.nutrition.sodiumMg || 0;
        }
      }
    }

    const foodLog = await FoodLog.create({
      userId: user._id,
      loggedDate: body.loggedDate || new Date().toISOString().split("T")[0],
      loggedAt: body.loggedAt || new Date(),
      mealType: body.mealType || "snack",
      mealName: body.mealName,
      entryMethod: body.entryMethod || "manual",
      items: body.items || [],
      totals,
      notes: body.notes,
      mood: body.mood,
      hungerLevel: body.hungerLevel,
      location: body.location,
    });

    return NextResponse.json(foodLog, { status: 201 });
  } catch (error) {
    console.error("Error creating food log:", error);
    const message = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json(
      { error: "Internal server error", details: message },
      { status: 500 }
    );
  }
}
