import mongoose, { Document, Schema, Types } from "mongoose";

export interface IWeightLog extends Document {
  userId: Types.ObjectId;
  weightKg: number;
  measuredAt: Date;
  measuredDate: string;
  bodyFatPercentage?: number;
  muscleMassKg?: number;
  waterPercentage?: number;
  boneMassKg?: number;
  source: "manual" | "smart_scale" | "apple_health" | "fitbit" | "garmin";
  notes?: string;
  version: number;
  lastSyncedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date;
}

const WeightLogSchema = new Schema<IWeightLog>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    weightKg: {
      type: Number,
      required: true,
      min: 0,
    },
    measuredAt: {
      type: Date,
      required: true,
    },
    measuredDate: {
      type: String,
      required: true,
    },
    bodyFatPercentage: {
      type: Number,
      min: 0,
      max: 100,
    },
    muscleMassKg: {
      type: Number,
      min: 0,
    },
    waterPercentage: {
      type: Number,
      min: 0,
      max: 100,
    },
    boneMassKg: {
      type: Number,
      min: 0,
    },
    source: {
      type: String,
      enum: ["manual", "smart_scale", "apple_health", "fitbit", "garmin"],
      default: "manual",
    },
    notes: {
      type: String,
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

// Indexes
WeightLogSchema.index({ userId: 1, measuredDate: -1 });
WeightLogSchema.index({ userId: 1, deletedAt: 1 });

export const WeightLog = mongoose.model<IWeightLog>(
  "WeightLog",
  WeightLogSchema
);
