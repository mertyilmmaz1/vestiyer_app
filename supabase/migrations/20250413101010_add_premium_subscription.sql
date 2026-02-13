-- Add premium subscription related columns to auth.users table
ALTER TABLE auth.users 
ADD COLUMN IF NOT EXISTS is_premium BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS subscription_start_date TIMESTAMP,
ADD COLUMN IF NOT EXISTS subscription_end_date TIMESTAMP,
ADD COLUMN IF NOT EXISTS subscription_type TEXT,
ADD COLUMN IF NOT EXISTS subscription_status TEXT DEFAULT 'inactive',
ADD COLUMN IF NOT EXISTS apple_transaction_id TEXT,
ADD COLUMN IF NOT EXISTS last_paywall_shown TIMESTAMP;

-- Create a table to track subscription transactions
CREATE TABLE IF NOT EXISTS subscription_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    transaction_id TEXT,
    transaction_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    provider TEXT NOT NULL,
    subscription_type TEXT NOT NULL,
    amount DECIMAL(10, 2),
    status TEXT NOT NULL,
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add free_items_used column to track how many free items a user has uploaded
ALTER TABLE auth.users 
ADD COLUMN IF NOT EXISTS free_items_used INTEGER DEFAULT 0;

-- Create a function to check if a user can add more free items
CREATE OR REPLACE FUNCTION check_free_item_limit()
RETURNS TRIGGER AS $$
BEGIN
    -- If the user is premium, allow the insert
    IF EXISTS (
        SELECT 1 FROM auth.users 
        WHERE id = NEW.user_id 
        AND is_premium = TRUE
        AND (subscription_end_date IS NULL OR subscription_end_date > CURRENT_TIMESTAMP)
    ) THEN
        RETURN NEW;
    END IF;
    
    -- Check if the user has reached their free limit
    IF (
        SELECT COUNT(*) FROM clothing_items 
        WHERE user_id = NEW.user_id
    ) >= 10 THEN
        RAISE EXCEPTION 'Free users can only add up to 10 clothing items. Please upgrade to premium.';
    END IF;
    
    -- Increment the free_items_used counter
    UPDATE auth.users 
    SET free_items_used = free_items_used + 1
    WHERE id = NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on clothing_items table
DROP TRIGGER IF EXISTS check_item_limit ON clothing_items;
CREATE TRIGGER check_item_limit
BEFORE INSERT ON clothing_items
FOR EACH ROW
EXECUTE FUNCTION check_free_item_limit(); 