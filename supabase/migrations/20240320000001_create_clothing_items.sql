-- Create clothing_items table
CREATE TABLE IF NOT EXISTS public.clothing_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    main_group TEXT NOT NULL,
    category TEXT,
    color TEXT,
    material TEXT,
    style TEXT,
    season TEXT,
    description TEXT,
    image_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.clothing_items ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own items" 
    ON public.clothing_items FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own items" 
    ON public.clothing_items FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own items" 
    ON public.clothing_items FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own items" 
    ON public.clothing_items FOR DELETE 
    USING (auth.uid() = user_id);

-- Create api_usage table for tracking costs
CREATE TABLE IF NOT EXISTS public.api_usage (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    model TEXT NOT NULL,
    prompt_tokens INTEGER NOT NULL,
    completion_tokens INTEGER NOT NULL,
    cost DECIMAL(10, 6) NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security for api_usage
ALTER TABLE public.api_usage ENABLE ROW LEVEL SECURITY;

-- Create policies for api_usage
CREATE POLICY "Users can view own api usage" 
    ON public.api_usage FOR SELECT 
    USING (auth.uid() = user_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at trigger to clothing_items
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON public.clothing_items
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at(); 