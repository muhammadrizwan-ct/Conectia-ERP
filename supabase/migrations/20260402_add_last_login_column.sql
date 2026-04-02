-- Add last_login and created_at columns to track user activity.

BEGIN;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'users'
    ) THEN
        ALTER TABLE public.users ADD COLUMN IF NOT EXISTS last_login timestamptz;
        ALTER TABLE public.users ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();
    END IF;
END
$$;

COMMIT;
