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

    // Calculate daily totals including micronutrients
    const dailyTotals = {
      // Macros
      calories: 0,
      proteinG: 0,
      carbsG: 0,
      fatG: 0,
      fiberG: 0,
      sugarG: 0,
      sodiumMg: 0,
      mealCount: foodLogs.length,
      itemCount: 0,
      // Vitamins
      vitaminAMcg: 0,
      vitaminCMg: 0,
      vitaminDMcg: 0,
      vitaminEMg: 0,
      vitaminKMcg: 0,
      vitaminB1Mg: 0,
      vitaminB2Mg: 0,
      vitaminB3Mg: 0,
      vitaminB5Mg: 0,
      vitaminB6Mg: 0,
      vitaminB9Mcg: 0,
      vitaminB12Mcg: 0,
      cholineMg: 0,
      // Minerals
      calciumMg: 0,
      ironMg: 0,
      magnesiumMg: 0,
      phosphorusMg: 0,
      potassiumMg: 0,
      zincMg: 0,
      copperMg: 0,
      manganeseMg: 0,
      seleniumMcg: 0,
      // Lipids
      saturatedFatG: 0,
      monounsaturatedFatG: 0,
      polyunsaturatedFatG: 0,
      transFatG: 0,
      cholesterolMg: 0,
    };

    // Group by meal type
    const mealsByType: Record<string, typeof foodLogs> = {
      breakfast: [],
      lunch: [],
      dinner: [],
      snack: [],
    };

    for (const log of foodLogs) {
      // Macros
      dailyTotals.calories += log.totals?.calories || 0;
      dailyTotals.proteinG += log.totals?.proteinG || 0;
      dailyTotals.carbsG += log.totals?.carbsG || 0;
      dailyTotals.fatG += log.totals?.fatG || 0;
      dailyTotals.fiberG += log.totals?.fiberG || 0;
      dailyTotals.sugarG += log.totals?.sugarG || 0;
      dailyTotals.sodiumMg += log.totals?.sodiumMg || 0;
      dailyTotals.itemCount += log.totals?.itemCount || 0;

      // Aggregate micronutrients from items (if present)
      for (const item of log.items || []) {
        const n = item.nutrition || {};
        // Vitamins
        dailyTotals.vitaminAMcg += n.vitaminAMcg || 0;
        dailyTotals.vitaminCMg += n.vitaminCMg || 0;
        dailyTotals.vitaminDMcg += n.vitaminDMcg || 0;
        dailyTotals.vitaminEMg += n.vitaminEMg || 0;
        dailyTotals.vitaminKMcg += n.vitaminKMcg || 0;
        dailyTotals.vitaminB1Mg += n.vitaminB1Mg || 0;
        dailyTotals.vitaminB2Mg += n.vitaminB2Mg || 0;
        dailyTotals.vitaminB3Mg += n.vitaminB3Mg || 0;
        dailyTotals.vitaminB5Mg += n.vitaminB5Mg || 0;
        dailyTotals.vitaminB6Mg += n.vitaminB6Mg || 0;
        dailyTotals.vitaminB9Mcg += n.vitaminB9Mcg || 0;
        dailyTotals.vitaminB12Mcg += n.vitaminB12Mcg || 0;
        dailyTotals.cholineMg += n.cholineMg || 0;
        // Minerals
        dailyTotals.calciumMg += n.calciumMg || 0;
        dailyTotals.ironMg += n.ironMg || 0;
        dailyTotals.magnesiumMg += n.magnesiumMg || 0;
        dailyTotals.phosphorusMg += n.phosphorusMg || 0;
        dailyTotals.potassiumMg += n.potassiumMg || 0;
        dailyTotals.zincMg += n.zincMg || 0;
        dailyTotals.copperMg += n.copperMg || 0;
        dailyTotals.manganeseMg += n.manganeseMg || 0;
        dailyTotals.seleniumMcg += n.seleniumMcg || 0;
        // Lipids
        dailyTotals.saturatedFatG += n.saturatedFatG || 0;
        dailyTotals.monounsaturatedFatG += n.monounsaturatedFatG || 0;
        dailyTotals.polyunsaturatedFatG += n.polyunsaturatedFatG || 0;
        dailyTotals.transFatG += n.transFatG || 0;
        dailyTotals.cholesterolMg += n.cholesterolMg || 0;
      }

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
