-- Update user_profiles table to ensure proper premium status tracking
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (
        id,
        is_premium,
        subscription_end_date,
        free_items_used,
        role,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id,
        false,  -- default not premium
        null,   -- no subscription end date
        0,      -- no free items used
        'user', -- default role
        NOW(),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create or replace the function to update subscription status
CREATE OR REPLACE FUNCTION public.update_subscription_status()
RETURNS TRIGGER AS $$
BEGIN
    -- If subscription has expired, set premium to false
    IF (NEW.subscription_end_date IS NOT NULL AND NEW.subscription_end_date < NOW()) THEN
        NEW.is_premium = false;
    END IF;
    
    -- Update the updated_at timestamp
    NEW.updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create or replace trigger for subscription status updates
DROP TRIGGER IF EXISTS on_subscription_update ON public.user_profiles;
CREATE TRIGGER on_subscription_update
    BEFORE UPDATE OF subscription_end_date, is_premium
    ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_subscription_status();

-- Ensure RLS policies are in place
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;

CREATE POLICY "Users can view own profile" 
    ON public.user_profiles FOR SELECT 
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
    ON public.user_profiles FOR UPDATE 
    USING (auth.uid() = id);

-- Add index for faster premium status queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_premium 
    ON public.user_profiles (is_premium, subscription_end_date); 