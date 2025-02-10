# Database Technical Documentation

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