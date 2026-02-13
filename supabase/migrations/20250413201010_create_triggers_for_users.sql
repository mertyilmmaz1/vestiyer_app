-- Create a function to check and update subscription status
CREATE OR REPLACE FUNCTION update_subscription_status()
RETURNS TRIGGER AS $$
BEGIN
    -- If subscription has expired, set status to expired and premium to false
    IF (NEW.subscription_end_date IS NOT NULL AND NEW.subscription_end_date < CURRENT_TIMESTAMP) THEN
        NEW.is_premium = FALSE;
        NEW.subscription_status = 'expired';
    -- If subscription is active and end date is in the future
    ELSIF (NEW.is_premium = TRUE AND 
          (NEW.subscription_end_date IS NULL OR NEW.subscription_end_date > CURRENT_TIMESTAMP)) THEN
        NEW.subscription_status = 'active';
    -- If no subscription
    ELSIF (NEW.is_premium = FALSE) THEN
        NEW.subscription_status = 'inactive';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to automatically update subscription status
DROP TRIGGER IF EXISTS update_user_subscription_status ON auth.users;
CREATE TRIGGER update_user_subscription_status
BEFORE UPDATE OR INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION update_subscription_status();

-- Create a function to automatically count clothing items and update free_items_used
CREATE OR REPLACE FUNCTION update_free_items_count()
RETURNS TRIGGER AS $$
DECLARE
    items_count INTEGER;
BEGIN
    -- Count user's clothing items
    SELECT COUNT(*) INTO items_count 
    FROM public.clothing_items 
    WHERE user_id = NEW.user_id;
    
    -- Update the free_items_used count in users table if not premium
    UPDATE auth.users 
    SET free_items_used = items_count
    WHERE id = NEW.user_id AND is_premium = FALSE;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to automatically update free_items_used count
DROP TRIGGER IF EXISTS update_free_items_used ON public.clothing_items;
CREATE TRIGGER update_free_items_used
AFTER INSERT OR DELETE ON public.clothing_items
FOR EACH ROW
EXECUTE FUNCTION update_free_items_count(); 