import mongoose, { Document, Schema, Types } from "mongoose";

export interface IFoodLogItemNutrition {
  calories: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
  fiberG?: number;
  sugarG?: number;
  sodiumMg?: number;
}

export interface IFoodSnapshot {
  name: string;
  brand?: string;
  servingDescription?: string;
}

export interface IFoodLogItem {
  _id: Types.ObjectId;
  foodId?: Types.ObjectId;
  quantity: number;
  servingMultiplier: number;
  nutrition: IFoodLogItemNutrition;
  quickAddName?: string;
  quickAddDescription?: string;
  foodSnapshot: IFoodSnapshot;
  sortOrder: number;
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date;
}

export interface IFoodLogTotals {
  calories: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
  fiberG: number;
  sugarG: number;
  sodiumMg: number;
  itemCount: number;
}

export interface ILocation {
  name?: string;
  lat?: number;
  lng?: number;
}

export interface IFoodLog extends Document {
  userId: Types.ObjectId;
  loggedDate: string;
  loggedAt: Date;
  mealType: "breakfast" | "lunch" | "dinner" | "snack";
  mealName?: string;
  entryMethod:
    | "manual"
    | "barcode"
    | "photo_ai"
    | "voice"
    | "quick_add"
    | "copy"
    | "recipe";
  items: IFoodLogItem[];
  totals: IFoodLogTotals;
  notes?: string;
  mood?: "great" | "good" | "neutral" | "bad" | "terrible";
  hungerLevel?: number;
  location?: ILocation;
  version: number;
  lastSyncedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date;
}

const FoodLogItemNutritionSchema = new Schema<IFoodLogItemNutrition>(
  {
    calories: { type: Number, required: true },
    proteinG: { type: Number, required: true },
    carbsG: { type: Number, required: true },
    fatG: { type: Number, required: true },
    fiberG: { type: Number },
    sugarG: { type: Number },
    sodiumMg: { type: Number },
  },
  { _id: false }
);

const FoodSnapshotSchema = new Schema<IFoodSnapshot>(
  {
    name: { type: String, required: true },
    brand: { type: String },
    servingDescription: { type: String },
  },
  { _id: false }
);

const FoodLogItemSchema = new Schema<IFoodLogItem>(
  {
    foodId: {
      type: Schema.Types.ObjectId,
      ref: "Food",
    },
    quantity: {
      type: Number,
      required: true,
      default: 1,
    },
    servingMultiplier: {
      type: Number,
      required: true,
      default: 1,
    },
    nutrition: {
      type: FoodLogItemNutritionSchema,
      required: true,
    },
    quickAddName: {
      type: String,
    },
    quickAddDescription: {
      type: String,
    },
    foodSnapshot: {
      type: FoodSnapshotSchema,
      required: true,
    },
    sortOrder: {
      type: Number,
      default: 0,
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
    updatedAt: {
      type: Date,
      default: Date.now,
    },
    deletedAt: {
      type: Date,
      default: null,
    },
  },
  { _id: true }
);

const FoodLogTotalsSchema = new Schema<IFoodLogTotals>(
  {
    calories: { type: Number, default: 0 },
    proteinG: { type: Number, default: 0 },
    carbsG: { type: Number, default: 0 },
    fatG: { type: Number, default: 0 },
    fiberG: { type: Number, default: 0 },
    sugarG: { type: Number, default: 0 },
    sodiumMg: { type: Number, default: 0 },
    itemCount: { type: Number, default: 0 },
  },
  { _id: false }
);

const LocationSchema = new Schema<ILocation>(
  {
    name: { type: String },
    lat: { type: Number },
    lng: { type: Number },
  },
  { _id: false }
);

const FoodLogSchema = new Schema<IFoodLog>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    loggedDate: {
      type: String,
      required: true,
    },
    loggedAt: {
      type: Date,
      required: true,
    },
    mealType: {
      type: String,
      enum: ["breakfast", "lunch", "dinner", "snack"],
      required: true,
    },
    mealName: {
      type: String,
    },
    entryMethod: {
      type: String,
      enum: [
        "manual",
        "barcode",
        "photo_ai",
        "voice",
        "quick_add",
        "copy",
        "recipe",
      ],
      default: "manual",
    },
    items: {
      type: [FoodLogItemSchema],
      default: [],
    },
    totals: {
      type: FoodLogTotalsSchema,
      default: {},
    },
    notes: {
      type: String,
    },
    mood: {
      type: String,
      enum: ["great", "good", "neutral", "bad", "terrible"],
    },
    hungerLevel: {
      type: Number,
      min: 1,
      max: 5,
    },
    location: {
      type: LocationSchema,
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
FoodLogSchema.index({ userId: 1, loggedDate: -1 });
FoodLogSchema.index({ userId: 1, loggedDate: 1, mealType: 1 });
FoodLogSchema.index({ userId: 1, deletedAt: 1, loggedDate: -1 });
FoodLogSchema.index({ "items.foodId": 1 });
FoodLogSchema.index({ userId: 1, updatedAt: -1 });

export const FoodLog = mongoose.model<IFoodLog>("FoodLog", FoodLogSchema);
