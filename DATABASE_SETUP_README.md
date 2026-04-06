# Database Setup for Profile Saving

## Issue
The "Save Profile" functionality is failing because the required database tables don't exist in your Supabase project.

## Solution
Run the SQL script in your Supabase dashboard to create the necessary tables:

1. Go to your Supabase project dashboard
2. Navigate to the SQL Editor
3. Copy and paste the contents of `database_setup.sql`
4. Run the script

## What the script creates:
- `buyer_profiles` table for buyer-specific data
- `seller_profiles` table for seller-specific data
- Row Level Security policies for data protection

## After running the script:
- The profile save functionality should work properly
- Users can save their profile information without errors
- Data will be properly stored in the database

## Additional Notes:
- Make sure your Supabase project has the `avatars` storage bucket created
- The bucket should allow public access for avatar images
- RLS policies ensure users can only access their own data