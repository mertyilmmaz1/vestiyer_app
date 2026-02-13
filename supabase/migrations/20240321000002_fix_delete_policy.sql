-- Drop existing policies
DROP POLICY IF EXISTS "Users can delete own items" ON public.clothing_items;
DROP POLICY IF EXISTS "Users can view own items" ON public.clothing_items;
DROP POLICY IF EXISTS "Users can insert own items" ON public.clothing_items;
DROP POLICY IF EXISTS "Users can update own items" ON public.clothing_items;

-- Enable RLS
ALTER TABLE public.clothing_items ENABLE ROW LEVEL SECURITY;

-- Create policies with proper authentication checks
CREATE POLICY "Users can delete own items"
ON public.clothing_items
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can view own items"
ON public.clothing_items
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own items"
ON public.clothing_items
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own items"
ON public.clothing_items
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Grant necessary permissions to authenticated users
GRANT ALL ON public.clothing_items TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated; 