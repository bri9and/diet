import mongoose, { Schema, Document } from "mongoose";

export interface IUserGoals extends Document {
  clerkId: string;
  dailyCalories: number;
  dailyProteinG: number;
  dailyCarbsG: number;
  dailyFatG: number;
  targetWeight?: number;
  targetWeightUnit: "kg" | "lbs";
  activityLevel: "sedentary" | "light" | "moderate" | "active" | "very_active";
  goalType: "lose" | "maintain" | "gain";
  weeklyGoalKg?: number;
  createdAt: Date;
  updatedAt: Date;
}

const UserGoalsSchema = new Schema<IUserGoals>(
  {
    clerkId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    dailyCalories: {
      type: Number,
      required: true,
      default: 2000,
    },
    dailyProteinG: {
      type: Number,
      required: true,
      default: 50,
    },
    dailyCarbsG: {
      type: Number,
      required: true,
      default: 250,
    },
    dailyFatG: {
      type: Number,
      required: true,
      default: 65,
    },
    targetWeight: {
      type: Number,
    },
    targetWeightUnit: {
      type: String,
      enum: ["kg", "lbs"],
      default: "kg",
    },
    activityLevel: {
      type: String,
      enum: ["sedentary", "light", "moderate", "active", "very_active"],
      default: "moderate",
    },
    goalType: {
      type: String,
      enum: ["lose", "maintain", "gain"],
      default: "maintain",
    },
    weeklyGoalKg: {
      type: Number,
    },
  },
  {
    timestamps: true,
  }
);

export const UserGoals =
  mongoose.models.UserGoals ||
  mongoose.model<IUserGoals>("UserGoals", UserGoalsSchema);
