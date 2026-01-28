import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import { connectToDatabase } from "@/lib/mongodb";
import { User } from "@/lib/models/User";
import { FoodLog } from "@/lib/models/FoodLog";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { userId } = await auth();
    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { id } = await params;
    await connectToDatabase();

    const user = await User.findOne({ clerkId: userId, deletedAt: null });
    if (!user) {
      return NextResponse.json({ error: "User not found" }, { status: 404 });
    }

    const foodLog = await FoodLog.findOne({
      _id: id,
      userId: user._id,
      deletedAt: null,
    });

    if (!foodLog) {
      return NextResponse.json({ error: "Food log not found" }, { status: 404 });
    }

    return NextResponse.json(foodLog);
  } catch (error) {
    console.error("Error fetching food log:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { userId } = await auth();
    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { id } = await params;
    const body = await request.json();

    await connectToDatabase();

    const user = await User.findOne({ clerkId: userId, deletedAt: null });
    if (!user) {
      return NextResponse.json({ error: "User not found" }, { status: 404 });
    }

    // Recalculate totals if items changed
    let totals = body.totals;
    if (body.items) {
      totals = {
        calories: 0,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
        fiberG: 0,
        sugarG: 0,
        sodiumMg: 0,
        itemCount: body.items.length,
      };
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

    const updateData: Record<string, unknown> = { ...body };
    if (totals) {
      updateData.totals = totals;
    }

    const foodLog = await FoodLog.findOneAndUpdate(
      { _id: id, userId: user._id, deletedAt: null },
      { $set: updateData, $inc: { version: 1 } },
      { new: true }
    );

    if (!foodLog) {
      return NextResponse.json({ error: "Food log not found" }, { status: 404 });
    }

    return NextResponse.json(foodLog);
  } catch (error) {
    console.error("Error updating food log:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { userId } = await auth();
    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { id } = await params;
    await connectToDatabase();

    const user = await User.findOne({ clerkId: userId, deletedAt: null });
    if (!user) {
      return NextResponse.json({ error: "User not found" }, { status: 404 });
    }

    // Soft delete
    const foodLog = await FoodLog.findOneAndUpdate(
      { _id: id, userId: user._id, deletedAt: null },
      { $set: { deletedAt: new Date() }, $inc: { version: 1 } },
      { new: true }
    );

    if (!foodLog) {
      return NextResponse.json({ error: "Food log not found" }, { status: 404 });
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("Error deleting food log:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
