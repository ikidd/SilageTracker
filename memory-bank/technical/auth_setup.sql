-- Enable Row Level Security
ALTER TABLE herds ENABLE ROW LEVEL SECURITY;
ALTER TABLE silage_fed ENABLE ROW LEVEL SECURITY;

-- Create policies for herds table
CREATE POLICY "Users can view their own herds" ON herds
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own herds" ON herds
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own herds" ON herds
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own herds" ON herds
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- Create policies for silage_fed table
CREATE POLICY "Users can view their own silage entries" ON silage_fed
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own silage entries" ON silage_fed
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own silage entries" ON silage_fed
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own silage entries" ON silage_fed
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- Add user_id column to existing tables if not present
ALTER TABLE herds 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);

ALTER TABLE silage_fed 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);

-- Create trigger to automatically set user_id on insert
CREATE OR REPLACE FUNCTION public.set_user_id()
RETURNS TRIGGER AS $$
BEGIN
  NEW.user_id = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add triggers to tables
DROP TRIGGER IF EXISTS set_herd_user_id ON herds;
CREATE TRIGGER set_herd_user_id
  BEFORE INSERT ON herds
  FOR EACH ROW
  EXECUTE FUNCTION public.set_user_id();

DROP TRIGGER IF EXISTS set_silage_entry_user_id ON silage_fed;
CREATE TRIGGER set_silage_entry_user_id
  BEFORE INSERT ON silage_fed
  FOR EACH ROW
  EXECUTE FUNCTION public.set_user_id();