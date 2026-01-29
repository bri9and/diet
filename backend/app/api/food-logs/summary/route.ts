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
    const date =
      searchParams.get("date") || new Date().toISOString().split("T")[0];

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

    // Get all food logs for the date
    const foodLogs = await FoodLog.find({
      userId: user._id,
      loggedDate: date,
      deletedAt: null,
    }).sort({ loggedAt: 1 });

    // Calculate daily totals
    const dailyTotals = {
      calories: 0,
      proteinG: 0,
      carbsG: 0,
      fatG: 0,
      fiberG: 0,
      sugarG: 0,
      sodiumMg: 0,
      mealCount: foodLogs.length,
      itemCount: 0,
    };

    // Group by meal type
    const mealsByType: Record<string, typeof foodLogs> = {
      breakfast: [],
      lunch: [],
      dinner: [],
      snack: [],
    };

    for (const log of foodLogs) {
      dailyTotals.calories += log.totals?.calories || 0;
      dailyTotals.proteinG += log.totals?.proteinG || 0;
      dailyTotals.carbsG += log.totals?.carbsG || 0;
      dailyTotals.fatG += log.totals?.fatG || 0;
      dailyTotals.fiberG += log.totals?.fiberG || 0;
      dailyTotals.sugarG += log.totals?.sugarG || 0;
      dailyTotals.sodiumMg += log.totals?.sodiumMg || 0;
      dailyTotals.itemCount += log.totals?.itemCount || 0;

      if (mealsByType[log.mealType]) {
        mealsByType[log.mealType].push(log);
      }
    }

    // Round values
    dailyTotals.calories = Math.round(dailyTotals.calories);
    dailyTotals.proteinG = Math.round(dailyTotals.proteinG * 10) / 10;
    dailyTotals.carbsG = Math.round(dailyTotals.carbsG * 10) / 10;
    dailyTotals.fatG = Math.round(dailyTotals.fatG * 10) / 10;

    return NextResponse.json({
      date,
      totals: dailyTotals,
      meals: mealsByType,
      // User's daily targets (defaults for now)
      targets: {
        calories: 2400,
        proteinG: 150,
        carbsG: 300,
        fatG: 80,
      },
    });
  } catch (error) {
    console.error("Error fetching daily summary:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
