import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import connectDB from "@/lib/mongodb";
import { UserProfile } from "@/models/UserProfile";
import { UserGoals } from "@/models/UserGoals";

// Activity level multipliers for TDEE calculation
const ACTIVITY_MULTIPLIERS = {
  sedentary: 1.2, // Little or no exercise
  light: 1.375, // Light exercise 1-3 days/week
  moderate: 1.55, // Moderate exercise 3-5 days/week
  active: 1.725, // Hard exercise 6-7 days/week
  very_active: 1.9, // Very hard exercise, physical job
};

// Calculate age from birthDate
function calculateAge(birthDate: Date): number {
  const today = new Date();
  let age = today.getFullYear() - birthDate.getFullYear();
  const monthDiff = today.getMonth() - birthDate.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
    age--;
  }
  return age;
}

// Calculate BMR using Mifflin-St Jeor equation
function calculateBMR(
  weightKg: number,
  heightCm: number,
  age: number,
  gender: string
): number {
  // Mifflin-St Jeor equation
  // Men: BMR = (10 × weight in kg) + (6.25 × height in cm) - (5 × age) + 5
  // Women: BMR = (10 × weight in kg) + (6.25 × height in cm) - (5 × age) - 161
  const baseBMR = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return gender === "male" ? baseBMR + 5 : baseBMR - 161;
}

// POST - Calculate goals based on profile
export async function POST(request: NextRequest) {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const {
      heightCm,
      currentWeightKg,
      targetWeightKg,
      birthDate,
      gender,
      activityLevel,
      goalType, // "lose", "maintain", "gain"
    } = body;

    // Validate required fields
    if (!heightCm || !currentWeightKg || !birthDate || !gender || !activityLevel) {
      return NextResponse.json(
        { error: "Missing required fields: heightCm, currentWeightKg, birthDate, gender, activityLevel" },
        { status: 400 }
      );
    }

    await connectDB();

    // Calculate age
    const age = calculateAge(new Date(birthDate));

    // Calculate BMR
    const bmr = calculateBMR(currentWeightKg, heightCm, age, gender);

    // Calculate TDEE
    const activityMultiplier = ACTIVITY_MULTIPLIERS[activityLevel as keyof typeof ACTIVITY_MULTIPLIERS] || 1.55;
    const tdee = Math.round(bmr * activityMultiplier);

    // Determine calorie goal based on goal type
    let dailyCalories: number;
    let weeklyGoalKg = 0;

    const derivedGoalType = goalType || (targetWeightKg && targetWeightKg < currentWeightKg ? "lose" : targetWeightKg && targetWeightKg > currentWeightKg ? "gain" : "maintain");

    switch (derivedGoalType) {
      case "lose":
        // Deficit of 500-750 cal/day = ~0.5-0.75 kg/week loss
        dailyCalories = Math.max(1200, tdee - 500);
        weeklyGoalKg = -0.5;
        break;
      case "gain":
        // Surplus of 300-500 cal/day = ~0.25-0.5 kg/week gain
        dailyCalories = tdee + 400;
        weeklyGoalKg = 0.35;
        break;
      default:
        // Maintain
        dailyCalories = tdee;
        weeklyGoalKg = 0;
    }

    // Calculate macros (balanced approach)
    // Protein: 1.6-2.2g per kg of body weight
    // Fat: 25-35% of calories
    // Carbs: remainder
    const dailyProteinG = Math.round(currentWeightKg * 1.8); // 1.8g/kg
    const dailyFatG = Math.round((dailyCalories * 0.28) / 9); // 28% of calories, 9 cal/g
    const dailyCarbsG = Math.round((dailyCalories - dailyProteinG * 4 - dailyFatG * 9) / 4); // Remainder, 4 cal/g

    // Update profile
    await UserProfile.findOneAndUpdate(
      { clerkId: userId },
      {
        $set: {
          heightCm,
          currentWeightKg,
          targetWeightKg,
          birthDate: new Date(birthDate),
          gender,
          activityLevel,
          onboardingCompleted: true,
          lastSyncAt: new Date(),
        },
      },
      { upsert: true }
    );

    // Update goals
    const goals = await UserGoals.findOneAndUpdate(
      { clerkId: userId },
      {
        $set: {
          dailyCalories,
          dailyProteinG,
          dailyCarbsG,
          dailyFatG,
          targetWeight: targetWeightKg,
          targetWeightUnit: "kg",
          activityLevel,
          goalType: derivedGoalType,
          weeklyGoalKg,
        },
      },
      { new: true, upsert: true }
    );

    return NextResponse.json({
      success: true,
      calculations: {
        age,
        bmr: Math.round(bmr),
        tdee,
        dailyCalories,
        dailyProteinG,
        dailyCarbsG,
        dailyFatG,
        goalType: derivedGoalType,
        weeklyGoalKg,
      },
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
    console.error("Calculate goals error:", error);
    return NextResponse.json(
      { error: "Failed to calculate goals" },
      { status: 500 }
    );
  }
}
