import mongoose, { Schema, Document } from "mongoose";

export interface IDeviceToken extends Document {
  clerkId: string;
  token: string;
  platform: "ios" | "android";
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const DeviceTokenSchema = new Schema<IDeviceToken>(
  {
    clerkId: {
      type: String,
      required: true,
      index: true,
    },
    token: {
      type: String,
      required: true,
      unique: true,
    },
    platform: {
      type: String,
      enum: ["ios", "android"],
      default: "ios",
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index for efficient queries
DeviceTokenSchema.index({ clerkId: 1, isActive: 1 });

export const DeviceToken =
  mongoose.models.DeviceToken ||
  mongoose.model<IDeviceToken>("DeviceToken", DeviceTokenSchema);
