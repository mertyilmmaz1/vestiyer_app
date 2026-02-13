-- Create user_profiles table to track premium status and usage
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    is_premium BOOLEAN DEFAULT false,
    subscription_end_date TIMESTAMPTZ,
    free_items_used INTEGER DEFAULT 0,
    role TEXT DEFAULT 'user',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add constraint to ensure role is either 'user' or 'admin'
ALTER TABLE public.user_profiles
ADD CONSTRAINT valid_role CHECK (role IN ('user', 'admin'));

-- Create a trigger to automatically create a user profile when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id)
    VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger the function every time a user is created
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Enable Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own profile" 
    ON public.user_profiles FOR SELECT 
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
    ON public.user_profiles FOR UPDATE 
    USING (auth.uid() = id);

-- Create function to increment free items count
CREATE OR REPLACE FUNCTION public.increment_free_items_used(user_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.user_profiles 
    SET free_items_used = free_items_used + 1,
        updated_at = NOW()
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to set user as admin
CREATE OR REPLACE FUNCTION public.set_user_as_admin(user_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.user_profiles 
    SET role = 'admin'
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 