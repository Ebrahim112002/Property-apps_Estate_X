-- Create buyer_profiles table
CREATE TABLE IF NOT EXISTS buyer_profiles (
    id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    preferred_property_type TEXT,
    budget_min DECIMAL,
    budget_max DECIMAL,
    preferred_bedrooms INTEGER,
    preferred_size_sqft INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create seller_profiles table
CREATE TABLE IF NOT EXISTS seller_profiles (
    id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    seller_type TEXT,
    company_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE buyer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE seller_profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for buyer_profiles
CREATE POLICY "Users can view their own buyer profile" ON buyer_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert their own buyer profile" ON buyer_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own buyer profile" ON buyer_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Create policies for seller_profiles
CREATE POLICY "Users can view their own seller profile" ON seller_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert their own seller profile" ON seller_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own seller profile" ON seller_profiles
    FOR UPDATE USING (auth.uid() = id);