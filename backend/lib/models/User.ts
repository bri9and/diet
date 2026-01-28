import mongoose, { Document, Schema } from "mongoose";

export interface IUser extends Document {
  clerkId: string;
  email: string;
  displayName?: string;
  avatarUrl?: string;
  timezone: string;
  unitSystem: "metric" | "imperial";
  language: string;
  dateFormat: string;
  startOfWeek: number;
  shareWithFamily: boolean;
  aiProcessingConsent: boolean;
  analyticsConsent: boolean;
  subscriptionTier: "free" | "premium" | "family";
  subscriptionExpiresAt?: Date;
  betaFeaturesEnabled: boolean;
  version: number;
  lastSyncedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date;
}

const UserSchema = new Schema<IUser>(
  {
    clerkId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    email: {
      type: String,
      required: true,
      index: true,
    },
    displayName: {
      type: String,
    },
    avatarUrl: {
      type: String,
    },
    timezone: {
      type: String,
      default: "UTC",
    },
    unitSystem: {
      type: String,
      enum: ["metric", "imperial"],
      default: "metric",
    },
    language: {
      type: String,
      default: "en",
    },
    dateFormat: {
      type: String,
      default: "yyyy-MM-dd",
    },
    startOfWeek: {
      type: Number,
      default: 1,
      min: 0,
      max: 6,
    },
    shareWithFamily: {
      type: Boolean,
      default: false,
    },
    aiProcessingConsent: {
      type: Boolean,
      default: true,
    },
    analyticsConsent: {
      type: Boolean,
      default: true,
    },
    subscriptionTier: {
      type: String,
      enum: ["free", "premium", "family"],
      default: "free",
    },
    subscriptionExpiresAt: {
      type: Date,
    },
    betaFeaturesEnabled: {
      type: Boolean,
      default: false,
    },
    version: {
      type: Number,
      default: 1,
    },
    lastSyncedAt: {
      type: Date,
    },
    deletedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Index for soft delete queries
UserSchema.index(
  { deletedAt: 1 },
  { partialFilterExpression: { deletedAt: null } }
);

export const User = mongoose.model<IUser>("User", UserSchema);
