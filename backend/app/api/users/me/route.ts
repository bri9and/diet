import { NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import { connectToDatabase } from "@/lib/mongodb";
import { User, IUser } from "@/lib/models/User";

export async function GET() {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    await connectToDatabase();

    let user = await User.findOne({ clerkId: userId, deletedAt: null });

    if (!user) {
      // Create new user on first access
      user = await User.create({
        clerkId: userId,
        email: "", // Will be updated via webhook or profile sync
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      });
    }

    return NextResponse.json({
      id: user._id,
      clerkId: user.clerkId,
      email: user.email,
      displayName: user.displayName,
      timezone: user.timezone,
      unitSystem: user.unitSystem,
      subscriptionTier: user.subscriptionTier,
    });
  } catch (error) {
    console.error("Error fetching user:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}

export async function PATCH(request: Request) {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const allowedFields = [
      "displayName",
      "timezone",
      "unitSystem",
      "language",
      "dateFormat",
      "startOfWeek",
      "shareWithFamily",
      "aiProcessingConsent",
      "analyticsConsent",
    ];

    const updateData: Partial<IUser> = {};
    for (const field of allowedFields) {
      if (field in body) {
        (updateData as Record<string, unknown>)[field] = body[field];
      }
    }

    await connectToDatabase();

    const user = await User.findOneAndUpdate(
      { clerkId: userId, deletedAt: null },
      { $set: updateData, $inc: { version: 1 } },
      { new: true }
    );

    if (!user) {
      return NextResponse.json({ error: "User not found" }, { status: 404 });
    }

    return NextResponse.json({
      id: user._id,
      displayName: user.displayName,
      timezone: user.timezone,
      unitSystem: user.unitSystem,
    });
  } catch (error) {
    console.error("Error updating user:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
