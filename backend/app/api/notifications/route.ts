import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import connectDB from "@/lib/mongodb";
import { NotificationPreferences } from "@/models/NotificationPreferences";

// GET notification preferences
export async function GET() {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    await connectDB();

    let prefs = await NotificationPreferences.findOne({ clerkId: userId });

    // Create default preferences if none exist
    if (!prefs) {
      prefs = await NotificationPreferences.create({
        clerkId: userId,
        mealReminders: true,
        mealReminderTimes: {
          breakfast: "08:00",
          lunch: "12:00",
          dinner: "18:00",
        },
        weeklyDigest: true,
        goalProgress: true,
        streakReminders: true,
        timezone: "UTC",
      });
    }

    return NextResponse.json({
      success: true,
      preferences: {
        mealReminders: prefs.mealReminders,
        mealReminderTimes: prefs.mealReminderTimes,
        weeklyDigest: prefs.weeklyDigest,
        goalProgress: prefs.goalProgress,
        streakReminders: prefs.streakReminders,
        timezone: prefs.timezone,
      },
    });
  } catch (error) {
    console.error("Get notification preferences error:", error);
    return NextResponse.json(
      { error: "Failed to get preferences" },
      { status: 500 }
    );
  }
}

// PUT update notification preferences
export async function PUT(request: NextRequest) {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const {
      mealReminders,
      mealReminderTimes,
      weeklyDigest,
      goalProgress,
      streakReminders,
      timezone,
    } = body;

    await connectDB();

    const updateData: Record<string, unknown> = {};

    if (mealReminders !== undefined) updateData.mealReminders = mealReminders;
    if (mealReminderTimes !== undefined) updateData.mealReminderTimes = mealReminderTimes;
    if (weeklyDigest !== undefined) updateData.weeklyDigest = weeklyDigest;
    if (goalProgress !== undefined) updateData.goalProgress = goalProgress;
    if (streakReminders !== undefined) updateData.streakReminders = streakReminders;
    if (timezone !== undefined) updateData.timezone = timezone;

    const prefs = await NotificationPreferences.findOneAndUpdate(
      { clerkId: userId },
      { $set: updateData },
      { new: true, upsert: true }
    );

    return NextResponse.json({
      success: true,
      preferences: {
        mealReminders: prefs.mealReminders,
        mealReminderTimes: prefs.mealReminderTimes,
        weeklyDigest: prefs.weeklyDigest,
        goalProgress: prefs.goalProgress,
        streakReminders: prefs.streakReminders,
        timezone: prefs.timezone,
      },
    });
  } catch (error) {
    console.error("Update notification preferences error:", error);
    return NextResponse.json(
      { error: "Failed to update preferences" },
      { status: 500 }
    );
  }
}
