import mongoose, { Schema, Document } from "mongoose";

export interface INotificationPreferences extends Document {
  clerkId: string;
  mealReminders: boolean;
  mealReminderTimes: {
    breakfast: string;  // "08:00"
    lunch: string;      // "12:00"
    dinner: string;     // "18:00"
  };
  weeklyDigest: boolean;
  goalProgress: boolean;
  streakReminders: boolean;
  timezone: string;
  createdAt: Date;
  updatedAt: Date;
}

const NotificationPreferencesSchema = new Schema<INotificationPreferences>(
  {
    clerkId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    mealReminders: {
      type: Boolean,
      default: true,
    },
    mealReminderTimes: {
      breakfast: { type: String, default: "08:00" },
      lunch: { type: String, default: "12:00" },
      dinner: { type: String, default: "18:00" },
    },
    weeklyDigest: {
      type: Boolean,
      default: true,
    },
    goalProgress: {
      type: Boolean,
      default: true,
    },
    streakReminders: {
      type: Boolean,
      default: true,
    },
    timezone: {
      type: String,
      default: "UTC",
    },
  },
  {
    timestamps: true,
  }
);

export const NotificationPreferences =
  mongoose.models.NotificationPreferences ||
  mongoose.model<INotificationPreferences>("NotificationPreferences", NotificationPreferencesSchema);
