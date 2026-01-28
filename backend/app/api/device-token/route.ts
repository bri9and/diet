import { NextRequest, NextResponse } from "next/server";
import { auth } from "@clerk/nextjs/server";
import connectDB from "@/lib/mongodb";
import { DeviceToken } from "@/models/DeviceToken";

// POST register device token
export async function POST(request: NextRequest) {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const { token, platform = "ios" } = body;

    if (!token) {
      return NextResponse.json(
        { error: "Token is required" },
        { status: 400 }
      );
    }

    await connectDB();

    // Upsert the token
    await DeviceToken.findOneAndUpdate(
      { token },
      {
        clerkId: userId,
        token,
        platform,
        isActive: true,
      },
      { upsert: true, new: true }
    );

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("Register device token error:", error);
    return NextResponse.json(
      { error: "Failed to register token" },
      { status: 500 }
    );
  }
}

// DELETE unregister device token
export async function DELETE(request: NextRequest) {
  try {
    const { userId } = await auth();

    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const token = searchParams.get("token");

    if (!token) {
      return NextResponse.json(
        { error: "Token is required" },
        { status: 400 }
      );
    }

    await connectDB();

    // Mark token as inactive
    await DeviceToken.findOneAndUpdate(
      { token, clerkId: userId },
      { isActive: false }
    );

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("Unregister device token error:", error);
    return NextResponse.json(
      { error: "Failed to unregister token" },
      { status: 500 }
    );
  }
}
