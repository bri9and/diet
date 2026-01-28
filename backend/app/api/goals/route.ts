import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import connectDB from "@/lib/mongodb";
import { UserGoals } from "@/models/UserGoals";

// GET user goals
export async function GET() {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    await connectDB();

    let goals = await UserGoals.findOne({ clerkId: userId });

    // Create default goals if none exist
    if (!goals) {
      goals = await UserGoals.create({
        clerkId: userId,
        dailyCalories: 2000,
        dailyProteinG: 50,
        dailyCarbsG: 250,
        dailyFatG: 65,
        activityLevel: "moderate",
        goalType: "maintain",
      });
    }

    return NextResponse.json({
      success: true,
      goals: {
        dailyCalories: goals.dailyCalories,
        dailyProteinG: goals.dailyProteinG,
        dailyCarbsG: goals.dailyCarbsG,
        dailyFatG: goals.dailyFatG,
        targetWeight: goals.targetWeight,
        targetWeightUnit: goals.targetWeightUnit,
        activityLevel: goals.activityLevel,
        goalType: goals.goalType,
        weeklyGoalKg: goals.weeklyGoalKg,
      },
    });
  } catch (error) {
    console.error("Get goals error:", error);
    return NextResponse.json(
      { error: "Failed to get goals" },
      { status: 500 }
    );
  }
}

// PUT update goals
export async function PUT(request: NextRequest) {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const {
      dailyCalories,
      dailyProteinG,
      dailyCarbsG,
      dailyFatG,
      targetWeight,
      targetWeightUnit,
      activityLevel,
      goalType,
      weeklyGoalKg,
    } = body;

    await connectDB();

    const updateData: Record<string, unknown> = {};

    if (dailyCalories !== undefined) updateData.dailyCalories = dailyCalories;
    if (dailyProteinG !== undefined) updateData.dailyProteinG = dailyProteinG;
    if (dailyCarbsG !== undefined) updateData.dailyCarbsG = dailyCarbsG;
    if (dailyFatG !== undefined) updateData.dailyFatG = dailyFatG;
    if (targetWeight !== undefined) updateData.targetWeight = targetWeight;
    if (targetWeightUnit !== undefined) updateData.targetWeightUnit = targetWeightUnit;
    if (activityLevel !== undefined) updateData.activityLevel = activityLevel;
    if (goalType !== undefined) updateData.goalType = goalType;
    if (weeklyGoalKg !== undefined) updateData.weeklyGoalKg = weeklyGoalKg;

    const goals = await UserGoals.findOneAndUpdate(
      { clerkId: userId },
      { $set: updateData },
      { new: true, upsert: true }
    );

    return NextResponse.json({
      success: true,
      goals: {
        dailyCalories: goals.dailyCalories,
        dailyProteinG: goals.dailyProteinG,
        dailyCarbsG: goals.dailyCarbsG,
        dailyFatG: goals.dailyFatG,
        targetWeight: goals.targetWeight,
        targetWeightUnit: goals.targetWeightUnit,
        activityLevel: goals.activityLevel,
        goalType: goals.goalType,
        weeklyGoalKg: goals.weeklyGoalKg,
      },
    });
  } catch (error) {
    console.error("Update goals error:", error);
    return NextResponse.json(
      { error: "Failed to update goals" },
      { status: 500 }
    );
  }
}
