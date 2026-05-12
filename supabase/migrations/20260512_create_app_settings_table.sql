-- Create app_settings table for global key-value configuration
-- Only the master admin (via RLS) can insert/update; all authenticated users can read.

CREATE TABLE IF NOT EXISTS public.app_settings (
    key   text PRIMARY KEY,
    value text NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Seed the opening balance row so it always exists
INSERT INTO public.app_settings (key, value)
VALUES ('bank_opening_balance', '0')
ON CONFLICT (key) DO NOTHING;

-- Enable RLS
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read
CREATE POLICY "app_settings_read" ON public.app_settings
    FOR SELECT
    TO authenticated
    USING (true);

-- Only master admin can write (matched by email stored in users table)
CREATE POLICY "app_settings_write_master" ON public.app_settings
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE auth_user_id = auth.uid()
              AND (
                  lower(username) = 'master'
                  OR lower(email) = lower('muhammadrizwan@connectia.io')
              )
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE auth_user_id = auth.uid()
              AND (
                  lower(username) = 'master'
                  OR lower(email) = lower('muhammadrizwan@connectia.io')
              )
        )
    );
