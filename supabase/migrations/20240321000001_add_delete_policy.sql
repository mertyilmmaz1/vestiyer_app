-- Enable Row Level Security if not already enabled
ALTER TABLE public.clothing_items ENABLE ROW LEVEL SECURITY;

-- Drop existing delete policy if exists
DROP POLICY IF EXISTS "Users can delete own items" ON public.clothing_items;

-- Create delete policy
CREATE POLICY "Users can delete own items"
ON public.clothing_items
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- Verify RLS is not too restrictive by adding select policy if not exists
DROP POLICY IF EXISTS "Users can view own items" ON public.clothing_items;
CREATE POLICY "Users can view own items"
ON public.clothing_items
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Add insert policy if not exists
DROP POLICY IF EXISTS "Users can insert own items" ON public.clothing_items;
CREATE POLICY "Users can insert own items"
ON public.clothing_items
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Add update policy if not exists
DROP POLICY IF EXISTS "Users can update own items" ON public.clothing_items;
CREATE POLICY "Users can update own items"
ON public.clothing_items
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id); 