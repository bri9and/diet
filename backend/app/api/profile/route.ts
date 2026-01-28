import { NextRequest, NextResponse } from "next/server";
import { auth, currentUser } from "@clerk/nextjs/server";
import connectDB from "@/lib/mongodb";
import { UserProfile } from "@/models/UserProfile";

// GET user profile
export async function GET() {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    await connectDB();

    let profile = await UserProfile.findOne({ clerkId: userId });

    // Create profile from Clerk data if none exists
    if (!profile) {
      const user = await currentUser();
      profile = await UserProfile.create({
        clerkId: userId,
        displayName: user?.firstName
          ? `${user.firstName} ${user.lastName || ""}`.trim()
          : undefined,
        email: user?.emailAddresses?.[0]?.emailAddress,
        avatarUrl: user?.imageUrl,
        lastSyncAt: new Date(),
      });
    }

    return NextResponse.json({
      success: true,
      profile: {
        displayName: profile.displayName,
        email: profile.email,
        avatarUrl: profile.avatarUrl,
        heightCm: profile.heightCm,
        currentWeightKg: profile.currentWeightKg,
        birthDate: profile.birthDate?.toISOString().split("T")[0],
        gender: profile.gender,
        lastSyncAt: profile.lastSyncAt?.toISOString(),
      },
    });
  } catch (error) {
    console.error("Get profile error:", error);
    return NextResponse.json(
      { error: "Failed to get profile" },
      { status: 500 }
    );
  }
}

// PUT update profile
export async function PUT(request: NextRequest) {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const {
      displayName,
      heightCm,
      currentWeightKg,
      birthDate,
      gender,
    } = body;

    await connectDB();

    const updateData: Record<string, unknown> = {
      lastSyncAt: new Date(),
    };

    if (displayName !== undefined) updateData.displayName = displayName;
    if (heightCm !== undefined) updateData.heightCm = heightCm;
    if (currentWeightKg !== undefined) updateData.currentWeightKg = currentWeightKg;
    if (birthDate !== undefined) updateData.birthDate = new Date(birthDate);
    if (gender !== undefined) updateData.gender = gender;

    const profile = await UserProfile.findOneAndUpdate(
      { clerkId: userId },
      { $set: updateData },
      { new: true, upsert: true }
    );

    return NextResponse.json({
      success: true,
      profile: {
        displayName: profile.displayName,
        email: profile.email,
        avatarUrl: profile.avatarUrl,
        heightCm: profile.heightCm,
        currentWeightKg: profile.currentWeightKg,
        birthDate: profile.birthDate?.toISOString().split("T")[0],
        gender: profile.gender,
        lastSyncAt: profile.lastSyncAt?.toISOString(),
      },
    });
  } catch (error) {
    console.error("Update profile error:", error);
    return NextResponse.json(
      { error: "Failed to update profile" },
      { status: 500 }
    );
  }
}
