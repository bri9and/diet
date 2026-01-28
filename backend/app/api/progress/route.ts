import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import connectDB from "@/lib/mongodb";
import { UserGoals } from "@/models/UserGoals";
import { FoodLog } from "@/lib/models/FoodLog";

// GET progress for a date range
export async function GET(request: NextRequest) {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const startDate = searchParams.get("start");
    const endDate = searchParams.get("end");

    // Default to last 7 days
    const end = endDate || new Date().toISOString().split("T")[0];
    const start = startDate || new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split("T")[0];

    await connectDB();

    // Get goals
    let goals = await UserGoals.findOne({ clerkId: userId });
    if (!goals) {
      goals = await UserGoals.create({
        clerkId: userId,
        dailyCalories: 2000,
        dailyProteinG: 50,
        dailyCarbsG: 250,
        dailyFatG: 65,
      });
    }

    // Get food logs for the date range
    const logs = await FoodLog.find({
      clerkId: userId,
      loggedDate: { $gte: start, $lte: end },
    }).sort({ loggedDate: 1 });

    // Aggregate by date
    const dailyData: Record<string, {
      calories: number;
      proteinG: number;
      carbsG: number;
      fatG: number;
    }> = {};

    for (const log of logs) {
      const date = log.loggedDate;
      if (!dailyData[date]) {
        dailyData[date] = { calories: 0, proteinG: 0, carbsG: 0, fatG: 0 };
      }

      for (const item of log.items) {
        dailyData[date].calories += item.nutrition.calories || 0;
        dailyData[date].proteinG += item.nutrition.proteinG || 0;
        dailyData[date].carbsG += item.nutrition.carbsG || 0;
        dailyData[date].fatG += item.nutrition.fatG || 0;
      }
    }

    // Build progress data
    const progress = Object.entries(dailyData).map(([date, totals]) => ({
      date,
      calories: {
        consumed: Math.round(totals.calories),
        goal: goals.dailyCalories,
        percentage: Math.round((totals.calories / goals.dailyCalories) * 100),
      },
      protein: {
        consumed: Math.round(totals.proteinG),
        goal: goals.dailyProteinG,
        percentage: Math.round((totals.proteinG / goals.dailyProteinG) * 100),
      },
      carbs: {
        consumed: Math.round(totals.carbsG),
        goal: goals.dailyCarbsG,
        percentage: Math.round((totals.carbsG / goals.dailyCarbsG) * 100),
      },
      fat: {
        consumed: Math.round(totals.fatG),
        goal: goals.dailyFatG,
        percentage: Math.round((totals.fatG / goals.dailyFatG) * 100),
      },
    }));

    // Calculate weekly averages
    const totalDays = progress.length || 1;
    const weeklyAverage = {
      calories: Math.round(progress.reduce((sum, p) => sum + p.calories.consumed, 0) / totalDays),
      protein: Math.round(progress.reduce((sum, p) => sum + p.protein.consumed, 0) / totalDays),
      carbs: Math.round(progress.reduce((sum, p) => sum + p.carbs.consumed, 0) / totalDays),
      fat: Math.round(progress.reduce((sum, p) => sum + p.fat.consumed, 0) / totalDays),
    };

    return NextResponse.json({
      success: true,
      goals: {
        dailyCalories: goals.dailyCalories,
        dailyProteinG: goals.dailyProteinG,
        dailyCarbsG: goals.dailyCarbsG,
        dailyFatG: goals.dailyFatG,
        goalType: goals.goalType,
      },
      progress,
      weeklyAverage,
      daysTracked: totalDays,
    });
  } catch (error) {
    console.error("Get progress error:", error);
    return NextResponse.json(
      { error: "Failed to get progress" },
      { status: 500 }
    );
  }
}
