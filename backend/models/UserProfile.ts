import mongoose, { Schema, Document } from "mongoose";

export interface IUserProfile extends Document {
  clerkId: string;
  displayName?: string;
  email?: string;
  avatarUrl?: string;
  heightCm?: number;
  currentWeightKg?: number;
  birthDate?: Date;
  gender?: "male" | "female" | "other" | "prefer_not_to_say";
  lastSyncAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

const UserProfileSchema = new Schema<IUserProfile>(
  {
    clerkId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    displayName: String,
    email: String,
    avatarUrl: String,
    heightCm: Number,
    currentWeightKg: Number,
    birthDate: Date,
    gender: {
      type: String,
      enum: ["male", "female", "other", "prefer_not_to_say"],
    },
    lastSyncAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

export const UserProfile =
  mongoose.models.UserProfile ||
  mongoose.model<IUserProfile>("UserProfile", UserProfileSchema);
