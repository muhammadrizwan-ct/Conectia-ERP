-- Add tickets_last_seen_at column to public.users so the toolbar badge
-- state persists across devices and browser sessions per user.

BEGIN;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'users'
    ) THEN
        ALTER TABLE public.users
            ADD COLUMN IF NOT EXISTS tickets_last_seen_at timestamptz;
    END IF;
END
$$;

COMMIT;
