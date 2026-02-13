-- Create wardrobe_analysis table to store AI analysis results
CREATE TABLE IF NOT EXISTS public.wardrobe_analysis (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  analysis_content text NOT NULL,
  parsed_analysis jsonb NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  
  -- Add indexes for faster lookups
  CONSTRAINT wardrobe_analysis_user_id_key UNIQUE (user_id)
);

-- Set up RLS policies
ALTER TABLE public.wardrobe_analysis ENABLE ROW LEVEL SECURITY;

-- Allow users to read only their own analysis
CREATE POLICY wardrobe_analysis_select_policy ON public.wardrobe_analysis
  FOR SELECT USING (auth.uid() = user_id);

-- Allow users to insert their own analysis
CREATE POLICY wardrobe_analysis_insert_policy ON public.wardrobe_analysis
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own analysis
CREATE POLICY wardrobe_analysis_update_policy ON public.wardrobe_analysis
  FOR UPDATE USING (auth.uid() = user_id);

-- Allow users to delete their own analysis
CREATE POLICY wardrobe_analysis_delete_policy ON public.wardrobe_analysis
  FOR DELETE USING (auth.uid() = user_id);

-- Add a trigger to ensure only one analysis per user (replace older ones)
CREATE OR REPLACE FUNCTION public.ensure_single_analysis_per_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete any existing analysis for this user
  DELETE FROM public.wardrobe_analysis
  WHERE user_id = NEW.user_id AND id != NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ensure_single_analysis_per_user
AFTER INSERT ON public.wardrobe_analysis
FOR EACH ROW
EXECUTE FUNCTION public.ensure_single_analysis_per_user(); 