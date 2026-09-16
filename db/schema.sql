-- =============================================================================
-- AgriLink (Bit App) Database Schema (PostgreSQL / ANSI SQL Compatible)
-- Description: Comprehensive database schema supporting the multi-role
--              agricultural marketplace connecting Farmers, Buyers, Transporters,
--              Government Authorities, and Platform Administrators.
-- Target Path: db/schema.sql
-- =============================================================================

-- Enable UUID extension if supported
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. ENUMS & DOMAIN TYPES
-- =============================================================================

DO $$ BEGIN
    CREATE TYPE user_role AS ENUM (
        'farmer',
        'business',     -- Buyer (wholesale company or retail individual)
        'government',   -- Government Agricultural Authority / Ministry
        'transporter'   -- Freight / logistics provider
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE production_status AS ENUM (
        'planned',
        'growing',
        'readyForHarvest',
        'available',
        'sold',
        'expired'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE demand_status AS ENUM (
        'open',
        'fulfilled',
        'closed'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE interest_status AS ENUM (
        'pending',
        'accepted',
        'rejected'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE quality_grade AS ENUM (
        'A',
        'B',
        'C'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE data_source_kind AS ENUM (
        'DEMO_SEED',
        'TRANSACTION_DERIVED',
        'ADMIN_MANUAL',
        'FARMER_SELF_REPORT'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE verification_status AS ENUM (
        'pending',
        'approved',
        'rejected'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE buyer_type AS ENUM (
        'company',      -- Commercial buyer (e.g. supermarket, food processor)
        'individual'    -- Retail / household buyer
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE transporter_type AS ENUM (
        'company',      -- Registered freight / logistics company
        'individual'    -- Independent vehicle owner / driver
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE auction_status AS ENUM (
        'scheduled',
        'open',
        'closed',
        'cancelled'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE order_status AS ENUM (
        'pending_farmer',
        'pending_buyer',
        'confirmed',
        'payment_pending',
        'paid',
        'delivery_required',
        'in_transit',
        'delivered',
        'completed',
        'cancelled',
        'disputed'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM (
        'pending',
        'sandbox_success',
        'sandbox_failed',
        'cancelled',
        'paid',
        'failed',
        'refunded',
        'partially_refunded'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE notification_audience AS ENUM (
        'farmer',
        'buyer',
        'admin',
        'transporter'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE delivery_method AS ENUM (
        'bit_app_transport',
        'own_transport'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE vehicle_type AS ENUM (
        'pickup',       -- Capacity up to 500 kg
        'small_lorry',  -- Capacity up to 1,500 kg
        'medium_lorry', -- Capacity up to 5,000 kg
        'large_lorry'   -- Capacity up to 15,000 kg
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE transport_status AS ENUM (
        'requested',
        'matching',
        'assigned',
        'accepted',
        'waiting_pickup',
        'arrived_at_pickup',
        'loaded',
        'in_transit',
        'arrived_at_destination',
        'delivered',
        'buyer_confirmed',
        'completed',
        'cancelled'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE dispute_type AS ENUM (
        'partial_delivery',
        'damaged',
        'missing',
        'other'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE dispute_status AS ENUM (
        'open',
        'under_review',
        'resolved',
        'rejected'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE crop_plan_status AS ENUM (
        'planned',
        'cultivating',
        'harvested',
        'cancelled'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE cultivation_season AS ENUM (
        'maha',
        'yala',
        'off_season'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;


-- =============================================================================
-- 2. CORE USERS & ROLE PROFILES
-- =============================================================================

CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    phone VARCHAR(50),
    role user_role NOT NULL,
    organization_name VARCHAR(255),
    region VARCHAR(100),
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    nic VARCHAR(50),
    address TEXT,
    district VARCHAR(100),
    province VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_district ON users(district);

-- Farmer Profile: Detailed farm location, capacity, and baseline economics
CREATE TABLE IF NOT EXISTS farmer_profiles (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    farm_location VARCHAR(255),
    farm_size_acres DOUBLE PRECISION,
    crop_types_json TEXT,
    preferred_crops_json TEXT,
    estimated_capacity_kg DOUBLE PRECISION,
    traditional_farmgate_price_kg DOUBLE PRECISION,
    harvesting_cost_per_kg DOUBLE PRECISION,
    income_before_bit_app DOUBLE PRECISION,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Buyer Profile: Company vs. individual verification, buying preferences
CREATE TABLE IF NOT EXISTS buyer_profiles (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    nic_or_brn VARCHAR(100),
    business_name VARCHAR(255),
    business_type VARCHAR(100),
    buyer_type buyer_type NOT NULL DEFAULT 'company',
    location TEXT,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    verification_status verification_status NOT NULL DEFAULT 'pending',
    preferred_crops_json TEXT,
    preferred_price_min DOUBLE PRECISION,
    preferred_price_max DOUBLE PRECISION,
    required_quantity_kg DOUBLE PRECISION,
    reliability_score DOUBLE PRECISION NOT NULL DEFAULT 50.0,
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by_id VARCHAR(36),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Transporter Profile: Fleet details, service area, and rating
CREATE TABLE IF NOT EXISTS transporter_profiles (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    company VARCHAR(255),
    transporter_type transporter_type NOT NULL DEFAULT 'company',
    rating DOUBLE PRECISION NOT NULL DEFAULT 4.5,
    availability_status VARCHAR(50) NOT NULL DEFAULT 'available',
    service_areas_json TEXT,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Vehicles operated by transporters
CREATE TABLE IF NOT EXISTS vehicles (
    id VARCHAR(36) PRIMARY KEY,
    transporter_id VARCHAR(36) NOT NULL REFERENCES transporter_profiles(id) ON DELETE CASCADE,
    vehicle_number VARCHAR(50) NOT NULL,
    vehicle_type vehicle_type NOT NULL,
    capacity_kg DOUBLE PRECISION NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_vehicles_type ON vehicles(vehicle_type);
CREATE INDEX IF NOT EXISTS idx_vehicles_transporter ON vehicles(transporter_id);


-- =============================================================================
-- 3. PRODUCTIONS, SEQUENCES & LISTINGS
-- =============================================================================

CREATE TABLE IF NOT EXISTS listing_sequences (
    year INTEGER PRIMARY KEY,
    last_number INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS productions (
    id VARCHAR(36) PRIMARY KEY,
    listing_code VARCHAR(50) UNIQUE,
    farmer_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    crop_type VARCHAR(100) NOT NULL,
    variety VARCHAR(100),
    category VARCHAR(100),
    quantity DOUBLE PRECISION NOT NULL,
    unit VARCHAR(20) NOT NULL,
    harvest_date TIMESTAMP WITH TIME ZONE NOT NULL,
    region VARCHAR(100) NOT NULL,
    location TEXT NOT NULL,
    status production_status NOT NULL DEFAULT 'planned',
    notes TEXT,
    quality_grade quality_grade NOT NULL DEFAULT 'B',
    min_acceptable_price DOUBLE PRECISION,
    preferred_delivery_location TEXT,
    description TEXT,
    images_json TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_productions_query ON productions(crop_type, region, status, harvest_date);
CREATE INDEX IF NOT EXISTS idx_productions_farmer ON productions(farmer_id);


-- =============================================================================
-- 4. BUYER DEMAND & PURCHASE INTERESTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS demand_requests (
    id VARCHAR(36) PRIMARY KEY,
    requester_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    crop_type VARCHAR(100) NOT NULL,
    quantity_needed DOUBLE PRECISION NOT NULL,
    unit VARCHAR(20) NOT NULL,
    deadline TIMESTAMP WITH TIME ZONE NOT NULL,
    region VARCHAR(100) NOT NULL,
    status demand_status NOT NULL DEFAULT 'open',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_demands_query ON demand_requests(crop_type, region, status);
CREATE INDEX IF NOT EXISTS idx_demands_requester ON demand_requests(requester_id);

CREATE TABLE IF NOT EXISTS purchase_interests (
    id VARCHAR(36) PRIMARY KEY,
    business_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    production_id VARCHAR(36) NOT NULL REFERENCES productions(id) ON DELETE CASCADE,
    quantity DOUBLE PRECISION NOT NULL,
    message TEXT,
    status interest_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_interests_business_status ON purchase_interests(business_id, status);
CREATE INDEX IF NOT EXISTS idx_interests_production_status ON purchase_interests(production_id, status);


-- =============================================================================
-- 5. ASCENDING AUCTIONS & BIDDING ENGINE
-- =============================================================================

CREATE TABLE IF NOT EXISTS auctions (
    id VARCHAR(36) PRIMARY KEY,
    production_id VARCHAR(36) UNIQUE NOT NULL REFERENCES productions(id) ON DELETE CASCADE,
    opening_bid DOUBLE PRECISION NOT NULL,
    min_bid DOUBLE PRECISION NOT NULL,
    min_increment DOUBLE PRECISION NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    status auction_status NOT NULL DEFAULT 'open',
    winning_bid_id VARCHAR(36),
    closed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_auctions_status_endtime ON auctions(status, end_time);

CREATE TABLE IF NOT EXISTS bids (
    id VARCHAR(36) PRIMARY KEY,
    auction_id VARCHAR(36) NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
    buyer_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_bids_auction_created ON bids(auction_id, created_at);
CREATE INDEX IF NOT EXISTS idx_bids_buyer ON bids(buyer_id);


-- =============================================================================
-- 6. ORDERS, AUDIT EVENTS & SANDBOX PRODUCE PAYMENTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS orders (
    id VARCHAR(36) PRIMARY KEY,
    auction_id VARCHAR(36) UNIQUE NOT NULL,
    production_id VARCHAR(36) NOT NULL,
    farmer_id VARCHAR(36) NOT NULL REFERENCES users(id),
    buyer_id VARCHAR(36) NOT NULL REFERENCES users(id),
    winning_price_kg DOUBLE PRECISION NOT NULL,
    quantity_kg DOUBLE PRECISION NOT NULL,
    status order_status NOT NULL DEFAULT 'pending_farmer',
    farmer_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    buyer_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    remarks TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_orders_farmer ON orders(farmer_id);
CREATE INDEX IF NOT EXISTS idx_orders_buyer ON orders(buyer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

CREATE TABLE IF NOT EXISTS order_events (
    id VARCHAR(36) PRIMARY KEY,
    order_id VARCHAR(36) NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    status order_status NOT NULL,
    actor_id VARCHAR(36),
    action VARCHAR(100) NOT NULL,
    remarks TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_order_events_order ON order_events(order_id);

-- Produce Payment (Strictly separate from Transport Payment)
CREATE TABLE IF NOT EXISTS payments (
    id VARCHAR(36) PRIMARY KEY,
    order_id VARCHAR(36) UNIQUE NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    buyer_id VARCHAR(36) NOT NULL REFERENCES users(id),
    farmer_id VARCHAR(36) NOT NULL REFERENCES users(id),
    amount DOUBLE PRECISION NOT NULL,
    status payment_status NOT NULL DEFAULT 'pending',
    reference VARCHAR(100) UNIQUE NOT NULL,
    paid_at TIMESTAMP WITH TIME ZONE,
    receipt_note TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Legacy/Summary order transportation link
CREATE TABLE IF NOT EXISTS transportations (
    id VARCHAR(36) PRIMARY KEY,
    order_id VARCHAR(36) UNIQUE NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    farmer_location TEXT,
    buyer_location TEXT,
    distance_km DOUBLE PRECISION NOT NULL,
    quantity_kg DOUBLE PRECISION NOT NULL,
    estimated_cost DOUBLE PRECISION NOT NULL,
    vehicle_requirement VARCHAR(100),
    delivery_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- =============================================================================
-- 7. FARM-TO-BUSINESS LOGISTICS, DISPATCH & LIVE TRACKING
-- =============================================================================

CREATE TABLE IF NOT EXISTS delivery_addresses (
    id VARCHAR(36) PRIMARY KEY,
    buyer_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    business_name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    instructions TEXT,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_delivery_addresses_buyer ON delivery_addresses(buyer_id);

CREATE TABLE IF NOT EXISTS transport_sequences (
    year INTEGER PRIMARY KEY,
    last_number INTEGER NOT NULL DEFAULT 0
);

-- Configurable Admin Pricing Rules per Vehicle Class
CREATE TABLE IF NOT EXISTS transport_pricing_rules (
    id VARCHAR(36) PRIMARY KEY,
    vehicle_type vehicle_type UNIQUE NOT NULL,
    base_charge DOUBLE PRECISION NOT NULL,
    per_km DOUBLE PRECISION NOT NULL,
    per_kg DOUBLE PRECISION NOT NULL,
    loading_fee DOUBLE PRECISION NOT NULL DEFAULT 0,
    fuel_surcharge_percent DOUBLE PRECISION NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS transport_requests (
    id VARCHAR(36) PRIMARY KEY,
    request_code VARCHAR(50) UNIQUE NOT NULL,
    order_id VARCHAR(36) NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    buyer_id VARCHAR(36) NOT NULL REFERENCES users(id),
    farmer_id VARCHAR(36) NOT NULL REFERENCES users(id),
    delivery_address_id VARCHAR(36) REFERENCES delivery_addresses(id),
    transporter_id VARCHAR(36) REFERENCES users(id),
    vehicle_id VARCHAR(36) REFERENCES vehicles(id),
    pickup_label VARCHAR(255) NOT NULL,
    pickup_city VARCHAR(100) NOT NULL,
    pickup_lat DOUBLE PRECISION,
    pickup_lng DOUBLE PRECISION,
    delivery_label VARCHAR(255) NOT NULL,
    delivery_city VARCHAR(100) NOT NULL,
    delivery_lat DOUBLE PRECISION,
    delivery_lng DOUBLE PRECISION,
    product VARCHAR(100) NOT NULL,
    quantity_kg DOUBLE PRECISION NOT NULL,
    required_vehicle_type vehicle_type NOT NULL,
    required_capacity_kg DOUBLE PRECISION NOT NULL,
    preferred_pickup_date TIMESTAMP WITH TIME ZONE,
    preferred_pickup_time VARCHAR(50),
    delivery_deadline TIMESTAMP WITH TIME ZONE,
    distance_km DOUBLE PRECISION NOT NULL,
    estimated_cost DOUBLE PRECISION NOT NULL,
    delivery_method delivery_method NOT NULL DEFAULT 'bit_app_transport',
    status transport_status NOT NULL DEFAULT 'requested',
    driver_name VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_transport_requests_status_type ON transport_requests(status, required_vehicle_type);
CREATE INDEX IF NOT EXISTS idx_transport_requests_order ON transport_requests(order_id);
CREATE INDEX IF NOT EXISTS idx_transport_requests_transporter ON transport_requests(transporter_id);

-- Transport Payment Settlement (Recorded separately from produce)
CREATE TABLE IF NOT EXISTS transport_payments (
    id VARCHAR(36) PRIMARY KEY,
    transport_request_id VARCHAR(36) UNIQUE NOT NULL REFERENCES transport_requests(id) ON DELETE CASCADE,
    buyer_id VARCHAR(36) NOT NULL REFERENCES users(id),
    transporter_id VARCHAR(36) NOT NULL REFERENCES users(id),
    amount DOUBLE PRECISION NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    payment_status payment_status NOT NULL DEFAULT 'pending',
    reference VARCHAR(100) UNIQUE NOT NULL,
    paid_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS delivery_trackings (
    id VARCHAR(36) PRIMARY KEY,
    transport_request_id VARCHAR(36) NOT NULL REFERENCES transport_requests(id) ON DELETE CASCADE,
    status transport_status NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    note TEXT,
    actor_id VARCHAR(36),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_delivery_trackings_req_date ON delivery_trackings(transport_request_id, created_at);

CREATE TABLE IF NOT EXISTS delivery_proofs (
    id VARCHAR(36) PRIMARY KEY,
    transport_request_id VARCHAR(36) UNIQUE NOT NULL REFERENCES transport_requests(id) ON DELETE CASCADE,
    ordered_quantity_kg DOUBLE PRECISION NOT NULL,
    delivered_quantity_kg DOUBLE PRECISION NOT NULL,
    received_by VARCHAR(255),
    signature TEXT,
    photo_url TEXT,
    otp VARCHAR(20),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS delivery_disputes (
    id VARCHAR(36) PRIMARY KEY,
    order_id VARCHAR(36) NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    transport_request_id VARCHAR(36) REFERENCES transport_requests(id),
    dispute_type dispute_type NOT NULL,
    quantity_kg DOUBLE PRECISION NOT NULL,
    description TEXT NOT NULL,
    evidence_url TEXT,
    status dispute_status NOT NULL DEFAULT 'open',
    buyer_remarks TEXT,
    admin_remarks TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_delivery_disputes_order ON delivery_disputes(order_id);
CREATE INDEX IF NOT EXISTS idx_delivery_disputes_status ON delivery_disputes(status);


-- =============================================================================
-- 8. PRE-SEASON CROP PLANNING (DISTRICT -> DS DIVISION -> VILLAGE)
-- =============================================================================

CREATE TABLE IF NOT EXISTS crop_plans (
    id VARCHAR(36) PRIMARY KEY,
    farmer_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    crop_type VARCHAR(100) NOT NULL,
    cultivation_year INTEGER NOT NULL,
    cultivation_month INTEGER NOT NULL,
    season cultivation_season,
    area_acres DOUBLE PRECISION NOT NULL,
    province VARCHAR(100) NOT NULL,
    district VARCHAR(100) NOT NULL,
    ds_division VARCHAR(100) NOT NULL,
    village VARCHAR(100) NOT NULL,
    location_notes TEXT,
    expected_yield_kg DOUBLE PRECISION,
    status crop_plan_status NOT NULL DEFAULT 'planned',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_crop_plans_geo_period ON crop_plans(district, crop_type, cultivation_year, cultivation_month);
CREATE INDEX IF NOT EXISTS idx_crop_plans_farmer ON crop_plans(farmer_id);


-- =============================================================================
-- 9. MARKET INTELLIGENCE & PRIVACY-PRESERVING RESEARCH LAYER
-- =============================================================================

CREATE TABLE IF NOT EXISTS market_prices (
    id VARCHAR(36) PRIMARY KEY,
    crop_type VARCHAR(100) NOT NULL,
    variety VARCHAR(100),
    district VARCHAR(100) NOT NULL,
    grade quality_grade NOT NULL DEFAULT 'B',
    price_per_kg DOUBLE PRECISION NOT NULL,
    recorded_on TIMESTAMP WITH TIME ZONE NOT NULL,
    source data_source_kind NOT NULL,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_market_prices_crop_district_date ON market_prices(crop_type, district, recorded_on);

-- Anonymized Research Observations (No PII: No name, email, NIC, or phone)
CREATE TABLE IF NOT EXISTS research_observations (
    id VARCHAR(36) PRIMARY KEY,
    participant_code VARCHAR(50) NOT NULL,
    role VARCHAR(50) NOT NULL,
    district VARCHAR(100),
    province VARCHAR(100),
    farm_size_acres DOUBLE PRECISION,
    crop_type VARCHAR(100),
    quantity_kg DOUBLE PRECISION,
    traditional_price_kg DOUBLE PRECISION,
    bit_app_price_kg DOUBLE PRECISION,
    transportation_cost DOUBLE PRECISION,
    harvesting_cost DOUBLE PRECISION,
    used_intermediary BOOLEAN,
    used_bit_app_direct BOOLEAN,
    market_info_access BOOLEAN,
    income_before DOUBLE PRECISION,
    income_after DOUBLE PRECISION,
    satisfaction_score INTEGER CHECK (satisfaction_score >= 1 AND satisfaction_score <= 5),
    source data_source_kind NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_research_observations_district ON research_observations(district, crop_type);


-- =============================================================================
-- 10. NOTIFICATIONS, RATINGS, COMPLAINTS & AUDIT TRAIL
-- =============================================================================

CREATE TABLE IF NOT EXISTS app_notifications (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    audience notification_audience NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON app_notifications(user_id, read_at);

CREATE TABLE IF NOT EXISTS reviews (
    id VARCHAR(36) PRIMARY KEY,
    reviewer_id VARCHAR(36) NOT NULL REFERENCES users(id),
    reviewee_id VARCHAR(36) NOT NULL REFERENCES users(id),
    order_id VARCHAR(36),
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_reviews_reviewee ON reviews(reviewee_id);

CREATE TABLE IF NOT EXISTS complaints (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_complaints_user ON complaints(user_id);

CREATE TABLE IF NOT EXISTS audit_logs (
    id VARCHAR(36) PRIMARY KEY,
    actor_id VARCHAR(36) REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id VARCHAR(36),
    metadata TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type, entity_id);


-- =============================================================================
-- 11. POSTGRESQL TRIGGERS FOR AUTOMATIC updated_at MAINTENANCE
-- =============================================================================

CREATE OR REPLACE FUNCTION update_timestamp_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
    CREATE TRIGGER trg_update_users_timestamp
        BEFORE UPDATE ON users
        FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TRIGGER trg_update_farmer_profiles_timestamp
        BEFORE UPDATE ON farmer_profiles
        FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TRIGGER trg_update_buyer_profiles_timestamp
        BEFORE UPDATE ON buyer_profiles
        FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TRIGGER trg_update_transporter_profiles_timestamp
        BEFORE UPDATE ON transporter_profiles
        FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TRIGGER trg_update_productions_timestamp
        BEFORE UPDATE ON productions
        FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TRIGGER trg_update_demand_requests_timestamp
        BEFORE UPDATE ON demand_requests
        FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TRIGGER trg_update_purchase_interests_timestamp
        BEFORE UPDATE ON purchase_interests
        FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TRIGGER trg_update_auctions_timestamp
        BEFORE UPDATE ON auctions
        FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TRIGGER trg_update_orders_timestamp
        BEFORE UPDATE ON orders
        FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TRIGGER trg_update_transport_pricing_rules_timestamp
        BEFORE UPDATE ON transport_pricing_rules
        FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TRIGGER trg_update_transport_requests_timestamp
        BEFORE UPDATE ON transport_requests
        FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TRIGGER trg_update_delivery_disputes_timestamp
        BEFORE UPDATE ON delivery_disputes
        FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TRIGGER trg_update_crop_plans_timestamp
        BEFORE UPDATE ON crop_plans
        FOR EACH ROW EXECUTE FUNCTION update_timestamp_column();
EXCEPTION WHEN duplicate_object THEN null;
END $$;

