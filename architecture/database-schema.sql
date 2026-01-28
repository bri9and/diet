-- =============================================================================
-- Diet Tracking App - Complete PostgreSQL Schema
-- =============================================================================
-- Version: 1.0.0
-- Date: 2026-01-27
-- Platform: Supabase PostgreSQL 15+
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For fuzzy text search

-- =============================================================================
-- SECTION 1: CORE USER TABLES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Table: users
-- Description: Core user profile and preferences
-- -----------------------------------------------------------------------------
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Auth linkage (Supabase Auth user ID)
    auth_id UUID UNIQUE NOT NULL,

    -- Profile information
    email TEXT NOT NULL,
    display_name TEXT,
    avatar_url TEXT,

    -- User preferences
    timezone TEXT DEFAULT 'UTC',
    unit_system TEXT DEFAULT 'metric'
        CHECK (unit_system IN ('metric', 'imperial')),
    language TEXT DEFAULT 'en',
    date_format TEXT DEFAULT 'yyyy-MM-dd',
    start_of_week INTEGER DEFAULT 1 CHECK (start_of_week BETWEEN 0 AND 6),

    -- Subscription management
    subscription_tier TEXT DEFAULT 'free'
        CHECK (subscription_tier IN ('free', 'premium', 'family')),
    subscription_expires_at TIMESTAMPTZ,
    stripe_customer_id TEXT,

    -- Privacy settings
    share_with_family BOOLEAN DEFAULT false,
    ai_processing_consent BOOLEAN DEFAULT true,
    analytics_consent BOOLEAN DEFAULT true,

    -- Feature flags
    beta_features_enabled BOOLEAN DEFAULT false,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    deleted_at TIMESTAMPTZ,  -- Soft delete

    -- Sync metadata (for PowerSync)
    _synced_at TIMESTAMPTZ,
    _local_only BOOLEAN DEFAULT false
);

-- Indexes for users
CREATE INDEX idx_users_auth_id ON users(auth_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_subscription ON users(subscription_tier, subscription_expires_at);
CREATE INDEX idx_users_active ON users(deleted_at) WHERE deleted_at IS NULL;

-- -----------------------------------------------------------------------------
-- Table: user_goals
-- Description: Nutrition and fitness goals per user
-- -----------------------------------------------------------------------------
CREATE TABLE user_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Goal classification
    goal_type TEXT NOT NULL
        CHECK (goal_type IN ('weight_loss', 'weight_gain', 'maintenance', 'muscle_gain', 'custom')),
    goal_name TEXT,  -- Optional custom name

    -- Daily nutrition targets
    calories_target INTEGER CHECK (calories_target > 0 AND calories_target < 10000),
    protein_target_g DECIMAL(6,2) CHECK (protein_target_g >= 0),
    carbs_target_g DECIMAL(6,2) CHECK (carbs_target_g >= 0),
    fat_target_g DECIMAL(6,2) CHECK (fat_target_g >= 0),
    fiber_target_g DECIMAL(6,2) CHECK (fiber_target_g >= 0),
    sugar_limit_g DECIMAL(6,2) CHECK (sugar_limit_g >= 0),
    sodium_limit_mg DECIMAL(8,2) CHECK (sodium_limit_mg >= 0),
    water_target_ml INTEGER CHECK (water_target_ml >= 0),

    -- Body metrics for TDEE calculation
    current_weight_kg DECIMAL(5,2) CHECK (current_weight_kg > 0 AND current_weight_kg < 500),
    target_weight_kg DECIMAL(5,2) CHECK (target_weight_kg > 0 AND target_weight_kg < 500),
    height_cm DECIMAL(5,2) CHECK (height_cm > 0 AND height_cm < 300),
    birth_date DATE,
    sex TEXT CHECK (sex IN ('male', 'female', 'other')),
    activity_level TEXT
        CHECK (activity_level IN ('sedentary', 'light', 'moderate', 'active', 'very_active')),
    body_fat_percentage DECIMAL(4,2) CHECK (body_fat_percentage > 0 AND body_fat_percentage < 100),

    -- Goal timeline
    target_date DATE,
    weekly_change_kg DECIMAL(3,2),  -- Positive = gain, negative = loss

    -- Macro ratio (percentages, should sum to 100)
    protein_percentage INTEGER CHECK (protein_percentage >= 0 AND protein_percentage <= 100),
    carbs_percentage INTEGER CHECK (carbs_percentage >= 0 AND carbs_percentage <= 100),
    fat_percentage INTEGER CHECK (fat_percentage >= 0 AND fat_percentage <= 100),

    -- Status
    is_active BOOLEAN DEFAULT true,
    started_at DATE DEFAULT CURRENT_DATE,
    ended_at DATE,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    deleted_at TIMESTAMPTZ,

    -- Sync metadata
    _synced_at TIMESTAMPTZ,
    _local_only BOOLEAN DEFAULT false,

    -- Constraint: Only one active goal per user
    CONSTRAINT unique_active_goal UNIQUE (user_id, is_active)
        WHERE (is_active = true AND deleted_at IS NULL)
);

-- Indexes for user_goals
CREATE INDEX idx_user_goals_user_id ON user_goals(user_id);
CREATE INDEX idx_user_goals_active ON user_goals(user_id, is_active) WHERE is_active = true;

-- =============================================================================
-- SECTION 2: FOOD DATABASE TABLES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Table: foods
-- Description: Food items from all sources (API cache + custom)
-- -----------------------------------------------------------------------------
CREATE TABLE foods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Source identification
    source TEXT NOT NULL
        CHECK (source IN ('nutritionix', 'openfoodfacts', 'usda', 'custom')),
    external_id TEXT,      -- ID from external API
    barcode TEXT,          -- UPC/EAN barcode

    -- For custom foods
    created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    is_public BOOLEAN DEFAULT false,  -- Share with other users
    is_verified BOOLEAN DEFAULT false, -- Admin verified

    -- Basic information
    name TEXT NOT NULL,
    brand TEXT,
    description TEXT,
    category TEXT,
    subcategory TEXT,

    -- Serving information
    serving_size DECIMAL(8,2) NOT NULL CHECK (serving_size > 0),
    serving_unit TEXT NOT NULL,  -- 'g', 'ml', 'oz', 'cup', 'piece', 'slice', etc.
    serving_description TEXT,     -- Human readable: "1 medium apple (182g)"
    servings_per_container DECIMAL(6,2),

    -- Primary nutrition per serving
    calories DECIMAL(8,2) CHECK (calories >= 0),
    protein_g DECIMAL(8,2) CHECK (protein_g >= 0),
    carbs_g DECIMAL(8,2) CHECK (carbs_g >= 0),
    fat_g DECIMAL(8,2) CHECK (fat_g >= 0),
    fiber_g DECIMAL(8,2) CHECK (fiber_g >= 0),
    sugar_g DECIMAL(8,2) CHECK (sugar_g >= 0),
    sodium_mg DECIMAL(8,2) CHECK (sodium_mg >= 0),
    saturated_fat_g DECIMAL(8,2) CHECK (saturated_fat_g >= 0),
    trans_fat_g DECIMAL(8,2) CHECK (trans_fat_g >= 0),
    cholesterol_mg DECIMAL(8,2) CHECK (cholesterol_mg >= 0),
    potassium_mg DECIMAL(8,2) CHECK (potassium_mg >= 0),

    -- Extended nutrition (JSON for flexibility)
    extended_nutrition JSONB DEFAULT '{}'::jsonb,
    -- Example structure:
    -- {
    --   "vitamin_a_iu": 500,
    --   "vitamin_c_mg": 10,
    --   "calcium_mg": 100,
    --   "iron_mg": 2,
    --   "vitamin_d_iu": 0,
    --   "vitamin_b12_mcg": 0,
    --   "omega_3_g": 0.1,
    --   "caffeine_mg": 0
    -- }

    -- Alternative serving sizes
    alt_serving_sizes JSONB DEFAULT '[]'::jsonb,
    -- Example: [{"size": 28, "unit": "g", "description": "1 oz"}, {"size": 1, "unit": "cup", "grams": 240}]

    -- Media
    photo_url TEXT,
    thumbnail_url TEXT,

    -- Search optimization
    search_keywords TEXT[],
    search_vector tsvector,

    -- Usage statistics (for ranking)
    global_use_count INTEGER DEFAULT 0,

    -- Cache management (for API-sourced foods)
    cached_at TIMESTAMPTZ,
    cache_expires_at TIMESTAMPTZ,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    deleted_at TIMESTAMPTZ,

    -- Sync metadata (only custom foods sync via PowerSync)
    _synced_at TIMESTAMPTZ,
    _local_only BOOLEAN DEFAULT false
);

-- Unique constraints
CREATE UNIQUE INDEX idx_foods_source_external ON foods(source, external_id)
    WHERE external_id IS NOT NULL;
CREATE UNIQUE INDEX idx_foods_barcode ON foods(barcode)
    WHERE barcode IS NOT NULL;

-- Search indexes
CREATE INDEX idx_foods_source ON foods(source);
CREATE INDEX idx_foods_created_by ON foods(created_by_user_id)
    WHERE created_by_user_id IS NOT NULL;
CREATE INDEX idx_foods_keywords ON foods USING gin(search_keywords);
CREATE INDEX idx_foods_name_trgm ON foods USING gin(name gin_trgm_ops);
CREATE INDEX idx_foods_search_vector ON foods USING gin(search_vector);
CREATE INDEX idx_foods_cache_expires ON foods(cache_expires_at)
    WHERE source != 'custom';
CREATE INDEX idx_foods_public_custom ON foods(is_public)
    WHERE source = 'custom' AND is_public = true;

-- Trigger to update search vector
CREATE OR REPLACE FUNCTION foods_search_vector_trigger() RETURNS trigger AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('english', COALESCE(NEW.name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.brand, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.description, '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(NEW.category, '')), 'D');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER foods_search_vector_update
    BEFORE INSERT OR UPDATE ON foods
    FOR EACH ROW
    EXECUTE FUNCTION foods_search_vector_trigger();

-- =============================================================================
-- SECTION 3: FOOD LOGGING TABLES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Table: food_logs
-- Description: Container for meals/eating occasions
-- -----------------------------------------------------------------------------
CREATE TABLE food_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Temporal information
    logged_date DATE NOT NULL,
    logged_at TIMESTAMPTZ DEFAULT now(),

    -- Meal categorization
    meal_type TEXT NOT NULL
        CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    meal_name TEXT,  -- Optional custom name: "Pre-workout", "Late night snack"

    -- Entry metadata
    entry_method TEXT DEFAULT 'manual'
        CHECK (entry_method IN ('manual', 'barcode', 'photo_ai', 'voice', 'quick_add', 'copy', 'recipe')),

    -- Notes and context
    notes TEXT,
    mood TEXT CHECK (mood IN ('great', 'good', 'neutral', 'bad', 'terrible')),
    hunger_level INTEGER CHECK (hunger_level BETWEEN 1 AND 5),

    -- Optional location
    location_name TEXT,
    location_lat DECIMAL(10,7),
    location_lng DECIMAL(10,7),

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    deleted_at TIMESTAMPTZ,

    -- Sync metadata
    _synced_at TIMESTAMPTZ,
    _local_only BOOLEAN DEFAULT false
);

-- Indexes for food_logs
CREATE INDEX idx_food_logs_user_date ON food_logs(user_id, logged_date DESC);
CREATE INDEX idx_food_logs_user_meal ON food_logs(user_id, logged_date, meal_type);
CREATE INDEX idx_food_logs_active ON food_logs(deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_food_logs_date_range ON food_logs(user_id, logged_date)
    WHERE deleted_at IS NULL;

-- -----------------------------------------------------------------------------
-- Table: meal_items
-- Description: Individual food items within a meal/food_log
-- -----------------------------------------------------------------------------
CREATE TABLE meal_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    food_log_id UUID NOT NULL REFERENCES food_logs(id) ON DELETE CASCADE,
    food_id UUID REFERENCES foods(id) ON DELETE SET NULL,  -- NULL for quick-add

    -- Quantity
    quantity DECIMAL(8,2) NOT NULL DEFAULT 1 CHECK (quantity > 0),
    serving_multiplier DECIMAL(6,3) DEFAULT 1 CHECK (serving_multiplier > 0),
    -- Example: quantity=2, serving_multiplier=0.5 means 2 half-servings = 1 full serving

    -- Denormalized nutrition (actual consumed values)
    -- These are calculated at log time and preserved for historical accuracy
    calories DECIMAL(8,2),
    protein_g DECIMAL(8,2),
    carbs_g DECIMAL(8,2),
    fat_g DECIMAL(8,2),
    fiber_g DECIMAL(8,2),
    sugar_g DECIMAL(8,2),
    sodium_mg DECIMAL(8,2),

    -- Quick-add fields (when food_id is NULL)
    quick_add_name TEXT,
    quick_add_description TEXT,

    -- Display order within meal
    sort_order INTEGER DEFAULT 0,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    deleted_at TIMESTAMPTZ,

    -- Sync metadata
    _synced_at TIMESTAMPTZ,
    _local_only BOOLEAN DEFAULT false,

    -- Validation: either food_id or quick_add_name required
    CONSTRAINT valid_meal_item CHECK (
        food_id IS NOT NULL OR quick_add_name IS NOT NULL
    )
);

-- Indexes for meal_items
CREATE INDEX idx_meal_items_food_log ON meal_items(food_log_id);
CREATE INDEX idx_meal_items_food ON meal_items(food_id) WHERE food_id IS NOT NULL;
CREATE INDEX idx_meal_items_active ON meal_items(deleted_at) WHERE deleted_at IS NULL;

-- =============================================================================
-- SECTION 4: USER ACTIVITY TRACKING
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Table: recent_foods
-- Description: User's frequently used foods for quick access
-- -----------------------------------------------------------------------------
CREATE TABLE recent_foods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    food_id UUID NOT NULL REFERENCES foods(id) ON DELETE CASCADE,

    -- Usage statistics
    use_count INTEGER DEFAULT 1 CHECK (use_count > 0),
    last_used_at TIMESTAMPTZ DEFAULT now(),

    -- Preferred serving
    preferred_quantity DECIMAL(8,2) DEFAULT 1,
    preferred_serving_multiplier DECIMAL(6,3) DEFAULT 1,

    -- Meal association (which meal this food is typically used for)
    common_meal_type TEXT CHECK (common_meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,

    -- Sync metadata
    _synced_at TIMESTAMPTZ,
    _local_only BOOLEAN DEFAULT false,

    CONSTRAINT unique_user_food UNIQUE (user_id, food_id)
);

-- Indexes for recent_foods
CREATE INDEX idx_recent_foods_user_recent ON recent_foods(user_id, last_used_at DESC);
CREATE INDEX idx_recent_foods_user_frequent ON recent_foods(user_id, use_count DESC);

-- -----------------------------------------------------------------------------
-- Table: daily_summaries
-- Description: Pre-computed daily nutrition totals
-- -----------------------------------------------------------------------------
CREATE TABLE daily_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    summary_date DATE NOT NULL,

    -- Aggregated nutrition totals
    total_calories DECIMAL(10,2) DEFAULT 0,
    total_protein_g DECIMAL(10,2) DEFAULT 0,
    total_carbs_g DECIMAL(10,2) DEFAULT 0,
    total_fat_g DECIMAL(10,2) DEFAULT 0,
    total_fiber_g DECIMAL(10,2) DEFAULT 0,
    total_sugar_g DECIMAL(10,2) DEFAULT 0,
    total_sodium_mg DECIMAL(10,2) DEFAULT 0,

    -- Per-meal breakdowns
    breakfast_calories DECIMAL(10,2) DEFAULT 0,
    lunch_calories DECIMAL(10,2) DEFAULT 0,
    dinner_calories DECIMAL(10,2) DEFAULT 0,
    snack_calories DECIMAL(10,2) DEFAULT 0,

    -- Meal counts
    total_meals INTEGER DEFAULT 0,
    total_items INTEGER DEFAULT 0,

    -- Goal snapshot (for historical comparison)
    calories_target INTEGER,
    protein_target_g DECIMAL(6,2),
    carbs_target_g DECIMAL(6,2),
    fat_target_g DECIMAL(6,2),

    -- Completion metrics
    calories_percentage DECIMAL(5,2),  -- Actual/Target * 100
    protein_percentage DECIMAL(5,2),
    carbs_percentage DECIMAL(5,2),
    fat_percentage DECIMAL(5,2),

    -- Computation metadata
    computed_at TIMESTAMPTZ DEFAULT now(),
    is_complete BOOLEAN DEFAULT false,  -- User marked day as complete

    -- Sync metadata
    _synced_at TIMESTAMPTZ,
    _local_only BOOLEAN DEFAULT false,

    CONSTRAINT unique_user_date_summary UNIQUE (user_id, summary_date)
);

-- Indexes for daily_summaries
CREATE INDEX idx_daily_summaries_user_date ON daily_summaries(user_id, summary_date DESC);
CREATE INDEX idx_daily_summaries_recent ON daily_summaries(user_id, summary_date DESC)
    WHERE summary_date >= CURRENT_DATE - INTERVAL '90 days';

-- =============================================================================
-- SECTION 5: FAMILY SHARING TABLES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Table: families
-- Description: Family groups for shared meal planning/logging
-- -----------------------------------------------------------------------------
CREATE TABLE families (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Family information
    name TEXT NOT NULL,
    description TEXT,
    created_by_user_id UUID NOT NULL REFERENCES users(id),

    -- Settings
    max_members INTEGER DEFAULT 6 CHECK (max_members > 0 AND max_members <= 20),

    -- Photo
    avatar_url TEXT,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    deleted_at TIMESTAMPTZ,

    -- Sync metadata
    _synced_at TIMESTAMPTZ,
    _local_only BOOLEAN DEFAULT false
);

-- Indexes for families
CREATE INDEX idx_families_created_by ON families(created_by_user_id);
CREATE INDEX idx_families_active ON families(deleted_at) WHERE deleted_at IS NULL;

-- -----------------------------------------------------------------------------
-- Table: family_members
-- Description: Junction table for family membership
-- -----------------------------------------------------------------------------
CREATE TABLE family_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Role and permissions
    role TEXT NOT NULL DEFAULT 'member'
        CHECK (role IN ('owner', 'admin', 'member', 'viewer')),

    -- What this member shares with family
    share_food_logs BOOLEAN DEFAULT true,
    share_goals BOOLEAN DEFAULT false,
    share_weight BOOLEAN DEFAULT false,

    -- What this member can see from others
    can_view_food_logs BOOLEAN DEFAULT true,
    can_view_goals BOOLEAN DEFAULT false,
    can_view_weight BOOLEAN DEFAULT false,

    -- Membership status
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'left')),
    joined_at TIMESTAMPTZ DEFAULT now(),
    left_at TIMESTAMPTZ,

    -- Notifications
    notify_family_meals BOOLEAN DEFAULT true,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    deleted_at TIMESTAMPTZ,

    -- Sync metadata
    _synced_at TIMESTAMPTZ,
    _local_only BOOLEAN DEFAULT false,

    -- Constraints
    CONSTRAINT unique_family_user UNIQUE (family_id, user_id)
);

-- Indexes for family_members
CREATE INDEX idx_family_members_family ON family_members(family_id);
CREATE INDEX idx_family_members_user ON family_members(user_id);
CREATE INDEX idx_family_members_active ON family_members(family_id, user_id)
    WHERE status = 'active';

-- -----------------------------------------------------------------------------
-- Table: family_invites
-- Description: Pending invitations to join a family
-- -----------------------------------------------------------------------------
CREATE TABLE family_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,

    -- Invite details
    invited_by_user_id UUID NOT NULL REFERENCES users(id),
    invited_email TEXT NOT NULL,
    invite_code TEXT NOT NULL UNIQUE,  -- Short code for sharing

    -- Invitation message
    message TEXT,

    -- Proposed role
    proposed_role TEXT DEFAULT 'member'
        CHECK (proposed_role IN ('admin', 'member', 'viewer')),

    -- Status tracking
    status TEXT DEFAULT 'pending'
        CHECK (status IN ('pending', 'accepted', 'declined', 'expired', 'revoked')),
    expires_at TIMESTAMPTZ NOT NULL,
    responded_at TIMESTAMPTZ,
    accepted_by_user_id UUID REFERENCES users(id),

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,

    -- Sync metadata
    _synced_at TIMESTAMPTZ,
    _local_only BOOLEAN DEFAULT false
);

-- Indexes for family_invites
CREATE INDEX idx_family_invites_code ON family_invites(invite_code);
CREATE INDEX idx_family_invites_email ON family_invites(invited_email);
CREATE INDEX idx_family_invites_family ON family_invites(family_id);
CREATE INDEX idx_family_invites_pending ON family_invites(status, expires_at)
    WHERE status = 'pending';

-- =============================================================================
-- SECTION 6: WEIGHT & MEASUREMENTS TRACKING
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Table: weight_logs
-- Description: User weight measurements over time
-- -----------------------------------------------------------------------------
CREATE TABLE weight_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Measurement
    weight_kg DECIMAL(5,2) NOT NULL CHECK (weight_kg > 0 AND weight_kg < 500),
    measured_at TIMESTAMPTZ DEFAULT now(),
    measured_date DATE NOT NULL DEFAULT CURRENT_DATE,

    -- Optional additional measurements
    body_fat_percentage DECIMAL(4,2) CHECK (body_fat_percentage > 0 AND body_fat_percentage < 100),
    muscle_mass_kg DECIMAL(5,2),
    water_percentage DECIMAL(4,2),
    bone_mass_kg DECIMAL(4,2),

    -- Source of measurement
    source TEXT DEFAULT 'manual'
        CHECK (source IN ('manual', 'smart_scale', 'apple_health', 'fitbit', 'garmin')),

    -- Notes
    notes TEXT,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    deleted_at TIMESTAMPTZ,

    -- Sync metadata
    _synced_at TIMESTAMPTZ,
    _local_only BOOLEAN DEFAULT false
);

-- Indexes for weight_logs
CREATE INDEX idx_weight_logs_user_date ON weight_logs(user_id, measured_date DESC);
CREATE INDEX idx_weight_logs_recent ON weight_logs(user_id, measured_date DESC)
    WHERE measured_date >= CURRENT_DATE - INTERVAL '365 days';

-- =============================================================================
-- SECTION 7: COMMON FUNCTIONS AND TRIGGERS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Function: Update updated_at timestamp
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all relevant tables
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_type = 'BASE TABLE'
        AND EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_name = tables.table_name
            AND column_name = 'updated_at'
        )
    LOOP
        EXECUTE format(
            'CREATE TRIGGER update_%I_updated_at
             BEFORE UPDATE ON %I
             FOR EACH ROW EXECUTE FUNCTION update_updated_at()',
            t, t
        );
    END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- Function: Compute daily summary
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION compute_daily_summary(p_user_id UUID, p_date DATE)
RETURNS void AS $$
DECLARE
    v_goal RECORD;
BEGIN
    -- Get active goal for percentage calculations
    SELECT * INTO v_goal
    FROM user_goals
    WHERE user_id = p_user_id
    AND is_active = true
    AND deleted_at IS NULL
    LIMIT 1;

    INSERT INTO daily_summaries (
        user_id, summary_date,
        total_calories, total_protein_g, total_carbs_g, total_fat_g,
        total_fiber_g, total_sugar_g, total_sodium_mg,
        breakfast_calories, lunch_calories, dinner_calories, snack_calories,
        total_meals, total_items,
        calories_target, protein_target_g, carbs_target_g, fat_target_g,
        calories_percentage, protein_percentage, carbs_percentage, fat_percentage
    )
    SELECT
        p_user_id,
        p_date,
        COALESCE(SUM(mi.calories), 0),
        COALESCE(SUM(mi.protein_g), 0),
        COALESCE(SUM(mi.carbs_g), 0),
        COALESCE(SUM(mi.fat_g), 0),
        COALESCE(SUM(mi.fiber_g), 0),
        COALESCE(SUM(mi.sugar_g), 0),
        COALESCE(SUM(mi.sodium_mg), 0),
        COALESCE(SUM(mi.calories) FILTER (WHERE fl.meal_type = 'breakfast'), 0),
        COALESCE(SUM(mi.calories) FILTER (WHERE fl.meal_type = 'lunch'), 0),
        COALESCE(SUM(mi.calories) FILTER (WHERE fl.meal_type = 'dinner'), 0),
        COALESCE(SUM(mi.calories) FILTER (WHERE fl.meal_type = 'snack'), 0),
        COUNT(DISTINCT fl.id),
        COUNT(mi.id),
        v_goal.calories_target,
        v_goal.protein_target_g,
        v_goal.carbs_target_g,
        v_goal.fat_target_g,
        CASE WHEN v_goal.calories_target > 0
            THEN ROUND((SUM(mi.calories) / v_goal.calories_target) * 100, 2)
            ELSE NULL END,
        CASE WHEN v_goal.protein_target_g > 0
            THEN ROUND((SUM(mi.protein_g) / v_goal.protein_target_g) * 100, 2)
            ELSE NULL END,
        CASE WHEN v_goal.carbs_target_g > 0
            THEN ROUND((SUM(mi.carbs_g) / v_goal.carbs_target_g) * 100, 2)
            ELSE NULL END,
        CASE WHEN v_goal.fat_target_g > 0
            THEN ROUND((SUM(mi.fat_g) / v_goal.fat_target_g) * 100, 2)
            ELSE NULL END
    FROM food_logs fl
    LEFT JOIN meal_items mi ON fl.id = mi.food_log_id AND mi.deleted_at IS NULL
    WHERE fl.user_id = p_user_id
    AND fl.logged_date = p_date
    AND fl.deleted_at IS NULL
    ON CONFLICT (user_id, summary_date)
    DO UPDATE SET
        total_calories = EXCLUDED.total_calories,
        total_protein_g = EXCLUDED.total_protein_g,
        total_carbs_g = EXCLUDED.total_carbs_g,
        total_fat_g = EXCLUDED.total_fat_g,
        total_fiber_g = EXCLUDED.total_fiber_g,
        total_sugar_g = EXCLUDED.total_sugar_g,
        total_sodium_mg = EXCLUDED.total_sodium_mg,
        breakfast_calories = EXCLUDED.breakfast_calories,
        lunch_calories = EXCLUDED.lunch_calories,
        dinner_calories = EXCLUDED.dinner_calories,
        snack_calories = EXCLUDED.snack_calories,
        total_meals = EXCLUDED.total_meals,
        total_items = EXCLUDED.total_items,
        calories_target = EXCLUDED.calories_target,
        protein_target_g = EXCLUDED.protein_target_g,
        carbs_target_g = EXCLUDED.carbs_target_g,
        fat_target_g = EXCLUDED.fat_target_g,
        calories_percentage = EXCLUDED.calories_percentage,
        protein_percentage = EXCLUDED.protein_percentage,
        carbs_percentage = EXCLUDED.carbs_percentage,
        fat_percentage = EXCLUDED.fat_percentage,
        computed_at = now();
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- Function: Auto-update daily summary when meal items change
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_daily_summary_on_item_change()
RETURNS TRIGGER AS $$
DECLARE
    v_food_log RECORD;
BEGIN
    -- Get the food log to find user and date
    SELECT fl.user_id, fl.logged_date INTO v_food_log
    FROM food_logs fl
    WHERE fl.id = COALESCE(NEW.food_log_id, OLD.food_log_id);

    IF v_food_log.user_id IS NOT NULL THEN
        PERFORM compute_daily_summary(v_food_log.user_id, v_food_log.logged_date);
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_daily_summary
    AFTER INSERT OR UPDATE OR DELETE ON meal_items
    FOR EACH ROW
    EXECUTE FUNCTION update_daily_summary_on_item_change();

-- =============================================================================
-- SECTION 8: ROW-LEVEL SECURITY POLICIES
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE food_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE recent_foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE weight_logs ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Users Policies
-- -----------------------------------------------------------------------------

-- Users can read and update their own profile
CREATE POLICY users_own_access ON users
    FOR ALL
    USING (auth.uid() = auth_id)
    WITH CHECK (auth.uid() = auth_id);

-- Users can view family members' basic profiles (via explicit family membership)
CREATE POLICY users_family_view ON users
    FOR SELECT
    USING (
        id IN (
            SELECT fm2.user_id
            FROM family_members fm1
            JOIN family_members fm2 ON fm1.family_id = fm2.family_id
            WHERE fm1.user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
            AND fm2.user_id != fm1.user_id
            AND fm1.status = 'active'
            AND fm2.status = 'active'
        )
    );

-- -----------------------------------------------------------------------------
-- User Goals Policies
-- -----------------------------------------------------------------------------

-- Own goals access
CREATE POLICY user_goals_own_access ON user_goals
    FOR ALL
    USING (user_id = (SELECT id FROM users WHERE auth_id = auth.uid()))
    WITH CHECK (user_id = (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Family can view shared goals
CREATE POLICY user_goals_family_view ON user_goals
    FOR SELECT
    USING (
        user_id IN (
            SELECT fm2.user_id
            FROM family_members fm1
            JOIN family_members fm2 ON fm1.family_id = fm2.family_id
            WHERE fm1.user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
            AND fm2.share_goals = true
            AND fm1.can_view_goals = true
            AND fm1.status = 'active'
            AND fm2.status = 'active'
        )
    );

-- -----------------------------------------------------------------------------
-- Foods Policies
-- -----------------------------------------------------------------------------

-- Anyone can read non-custom or public custom foods
CREATE POLICY foods_public_read ON foods
    FOR SELECT
    USING (source != 'custom' OR is_public = true);

-- Users can CRUD their own custom foods
CREATE POLICY foods_own_custom ON foods
    FOR ALL
    USING (
        source = 'custom'
        AND created_by_user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
    )
    WITH CHECK (
        source = 'custom'
        AND created_by_user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
    );

-- Service role can manage all foods (for caching)
CREATE POLICY foods_service_role ON foods
    FOR ALL
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

-- -----------------------------------------------------------------------------
-- Food Logs Policies
-- -----------------------------------------------------------------------------

-- Own food logs access
CREATE POLICY food_logs_own_access ON food_logs
    FOR ALL
    USING (user_id = (SELECT id FROM users WHERE auth_id = auth.uid()))
    WITH CHECK (user_id = (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Family can view shared food logs
CREATE POLICY food_logs_family_view ON food_logs
    FOR SELECT
    USING (
        user_id IN (
            SELECT fm2.user_id
            FROM family_members fm1
            JOIN family_members fm2 ON fm1.family_id = fm2.family_id
            JOIN users u ON fm2.user_id = u.id
            WHERE fm1.user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
            AND fm2.share_food_logs = true
            AND fm1.can_view_food_logs = true
            AND u.share_with_family = true
            AND fm1.status = 'active'
            AND fm2.status = 'active'
        )
    );

-- -----------------------------------------------------------------------------
-- Meal Items Policies
-- -----------------------------------------------------------------------------

-- Own meal items (via food log ownership)
CREATE POLICY meal_items_own_access ON meal_items
    FOR ALL
    USING (
        food_log_id IN (
            SELECT id FROM food_logs
            WHERE user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
        )
    )
    WITH CHECK (
        food_log_id IN (
            SELECT id FROM food_logs
            WHERE user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
        )
    );

-- Family can view meal items in shared logs
CREATE POLICY meal_items_family_view ON meal_items
    FOR SELECT
    USING (
        food_log_id IN (
            SELECT fl.id FROM food_logs fl
            JOIN family_members fm1 ON fm1.user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
            JOIN family_members fm2 ON fm1.family_id = fm2.family_id AND fl.user_id = fm2.user_id
            JOIN users u ON fl.user_id = u.id
            WHERE fm2.share_food_logs = true
            AND fm1.can_view_food_logs = true
            AND u.share_with_family = true
            AND fm1.status = 'active'
            AND fm2.status = 'active'
        )
    );

-- -----------------------------------------------------------------------------
-- Recent Foods Policies
-- -----------------------------------------------------------------------------
CREATE POLICY recent_foods_own_access ON recent_foods
    FOR ALL
    USING (user_id = (SELECT id FROM users WHERE auth_id = auth.uid()))
    WITH CHECK (user_id = (SELECT id FROM users WHERE auth_id = auth.uid()));

-- -----------------------------------------------------------------------------
-- Daily Summaries Policies
-- -----------------------------------------------------------------------------
CREATE POLICY daily_summaries_own_access ON daily_summaries
    FOR ALL
    USING (user_id = (SELECT id FROM users WHERE auth_id = auth.uid()))
    WITH CHECK (user_id = (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Family can view summaries when logs are shared
CREATE POLICY daily_summaries_family_view ON daily_summaries
    FOR SELECT
    USING (
        user_id IN (
            SELECT fm2.user_id
            FROM family_members fm1
            JOIN family_members fm2 ON fm1.family_id = fm2.family_id
            JOIN users u ON fm2.user_id = u.id
            WHERE fm1.user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
            AND fm2.share_food_logs = true
            AND fm1.can_view_food_logs = true
            AND u.share_with_family = true
            AND fm1.status = 'active'
            AND fm2.status = 'active'
        )
    );

-- -----------------------------------------------------------------------------
-- Families Policies
-- -----------------------------------------------------------------------------

-- Members can view their families
CREATE POLICY families_member_view ON families
    FOR SELECT
    USING (
        id IN (
            SELECT family_id FROM family_members
            WHERE user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
            AND status = 'active'
        )
    );

-- Owner/Admin can update family
CREATE POLICY families_admin_update ON families
    FOR UPDATE
    USING (
        id IN (
            SELECT family_id FROM family_members
            WHERE user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
            AND role IN ('owner', 'admin')
            AND status = 'active'
        )
    );

-- Only owner can delete family
CREATE POLICY families_owner_delete ON families
    FOR DELETE
    USING (
        created_by_user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
    );

-- Authenticated users can create families
CREATE POLICY families_create ON families
    FOR INSERT
    WITH CHECK (
        created_by_user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
    );

-- -----------------------------------------------------------------------------
-- Family Members Policies
-- -----------------------------------------------------------------------------

-- Members can view membership in their families
CREATE POLICY family_members_view ON family_members
    FOR SELECT
    USING (
        family_id IN (
            SELECT family_id FROM family_members
            WHERE user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
            AND status = 'active'
        )
    );

-- Users can update their own membership settings
CREATE POLICY family_members_own_update ON family_members
    FOR UPDATE
    USING (user_id = (SELECT id FROM users WHERE auth_id = auth.uid()))
    WITH CHECK (user_id = (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Owner/Admin can manage members
CREATE POLICY family_members_admin_manage ON family_members
    FOR ALL
    USING (
        family_id IN (
            SELECT family_id FROM family_members
            WHERE user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
            AND role IN ('owner', 'admin')
            AND status = 'active'
        )
    );

-- -----------------------------------------------------------------------------
-- Family Invites Policies
-- -----------------------------------------------------------------------------

-- Invited user can view their invites
CREATE POLICY family_invites_recipient_view ON family_invites
    FOR SELECT
    USING (
        invited_email = (SELECT email FROM users WHERE auth_id = auth.uid())
        OR invited_by_user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
    );

-- Owner/Admin can create invites
CREATE POLICY family_invites_admin_create ON family_invites
    FOR INSERT
    WITH CHECK (
        family_id IN (
            SELECT family_id FROM family_members
            WHERE user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
            AND role IN ('owner', 'admin')
            AND status = 'active'
        )
    );

-- Recipient can update (accept/decline)
CREATE POLICY family_invites_recipient_update ON family_invites
    FOR UPDATE
    USING (
        invited_email = (SELECT email FROM users WHERE auth_id = auth.uid())
    );

-- -----------------------------------------------------------------------------
-- Weight Logs Policies
-- -----------------------------------------------------------------------------

-- Own weight logs
CREATE POLICY weight_logs_own_access ON weight_logs
    FOR ALL
    USING (user_id = (SELECT id FROM users WHERE auth_id = auth.uid()))
    WITH CHECK (user_id = (SELECT id FROM users WHERE auth_id = auth.uid()));

-- Family can view if weight sharing enabled
CREATE POLICY weight_logs_family_view ON weight_logs
    FOR SELECT
    USING (
        user_id IN (
            SELECT fm2.user_id
            FROM family_members fm1
            JOIN family_members fm2 ON fm1.family_id = fm2.family_id
            WHERE fm1.user_id = (SELECT id FROM users WHERE auth_id = auth.uid())
            AND fm2.share_weight = true
            AND fm1.can_view_weight = true
            AND fm1.status = 'active'
            AND fm2.status = 'active'
        )
    );

-- =============================================================================
-- SECTION 9: VIEWS FOR COMMON QUERIES
-- =============================================================================

-- Weekly summary view
CREATE OR REPLACE VIEW weekly_summaries AS
SELECT
    user_id,
    date_trunc('week', summary_date)::DATE as week_start,
    SUM(total_calories) as total_calories,
    AVG(total_calories) as avg_daily_calories,
    SUM(total_protein_g) as total_protein_g,
    SUM(total_carbs_g) as total_carbs_g,
    SUM(total_fat_g) as total_fat_g,
    AVG(calories_percentage) as avg_calorie_adherence,
    COUNT(*) as days_logged
FROM daily_summaries
GROUP BY user_id, date_trunc('week', summary_date);

-- User's recent meals view (for quick logging)
CREATE OR REPLACE VIEW recent_meals AS
SELECT DISTINCT ON (fl.user_id, fl.meal_type, mi.food_id)
    fl.user_id,
    fl.meal_type,
    mi.food_id,
    f.name as food_name,
    f.brand,
    mi.quantity,
    mi.serving_multiplier,
    mi.calories,
    fl.logged_at
FROM food_logs fl
JOIN meal_items mi ON fl.id = mi.food_log_id
JOIN foods f ON mi.food_id = f.id
WHERE fl.deleted_at IS NULL
AND mi.deleted_at IS NULL
AND fl.logged_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY fl.user_id, fl.meal_type, mi.food_id, fl.logged_at DESC;

-- =============================================================================
-- END OF SCHEMA
-- =============================================================================
