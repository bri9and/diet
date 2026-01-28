import mongoose, { Document, Schema, Types } from "mongoose";

export interface INutrition {
  calories: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
  fiberG?: number;
  sugarG?: number;
  sodiumMg?: number;
  saturatedFatG?: number;
  transFatG?: number;
  cholesterolMg?: number;
  potassiumMg?: number;
}

export interface IExtendedNutrition {
  vitaminAIu?: number;
  vitaminCMg?: number;
  calciumMg?: number;
  ironMg?: number;
  vitaminDIu?: number;
  vitaminB12Mcg?: number;
  omega3G?: number;
  caffeineMg?: number;
}

export interface IAltServingSize {
  size: number;
  unit: string;
  description: string;
}

export interface IFood extends Document {
  source: "nutritionix" | "openfoodfacts" | "usda" | "custom";
  externalId?: string;
  barcode?: string;
  createdByUserId?: Types.ObjectId;
  isPublic: boolean;
  isVerified: boolean;
  name: string;
  brand?: string;
  description?: string;
  category?: string;
  subcategory?: string;
  servingSize: number;
  servingUnit: string;
  servingDescription?: string;
  servingsPerContainer?: number;
  altServingSizes: IAltServingSize[];
  nutrition: INutrition;
  extendedNutrition?: IExtendedNutrition;
  photoUrl?: string;
  thumbnailUrl?: string;
  searchKeywords: string[];
  globalUseCount: number;
  cachedAt?: Date;
  cacheExpiresAt?: Date;
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date;
}

const NutritionSchema = new Schema<INutrition>(
  {
    calories: { type: Number, required: true },
    proteinG: { type: Number, required: true },
    carbsG: { type: Number, required: true },
    fatG: { type: Number, required: true },
    fiberG: { type: Number },
    sugarG: { type: Number },
    sodiumMg: { type: Number },
    saturatedFatG: { type: Number },
    transFatG: { type: Number },
    cholesterolMg: { type: Number },
    potassiumMg: { type: Number },
  },
  { _id: false }
);

const ExtendedNutritionSchema = new Schema<IExtendedNutrition>(
  {
    vitaminAIu: { type: Number },
    vitaminCMg: { type: Number },
    calciumMg: { type: Number },
    ironMg: { type: Number },
    vitaminDIu: { type: Number },
    vitaminB12Mcg: { type: Number },
    omega3G: { type: Number },
    caffeineMg: { type: Number },
  },
  { _id: false }
);

const AltServingSizeSchema = new Schema<IAltServingSize>(
  {
    size: { type: Number, required: true },
    unit: { type: String, required: true },
    description: { type: String, required: true },
  },
  { _id: false }
);

const FoodSchema = new Schema<IFood>(
  {
    source: {
      type: String,
      enum: ["nutritionix", "openfoodfacts", "usda", "custom"],
      required: true,
    },
    externalId: {
      type: String,
      sparse: true,
    },
    barcode: {
      type: String,
      sparse: true,
    },
    createdByUserId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      sparse: true,
    },
    isPublic: {
      type: Boolean,
      default: false,
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
    name: {
      type: String,
      required: true,
    },
    brand: {
      type: String,
    },
    description: {
      type: String,
    },
    category: {
      type: String,
    },
    subcategory: {
      type: String,
    },
    servingSize: {
      type: Number,
      required: true,
    },
    servingUnit: {
      type: String,
      required: true,
    },
    servingDescription: {
      type: String,
    },
    servingsPerContainer: {
      type: Number,
    },
    altServingSizes: {
      type: [AltServingSizeSchema],
      default: [],
    },
    nutrition: {
      type: NutritionSchema,
      required: true,
    },
    extendedNutrition: {
      type: ExtendedNutritionSchema,
    },
    photoUrl: {
      type: String,
    },
    thumbnailUrl: {
      type: String,
    },
    searchKeywords: {
      type: [String],
      default: [],
    },
    globalUseCount: {
      type: Number,
      default: 0,
    },
    cachedAt: {
      type: Date,
    },
    cacheExpiresAt: {
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
FoodSchema.index({ source: 1, externalId: 1 }, { unique: true, sparse: true });
FoodSchema.index({ barcode: 1 }, { unique: true, sparse: true });
FoodSchema.index({ createdByUserId: 1 }, { sparse: true });
FoodSchema.index({ name: "text", brand: "text", searchKeywords: "text" });
FoodSchema.index({ globalUseCount: -1 });
FoodSchema.index({ source: 1, isPublic: 1 });
FoodSchema.index({ cacheExpiresAt: 1 }, { expireAfterSeconds: 0 });

export const Food = mongoose.model<IFood>("Food", FoodSchema);
