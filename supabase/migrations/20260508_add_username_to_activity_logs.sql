-- Add username column to activity_logs for direct display without joins.
-- Uses ALTER ... ADD COLUMN IF NOT EXISTS so it is safe to re-run.

ALTER TABLE public.activity_logs
    ADD COLUMN IF NOT EXISTS username text;
