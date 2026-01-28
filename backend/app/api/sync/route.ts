import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import connectDB from "@/lib/mongodb";
import { UserProfile } from "@/models/UserProfile";
import { UserGoals } from "@/models/UserGoals";
import { FoodLog } from "@/lib/models/FoodLog";
import { NotificationPreferences } from "@/models/NotificationPreferences";

// GET sync data - returns all user data for syncing
export async function GET(request: NextRequest) {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const since = searchParams.get("since"); // ISO timestamp

    await connectDB();

    // Get profile
    const profile = await UserProfile.findOne({ clerkId: userId });

    // Get goals
    const goals = await UserGoals.findOne({ clerkId: userId });

    // Get food logs (last 30 days or since last sync)
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const startDate = thirtyDaysAgo.toISOString().split("T")[0];

    const foodLogsQuery: Record<string, unknown> = {
      clerkId: userId,
      loggedDate: { $gte: startDate },
    };

    if (since) {
      foodLogsQuery.updatedAt = { $gt: new Date(since) };
    }

    const foodLogs = await FoodLog.find(foodLogsQuery)
      .sort({ loggedDate: -1 })
      .limit(100);

    // Get notification preferences
    const notifications = await NotificationPreferences.findOne({ clerkId: userId });

    // Update last sync
    await UserProfile.findOneAndUpdate(
      { clerkId: userId },
      { lastSyncAt: new Date() },
      { upsert: true }
    );

    return NextResponse.json({
      success: true,
      syncedAt: new Date().toISOString(),
      data: {
        profile: profile ? {
          displayName: profile.displayName,
          email: profile.email,
          avatarUrl: profile.avatarUrl,
          heightCm: profile.heightCm,
          currentWeightKg: profile.currentWeightKg,
          birthDate: profile.birthDate?.toISOString().split("T")[0],
          gender: profile.gender,
        } : null,
        goals: goals ? {
          dailyCalories: goals.dailyCalories,
          dailyProteinG: goals.dailyProteinG,
          dailyCarbsG: goals.dailyCarbsG,
          dailyFatG: goals.dailyFatG,
          goalType: goals.goalType,
          targetWeight: goals.targetWeight,
        } : null,
        foodLogs: foodLogs.map((log) => ({
          id: log._id.toString(),
          loggedDate: log.loggedDate,
          mealType: log.mealType,
          entryMethod: log.entryMethod,
          items: log.items.map((item: Record<string, unknown>) => ({
            quantity: item.quantity,
            nutrition: item.nutrition,
            foodSnapshot: item.foodSnapshot,
          })),
          updatedAt: log.updatedAt?.toISOString(),
        })),
        notifications: notifications ? {
          mealReminders: notifications.mealReminders,
          mealReminderTimes: notifications.mealReminderTimes,
          weeklyDigest: notifications.weeklyDigest,
          goalProgress: notifications.goalProgress,
          streakReminders: notifications.streakReminders,
        } : null,
      },
    });
  } catch (error) {
    console.error("Sync error:", error);
    return NextResponse.json(
      { error: "Failed to sync" },
      { status: 500 }
    );
  }
}
