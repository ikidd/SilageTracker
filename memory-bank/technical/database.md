# Database Technical Documentation

## Connection Configuration

### Supabase Settings
```
URL: https://supabase.pebcake.com
API Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.ewogICJyb2xlIjogImFub24iLAogICJpc3MiOiAic3VwYWJhc2UiLAogICJpYXQiOiAxNzM5MTcwODAwLAogICJleHAiOiAxODk2OTM3MjAwCn0.3XJyhrOwSR9>
```

These settings should be configured in your application's environment or settings file.

## Authentication Setup

### 1. Enable Email OTP Authentication in Supabase
1. Go to Authentication > Providers in the Supabase dashboard
2. Enable Email provider
3. Configure email templates for OTP/Magic Link emails
4. Ensure "Enable Email Confirmations" is turned off (as we're using OTP)

### 2. Database Schema and Security

#### Row Level Security (RLS) Setup
Execute the following SQL in the Supabase SQL editor to set up Row Level Security:

```sql
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
```

#### User Association
Add user_id columns and automatic user association:

```sql
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
```

## Tables

### Initial Setup

```sql
-- Create theme_mode enum type
CREATE TYPE theme_mode AS ENUM ('system', 'light', 'dark');

-- Create tables
CREATE TABLE herds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    user_id UUID REFERENCES auth.users(id)
);

CREATE TABLE silage_fed (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    herd_id UUID REFERENCES herds(id) ON DELETE CASCADE,
    entry_date DATE NOT NULL,
    amount NUMERIC NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    user_id UUID REFERENCES auth.users(id)
);

CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    theme_mode theme_mode NOT NULL DEFAULT 'system',
    show_delete_confirmation BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers to all tables
CREATE TRIGGER update_herds_updated_at
    BEFORE UPDATE ON herds
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_silage_fed_updated_at
    BEFORE UPDATE ON silage_fed
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create trigger for automatic profile creation
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id)
    VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- Add indexes for performance
CREATE INDEX idx_herds_user_id ON herds(user_id);
CREATE INDEX idx_silage_fed_user_id ON silage_fed(user_id);
CREATE INDEX idx_silage_fed_herd_id ON silage_fed(herd_id);
CREATE INDEX idx_silage_fed_entry_date ON silage_fed(entry_date);
```

### herds
- id (UUID, primary key)
- name (text)
- description (text)
- created_at (timestamp with time zone)
- updated_at (timestamp with time zone)
- user_id (UUID, references auth.users)

### silage_fed
- id (UUID, primary key)
- herd_id (UUID, references herds)
- entry_date (date)
- amount (numeric)
- notes (text)
- created_at (timestamp with time zone)
- updated_at (timestamp with time zone)
- user_id (UUID, references auth.users)

### profiles
- id (UUID, primary key, references auth.users)
- theme_mode (theme_mode enum: 'system', 'light', 'dark')
- show_delete_confirmation (boolean)
- created_at (timestamp with time zone)
- updated_at (timestamp with time zone)

The profiles table is automatically created for each new user upon signup through a trigger. It stores user-specific settings and preferences with the following features:
- Automatic default values (system theme, delete confirmation enabled)
- Automatic timestamp management
- Row Level Security ensuring users can only access their own profile
- Automatic profile creation on user signup

## Security Considerations

1. **Row Level Security (RLS)**
   - All tables have RLS enabled
   - Users can only access their own data
   - Authenticated access only

2. **User Association**
   - All records are automatically associated with the creating user
   - User association is enforced through triggers
   - Foreign key constraints ensure data integrity

3. **Authentication**
   - Email-based OTP (One-Time Password) authentication
   - Magic link functionality
   - No password storage required
   - Session management
   - Protected API endpoints

## Best Practices

1. **Data Access**
   - Always use RLS policies for data access
   - Never disable RLS
   - Use parameterized queries to prevent SQL injection

2. **User Management**
   - Store user preferences in a separate table
   - Use UUID for user IDs
   - Implement proper session handling

3. **Performance**
   - Index frequently queried columns
   - Use appropriate data types
   - Implement pagination for large datasets